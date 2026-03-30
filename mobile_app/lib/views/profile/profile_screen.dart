import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../booking/my_bookings_screen.dart';
import 'edit_profile_screen.dart';
import 'transaction_history_screen.dart';
import 'payment_management_screen.dart';
import 'my_offers_screen.dart';
import 'badminton_score_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _formatCurrency(int amount) =>
      "${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ";

  String _tierLabel(String tier) {
    switch (tier) {
      case 'platinum': return 'Platinum';
      case 'gold': return 'Gold';
      case 'silver': return 'Silver';
      default: return 'Member';
    }
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'platinum': return const Color(0xFF7C3AED);
      case 'gold': return const Color(0xFFD97706);
      case 'silver': return const Color(0xFF2563EB);
      default: return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final WalletController walletController = Get.put(WalletController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Obx(() {
        // Nếu chưa đăng nhập → hiện giao diện khách
        if (!authController.isLoggedIn) {
          return _buildGuestView(context);
        }

        final user = authController.user;
        return SingleChildScrollView(
          child: Column(
            children: [
              // --- HEADER ---
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    height: 230,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E56D9), Color(0xFF00C2FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // Decorative circle
                  Positioned(
                    top: -30,
                    right: -40,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    left: 24,
                    right: 24,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => Get.to(() => const EditProfileScreen()),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 36,
                              backgroundImage: NetworkImage(authController.avatarUrl),
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['fullName'] ?? "Khách",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user['phone'] ?? user['email'] ?? "Chưa có thông tin",
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => Get.to(() => const EditProfileScreen()),
                            icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Stats Card
                  Positioned(
                    bottom: -46,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            "Số dư ví",
                            _formatCurrency(walletController.balance.value),
                            const Color(0xFF1E56D9),
                            Icons.account_balance_wallet_rounded,
                          ),
                          _buildDivider(),
                          _buildStatItem(
                            "Điểm thưởng",
                            "${walletController.points.value} điểm",
                            Colors.orange,
                            Icons.stars_rounded,
                          ),
                          _buildDivider(),
                          _buildStatItem(
                            "Hạng",
                            _tierLabel(walletController.tier.value),
                            _tierColor(walletController.tier.value),
                            Icons.workspace_premium_rounded,
                          ),
                        ],
                      )),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 70),

              // --- MENU ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Quản lý"),
                    _buildMenuItem(
                      icon: Icons.confirmation_number_rounded,
                      title: "Vé của tôi",
                      subtitle: "Xem lịch đặt sân",
                      iconColor: Colors.orange,
                      onTap: () => Get.to(() => const MyBookingsScreen()),
                    ),

                    _buildSectionTitle("Công cụ thể thao"),
                    _buildMenuItem(
                      icon: Icons.scoreboard_rounded,
                      title: "Tính điểm Cầu lông",
                      subtitle: "Công cụ tính điểm thi đấu",
                      iconColor: Colors.green,
                      onTap: () => Get.to(() => const BadmintonScoreScreen()),
                    ),

                    _buildSectionTitle("Tài khoản"),
                    _buildMenuItem(
                      icon: Icons.person_rounded,
                      title: "Chỉnh sửa thông tin",
                      subtitle: "Cập nhật hồ sơ cá nhân",
                      onTap: () => Get.to(() => const EditProfileScreen()),
                    ),
                    _buildMenuItem(
                      icon: Icons.account_balance_wallet_rounded,
                      title: "Quản lý thanh toán",
                      subtitle: "Ví & phương thức thanh toán",
                      iconColor: const Color(0xFF1E56D9),
                      onTap: () => Get.to(() => const PaymentManagementScreen()),
                    ),
                    _buildMenuItem(
                      icon: Icons.history_rounded,
                      title: "Lịch sử giao dịch",
                      subtitle: "Xem các giao dịch gần đây",
                      iconColor: Colors.purple,
                      onTap: () => Get.to(() => const TransactionHistoryScreen()),
                    ),

                    _buildSectionTitle("Tiện ích"),
                    _buildMenuItem(
                      icon: Icons.card_giftcard_rounded,
                      title: "Ưu đãi của tôi",
                      subtitle: "Voucher & khuyến mãi",
                      iconColor: Colors.pinkAccent,
                      onTap: () => Get.to(() => const MyOffersScreen()),
                    ),
                    _buildMenuItem(
                      icon: Icons.group_add_rounded,
                      title: "Mời bạn bè",
                      subtitle: "Chia sẻ và nhận thưởng",
                      iconColor: Colors.teal,
                      onTap: () {},
                    ),

                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextButton.icon(
                        onPressed: () => authController.logout(),
                        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                        label: Text(
                          "Đăng xuất",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.redAccent,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// Giao diện khi chưa đăng nhập
  Widget _buildGuestView(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header gradient
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 40,
              bottom: 50,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E56D9), Color(0xFF00C2FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                // Guest avatar
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: Obx(() => CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.white24,
                    backgroundImage: Get.find<AuthController>().guestAvatar.value.isNotEmpty
                        ? NetworkImage(Get.find<AuthController>().avatarUrl)
                        : null,
                    child: Get.find<AuthController>().guestAvatar.value.isEmpty
                        ? const Icon(Icons.person_rounded, size: 48, color: Colors.white)
                        : null,
                  )),
                ),
                const SizedBox(height: 16),
                Text(
                  "Chào bạn!",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Đăng nhập để trải nghiệm đầy đủ",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Login / Register buttons
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E56D9), Color(0xFF42A5F5)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E56D9).withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => Get.toNamed('/login'),
                          icon: const Icon(Icons.login_rounded, color: Colors.white, size: 20),
                          label: Text(
                            "ĐĂNG NHẬP",
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Register button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => Get.toNamed('/register'),
                        icon: Icon(Icons.person_add_rounded, color: const Color(0xFF1E56D9), size: 20),
                        label: Text(
                          "ĐĂNG KÝ TÀI KHOẢN",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E56D9),
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: const Color(0xFF1E56D9).withOpacity(0.3), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Features preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Đăng nhập để:",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(Icons.confirmation_number_rounded, "Đặt sân và quản lý vé"),
                _buildFeatureItem(Icons.account_balance_wallet_rounded, "Quản lý ví & thanh toán"),
                _buildFeatureItem(Icons.card_giftcard_rounded, "Nhận ưu đãi & voucher"),
                _buildFeatureItem(Icons.favorite_rounded, "Lưu sân yêu thích"),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1E56D9).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF1E56D9), size: 20),
          ),
          const SizedBox(width: 14),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildDivider() => Container(height: 36, width: 1, color: const Color(0xFFEEF0F5));

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    String? badge,
    Color iconColor = const Color(0xFF1E56D9),
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 22),
          ],
        ),
      ),
    );
  }
}
