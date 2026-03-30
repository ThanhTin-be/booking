import 'dart:ui';
import 'package:booking/views/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/notification_controller.dart';
import 'home/home_screen.dart';
import 'home/notifications_screen.dart';
import 'wishlist/wishlist_screen.dart';
import 'chatbot/chatbot_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final NotificationController _notifController = Get.put(NotificationController());
  late final PageController _pageController;

  // Animation controllers for each tab icon
  late final List<AnimationController> _iconAnimControllers;
  late final List<Animation<double>> _iconScaleAnimations;

  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Trang chủ',
      gradient: [Color(0xFF1E56D9), Color(0xFF42A5F5)],
    ),
    _NavItem(
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications_rounded,
      label: 'Thông báo',
      gradient: [Color(0xFF1E56D9), Color(0xFF42A5F5)],
    ),
    _NavItem(
      icon: Icons.smart_toy_outlined,
      activeIcon: Icons.smart_toy_rounded,
      label: 'Trợ lý',
      gradient: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
    ),
    _NavItem(
      icon: Icons.favorite_border_rounded,
      activeIcon: Icons.favorite_rounded,
      label: 'Yêu thích',
      gradient: [Color(0xFFE91E63), Color(0xFFFF5252)],
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Tài khoản',
      gradient: [Color(0xFF1E56D9), Color(0xFF42A5F5)],
    ),
  ];

  final List<Widget> _pages = [
    const HomeScreen(),
    const NotificationsScreen(),
    const ChatbotScreen(isEmbedded: true),
    const WishlistScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    _iconAnimControllers = List.generate(
      _navItems.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );

    _iconScaleAnimations = _iconAnimControllers.map((controller) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 50),
      ]).animate(controller);
    }).toList();

    // Trigger the initial tab animation
    _iconAnimControllers[_currentIndex].forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _iconAnimControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    HapticFeedback.lightImpact();

    // Reset previous icon animation
    _iconAnimControllers[_currentIndex].reset();

    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );

    // Play bounce animation for new icon
    _iconAnimControllers[index].forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: Obx(() {
        return Container(
          margin: EdgeInsets.fromLTRB(12, 0, 12, bottomPadding > 0 ? bottomPadding : 10),
          height: 68,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF1E56D9).withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_navItems.length, (index) {
                    final item = _navItems[index];
                    final isSelected = _currentIndex == index;
                    final hasNotifBadge = index == 1 && _notifController.unreadCount.value > 0;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _onTabTapped(index),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedBuilder(
                          animation: _iconScaleAnimations[index],
                          builder: (context, _) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Icon with scale animation + badge
                                Transform.scale(
                                  scale: _iconScaleAnimations[index].value,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Subtle glow behind selected icon
                                      if (isSelected)
                                        Positioned(
                                          left: -8,
                                          right: -8,
                                          top: -8,
                                          bottom: -8,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: RadialGradient(
                                                colors: [
                                                  item.gradient[0].withOpacity(0.12),
                                                  item.gradient[0].withOpacity(0.0),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 250),
                                        switchInCurve: Curves.easeOut,
                                        switchOutCurve: Curves.easeIn,
                                        transitionBuilder: (child, anim) =>
                                            FadeTransition(opacity: anim, child: child),
                                        child: ShaderMask(
                                          key: ValueKey(isSelected),
                                          shaderCallback: (bounds) {
                                            if (isSelected) {
                                              return LinearGradient(
                                                colors: item.gradient,
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ).createShader(bounds);
                                            }
                                            return LinearGradient(
                                              colors: [Colors.grey[500]!, Colors.grey[500]!],
                                            ).createShader(bounds);
                                          },
                                          child: Icon(
                                            isSelected ? item.activeIcon : item.icon,
                                            size: isSelected ? 26 : 23,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      // Notification badge
                                      if (hasNotifBadge)
                                        Positioned(
                                          right: -5,
                                          top: -3,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFFFF1744), Color(0xFFFF5252)],
                                              ),
                                              borderRadius: BorderRadius.circular(10),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFFFF1744).withOpacity(0.4),
                                                  blurRadius: 5,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              '${_notifController.unreadCount.value}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                height: 1.2,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Label
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 250),
                                  style: GoogleFonts.poppins(
                                    fontSize: isSelected ? 10.5 : 9.5,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: isSelected
                                        ? item.gradient[0]
                                        : Colors.grey[500],
                                    letterSpacing: isSelected ? 0.1 : 0,
                                  ),
                                  child: Text(item.label),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final List<Color> gradient;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.gradient,
  });
}