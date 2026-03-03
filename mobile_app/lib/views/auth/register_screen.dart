import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/custom_text_field.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tạo tài khoản"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Đăng ký thành viên mới",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                CustomTextField(
                  label: "Họ và tên",
                  icon: Icons.person_outline,
                  controller: _nameController,
                ),
                CustomTextField(
                  label: "Email",
                  icon: Icons.email_outlined,
                  controller: _emailController,
                ),
                CustomTextField(
                  label: "Số điện thoại",
                  icon: Icons.phone,
                  controller: _phoneController,
                ),
                CustomTextField(
                  label: "Mật khẩu",
                  icon: Icons.lock_outlined,
                  isPassword: true,
                  controller: _passwordController,
                ),
                CustomTextField(
                  label: "Nhập lại mật khẩu",
                  icon: Icons.lock_outlined,
                  isPassword: true,
                  controller: _confirmPasswordController,
                ),

                const SizedBox(height: 30),

                Obx(() => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _authController.isLoading.value 
                      ? null 
                      : () {
                          _authController.register(
                            _nameController.text,
                            _emailController.text,
                            _phoneController.text,
                            _passwordController.text,
                            _confirmPasswordController.text,
                          );
                        },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _authController.isLoading.value 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Đăng ký", style: TextStyle(fontSize: 18)),
                  ),
                )),

                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Get.back();
                  },
                  child: const Text("Đã có tài khoản? Đăng nhập"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
