import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final _box = GetStorage();
  
  var isLoading = false.obs;
  var user = {}.obs;
  var token = ''.obs;

  @override
  void onInit() {
    super.onInit();
    token.value = _box.read('token') ?? '';
    user.value = _box.read('user') ?? {};
    if (token.value.isNotEmpty) {
      getMe();
    }
  }

  bool get isLoggedIn => token.value.isNotEmpty;

  Future<void> register(String fullName, String email, String phone, String password, String confirmPassword) async {
    try {
      isLoading.value = true;
      final response = await _authService.register(fullName, email, phone, password, confirmPassword);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        Get.snackbar('Thành công', data['message'] ?? 'Đăng ký thành công! Vui lòng xác thực email.');
        // Chuyển sang trang xác thực và truyền email qua arguments
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
        Get.offAllNamed('/home');
      } else if (response.statusCode == 400 && data['requiresVerification'] == true) {
        // Nếu tài khoản chưa xác thực, backend trả về requiresVerification: true
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
        // Xác thực xong mới quay về trang Login
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
      }
    } catch (e) {}
  }
}
