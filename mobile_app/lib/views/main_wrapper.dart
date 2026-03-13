import 'package:booking/views/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home/home_screen.dart';
import 'wishlist/wishlist_screen.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderPage({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E56D9).withOpacity(0.08),
                  const Color(0xFF00C2FF).withOpacity(0.08),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: const Color(0xFF1E56D9)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tính năng đang được phát triển",
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const PlaceholderPage(title: "Bản đồ sân", icon: Icons.map_rounded),
    const WishlistScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          height: 68,
          elevation: 0,
          backgroundColor: Colors.white,
          selectedIndex: _currentIndex,
          onDestinationSelected: (int index) => setState(() => _currentIndex = index),
          animationDuration: const Duration(milliseconds: 500),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined, size: 26),
              selectedIcon: const Icon(Icons.home_rounded, color: Color(0xFF1E56D9), size: 26),
              label: 'Trang chủ',
            ),
            NavigationDestination(
              icon: const Icon(Icons.map_outlined, size: 26),
              selectedIcon: const Icon(Icons.map_rounded, color: Color(0xFF1E56D9), size: 26),
              label: 'Bản đồ',
            ),
            NavigationDestination(
              icon: const Icon(Icons.favorite_border_rounded, size: 26),
              selectedIcon: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 26),
              label: 'Yêu thích',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded, size: 26),
              selectedIcon: const Icon(Icons.person_rounded, color: Color(0xFF1E56D9), size: 26),
              label: 'Tài khoản',
            ),
          ],
        ),
      ),
    );
  }
}