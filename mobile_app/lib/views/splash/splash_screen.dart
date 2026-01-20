import 'package:flutter/material.dart';
import '../auth/login_screen.dart'; // Import màn hình Login từ thư mục auth

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Thời gian hiển thị splash screen (giây)
  final int splashDuration = 3;

  @override
  void initState() {
    super.initState();
    _startTime();
  }

  // Hàm đếm giờ và chuyển trang
  void _startTime() async {
    await Future.delayed(Duration(seconds: splashDuration));

    // Kiểm tra mounted để tránh lỗi nếu user thoát app giữa chừng
    if (!mounted) return;

    // Chuyển sang màn hình Login (Dùng pushReplacement để không back lại được Splash)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      // Màu nền đã được lấy từ Theme (trong main.dart), không cần set cứng
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- 1. LOGO ---
            // Sau này thay bằng Image.asset('assets/images/logo.png')
            Icon(
              Icons.sports_tennis_rounded,
              size: size.width * 0.3,
              color: primaryColor,
            ),

            const SizedBox(height: 24),

            // --- 2. TÊN APP ---
            const Text(
              "BADMINTON BOOKING",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Màu trắng cho nổi trên nền tối
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 8),

            // --- 3. SLOGAN ---
            Text(
              "Đặt sân nhanh chóng - Dễ dàng",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
            ),

            const SizedBox(height: 60),

            // --- 4. LOADING ---
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}