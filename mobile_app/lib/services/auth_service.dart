import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';

class AuthService {
  String get baseUrl => '${AppConfig.apiBaseUrl}/auth';

  Future<http.Response> register(String fullName, String email, String phone, String password, String confirmPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'confirmPassword': confirmPassword,
      }),
    );
    return response;
  }

  Future<http.Response> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    return response;
  }

  Future<http.Response> googleLogin(String idToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
      }),
    );
    return response;
  }

  Future<http.Response> facebookLogin(String accessToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/facebook'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'accessToken': accessToken,
      }),
    );
    return response;
  }

  Future<http.Response> facebookLoginWithCode(String code, String redirectUri) async {
    final response = await http.post(
      Uri.parse('$baseUrl/facebook'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'code': code,
        'redirectUri': redirectUri,
      }),
    );
    return response;
  }

  Future<http.Response> verifyEmail(String email, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'verificationCode': code,
      }),
    );
    return response;
  }

  Future<http.Response> resendCode(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/resend-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
      }),
    );
    return response;
  }

  Future<http.Response> logout(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  Future<http.Response> getMe(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  Future<http.Response> getRandomAvatar() async {
    final response = await http.get(
      Uri.parse('$baseUrl/random-avatar'),
      headers: {'Content-Type': 'application/json'},
    );
    return response;
  }
}
