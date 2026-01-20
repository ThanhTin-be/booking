import 'package:flutter/material.dart';
import '../../widgets/custom_text_field.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tạo tài khoản"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent, // AppBar trong suốt
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

                const CustomTextField(
                  label: "Họ và tên",
                  icon: Icons.person_outline,
                ),
                const CustomTextField(
                  label: "Email",
                  icon: Icons.email_outlined,
                ),
                const CustomTextField(
                  label: "Số điện thoại",
                  icon: Icons.phone_android,
                ),
                const CustomTextField(
                  label: "Mật khẩu",
                  icon: Icons.lock_outlined,
                  isPassword: true,
                ),
                const CustomTextField(
                  label: "Nhập lại mật khẩu",
                  icon: Icons.lock_outlined,
                  isPassword: true,
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // Logic đăng ký xong thì quay về Login hoặc vào Home
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Màu nút khác biệt chút
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Đăng ký", style: TextStyle(fontSize: 18)),
                  ),
                ),

                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Quay lại trang Login
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