import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import '../views/auth/facebook_login_webview.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../config/config.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final _box = GetStorage();
  
  var isLoading = false.obs;
  var user = {}.obs;
  var token = ''.obs;
  var walletInfo = {}.obs;
  var guestAvatar = ''.obs;

  @override
  void onInit() {
    super.onInit();
    token.value = _box.read('token') ?? '';
    user.value = _box.read('user') ?? {};
    guestAvatar.value = _box.read('guestAvatar') ?? '';
    if (token.value.isNotEmpty) {
      getMe();
      fetchWalletInfo();
    } else {
      // Guest: fetch random avatar nếu chưa có cache
      if (guestAvatar.value.isEmpty) {
        _fetchGuestAvatar();
      }
    }
  }

  bool get isLoggedIn => token.value.isNotEmpty;

  /// Trả về URL avatar đầy đủ
  String get avatarUrl {
    final avatar = user['avatar'] ?? '';
    if (avatar.isEmpty) {
      // Guest hoặc user chưa có avatar → dùng guest avatar
      if (guestAvatar.value.isNotEmpty) {
        final ga = guestAvatar.value;
        if (ga.startsWith('http')) return ga;
        final base = AppConfig.apiBaseUrl.replaceAll('/api', '');
        return '$base$ga';
      }
      return "https://ui-avatars.com/api/?name=${user['fullName'] ?? 'User'}&background=random";
    }
    if (avatar.startsWith('http')) return avatar;
    // Avatar từ backend: /uploads/xxx.jpg → cần ghép với base URL
    final base = AppConfig.apiBaseUrl.replaceAll('/api', '');
    return '$base$avatar';
  }

  /// Fetch avatar ngẫu nhiên từ server cho guest
  Future<void> _fetchGuestAvatar() async {
    try {
      final response = await _authService.getRandomAvatar();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final avatar = data['avatar'] ?? '';
        if (avatar.isNotEmpty) {
          guestAvatar.value = avatar;
          await _box.write('guestAvatar', avatar);
        }
      }
    } catch (e) {
      debugPrint('fetchGuestAvatar error: $e');
    }
  }

  // ============ LOGIN GATE (cho guest) ============

  /// Hiện bottom sheet mời đăng nhập
  static void showLoginBottomSheet(BuildContext context, {String? message}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LoginBottomSheetContent(message: message),
    );
  }

  /// Kiểm tra đăng nhập. Nếu chưa → hiện bottom sheet, trả về false.
  static bool requireLogin(BuildContext context, {String? message}) {
    final auth = Get.find<AuthController>();
    if (auth.isLoggedIn) return true;
    showLoginBottomSheet(context, message: message);
    return false;
  }

  Future<void> register(String fullName, String email, String phone, String password, String confirmPassword) async {
    try {
      isLoading.value = true;
      final response = await _authService.register(fullName, email, phone, password, confirmPassword);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        Get.snackbar('Thành công', data['message'] ?? 'Đăng ký thành công! Vui lòng xác thực email.');
        Get.toNamed('/verify-code', arguments: email);
      } else {
        Get.snackbar('Lỗi', data['message'] ?? 'Đăng ký thất bại');
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể kết nối đến server. Vui lòng kiểm tra IP trong file .env');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      final response = await _authService.login(email, password);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        token.value = data['token'];
        user.value = data['user'];
        await _box.write('token', token.value);
        await _box.write('user', user.value);
        fetchWalletInfo();
        Get.offAllNamed('/home');
      } else if (response.statusCode == 400 && data['requiresVerification'] == true) {
        Get.snackbar('Thông báo', data['message']);
        Get.toNamed('/verify-code', arguments: email);
      } else {
        Get.snackbar('Lỗi', data['message'] ?? 'Đăng nhập thất bại');
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Đã xảy ra lỗi kết nối');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      isLoading.value = true;

      // Bước 1: Hiển thị Google Sign-In
      // Web dùng clientId, Android dùng serverClientId (cùng Web Client ID)
      const webClientId = '1081475560123-qstt36kouep4ni6brbt8nn42g0d5oom2.apps.googleusercontent.com';
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? webClientId : null,          // Chỉ cho Web
        serverClientId: kIsWeb ? null : webClientId,    // Chỉ cho Android
        scopes: ['email'],
      );
      // Xoá cache để luôn hiển thị chọn tài khoản
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User đã huỷ đăng nhập
        return;
      }

      // Bước 2: Lấy ID Token
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        Get.snackbar('Lỗi', 'Không lấy được token từ Google');
        return;
      }

      // Bước 3: Gửi ID Token lên backend
      final response = await _authService.googleLogin(idToken);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        token.value = data['token'];
        user.value = data['user'];
        await _box.write('token', token.value);
        await _box.write('user', user.value);
        fetchWalletInfo();
        Get.offAllNamed('/home');
      } else {
        Get.snackbar('Lỗi', data['message'] ?? 'Đăng nhập Google thất bại');
      }
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      Get.snackbar('Lỗi', 'Đăng nhập Google thất bại: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithFacebook() async {
    try {
      isLoading.value = true;

      const facebookAppId = '1299755395380623';
      const redirectUri = 'https://xavier-unextracted-truman.ngrok-free.dev/api/auth/facebook/callback';

      debugPrint('🔵 Opening Facebook Login WebView...');

      // Mở WebView → user login → nhận authorization code
      final code = await Get.to<String>(
        () => FacebookLoginWebView(
          appId: facebookAppId,
          redirectUri: redirectUri,
        ),
        fullscreenDialog: true,
      );

      if (code == null) {
        debugPrint('Facebook login: user cancelled or error');
        return;
      }

      debugPrint('✅ Got Facebook auth code, sending to backend...');

      // Gửi authorization code + redirectUri lên backend để exchange lấy access token
      final response = await _authService.facebookLoginWithCode(code, redirectUri);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        token.value = data['token'];
        user.value = data['user'];
        await _box.write('token', token.value);
        await _box.write('user', user.value);
        fetchWalletInfo();
        Get.offAllNamed('/home');
      } else {
        Get.snackbar('Lỗi', data['message'] ?? 'Đăng nhập Facebook thất bại');
      }
    } catch (e) {
      debugPrint('Facebook Sign-In error: $e');
      Get.snackbar('Lỗi', 'Đăng nhập Facebook thất bại: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyEmail(String email, String code) async {
    try {
      isLoading.value = true;
      final response = await _authService.verifyEmail(email, code);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        Get.snackbar('Thành công', data['message']);
        Get.offAllNamed('/login');
      } else {
        Get.snackbar('Lỗi', data['message'] ?? 'Mã xác thực không đúng');
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Đã xảy ra lỗi kết nối');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendCode(String email) async {
    try {
      isLoading.value = true;
      final response = await _authService.resendCode(email);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        Get.snackbar('Thành công', data['message']);
      } else {
        Get.snackbar('Lỗi', data['message'] ?? 'Gửi lại mã thất bại');
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Lỗi kết nối');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    token.value = '';
    user.value = {};
    walletInfo.value = {};
    await _box.remove('token');
    await _box.remove('user');
    Get.offAllNamed('/login');
  }

  Future<void> getMe() async {
    try {
      final response = await _authService.getMe(token.value);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        user.value = data['user'];
        await _box.write('user', user.value);
      }
    } catch (e) {
      debugPrint('getMe error: $e');
    }
  }

  // ============ WALLET INFO ============
  Future<void> fetchWalletInfo() async {
    try {
      final response = await _apiService.getWalletInfo();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        walletInfo.value = data['wallet'] ?? {};
      }
    } catch (e) {
      debugPrint('fetchWalletInfo error: $e');
    }
  }

  // ============ FORGOT PASSWORD ============
  Future<void> forgotPassword(String email) async {
    try {
      isLoading.value = true;
      final response = await _apiService.forgotPassword(email);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        Get.snackbar('Thành công', data['message']);
      } else {
        Get.snackbar('Lỗi', data['message'] ?? 'Gửi yêu cầu thất bại');
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Lỗi kết nối');
    } finally {
      isLoading.value = false;
    }
  }

  // ============ RESET PASSWORD ============
  Future<void> resetPassword(String email, String code, String newPassword) async {
    try {
      isLoading.value = true;
      final response = await _apiService.resetPassword(email, code, newPassword);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        Get.snackbar('Thành công', data['message']);
        Get.offAllNamed('/login');
      } else {
        Get.snackbar('Lỗi', data['message'] ?? 'Đặt lại mật khẩu thất bại');
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Lỗi kết nối');
    } finally {
      isLoading.value = false;
    }
  }

  // ============ UPDATE PROFILE ============
  Future<void> updateProfile({String? fullName, String? phone, String? email, String? address}) async {
    try {
      isLoading.value = true;
      final response = await _apiService.updateProfile(
        fullName: fullName, phone: phone, email: email, address: address,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        user.value = data['user'];
        await _box.write('user', user.value);
        Get.snackbar('Thành công', 'Cập nhật thông tin thành công');
      } else {
        Get.snackbar('Lỗi', data['message'] ?? 'Cập nhật thất bại');
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Lỗi kết nối');
    } finally {
      isLoading.value = false;
    }
  }
}

// ============ LOGIN BOTTOM SHEET WIDGET ============

class _LoginBottomSheetContent extends StatelessWidget {
  final String? message;
  const _LoginBottomSheetContent({this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 24),

          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E56D9), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E56D9).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.lock_open_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            "Đăng nhập để tiếp tục",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1F36),
            ),
          ),

          const SizedBox(height: 8),

          // Message
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message ?? "Bạn cần đăng nhập để sử dụng tính năng này",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Login button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E56D9), Color(0xFF42A5F5)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E56D9).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Get.toNamed('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    "ĐĂNG NHẬP",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Register button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Get.toNamed('/register');
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: const Color(0xFF1E56D9).withOpacity(0.3), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  "ĐĂNG KÝ TÀI KHOẢN",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E56D9),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Skip text
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "Để sau",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
