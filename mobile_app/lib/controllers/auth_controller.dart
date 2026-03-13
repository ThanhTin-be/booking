import 'dart:convert';
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

  @override
  void onInit() {
    super.onInit();
    token.value = _box.read('token') ?? '';
    user.value = _box.read('user') ?? {};
    if (token.value.isNotEmpty) {
      getMe();
      fetchWalletInfo();
    }
  }

  bool get isLoggedIn => token.value.isNotEmpty;

  /// Trả về URL avatar đầy đủ
  String get avatarUrl {
    final avatar = user['avatar'] ?? '';
    if (avatar.isEmpty) {
      return "https://ui-avatars.com/api/?name=${user['fullName'] ?? 'User'}&background=random";
    }
    if (avatar.startsWith('http')) return avatar;
    // Avatar từ backend: /uploads/xxx.jpg → cần ghép với base URL
    final base = AppConfig.apiBaseUrl.replaceAll('/api', '');
    return '$base$avatar';
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
