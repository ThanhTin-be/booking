import 'package:flutter/material.dart';
import '../../widgets/custom_text_field.dart'; // Import widget dùng chung

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_person, size: 80, color: Colors.blue),
                  const SizedBox(height: 20),
                  const Text(
                    "Xin chào!",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const Text("Đăng nhập để tiếp tục"),
                  const SizedBox(height: 40),

                  // Form nhập liệu
                  const CustomTextField(
                    label: "Email",
                    icon: Icons.email_outlined,
                  ),
                  const CustomTextField(
                    label: "Mật khẩu",
                    icon: Icons.lock_outlined,
                    isPassword: true,
                  ),

                  // Quên mật khẩu
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text("Quên mật khẩu?"),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Nút Đăng nhập
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Đăng nhập", style: TextStyle(fontSize: 18)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Chuyển sang trang đăng ký
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Chưa có tài khoản?"),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text("Đăng ký ngay"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}