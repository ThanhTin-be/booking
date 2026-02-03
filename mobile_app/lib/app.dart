import 'package:flutter/material.dart';
import 'views/splash/splash_screen.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/register_screen.dart';
import 'views/auth/forgot_password_screen.dart';
import 'views/main_wrapper.dart';
import 'views/admin/admin_dashboard_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Badminton Booking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Tông màu chủ đạo: Xanh thể thao (Royal Blue)
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2962FF), // Màu xanh đậm, rực rỡ
          primary: const Color(0xFF2962FF),
          secondary: const Color(0xFF00B0FF), // Xanh nhạt hơn cho điểm nhấn
        ),
        scaffoldBackgroundColor: Colors.grey[50], // Nền xám rất nhạt để làm nổi nội dung

        // Cấu hình mặc định cho thanh điều hướng dưới đáy
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF2962FF).withOpacity(0.1), // Màu nền nút khi chọn (Xanh nhạt)
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2962FF)
              );
            }
            return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey
            );
          }),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const MainWrapper(),
        '/admin': (context) => const AdminDashboardScreen(),
      },
    );
  }
}