import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final WalletController walletController = Get.put(WalletController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Obx(() {
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
                    height: 220,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2962FF), Color(0xFF00B0FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(bottom: Radius.elliptical(400, 60)),
                    ),
                  ),
                  Positioned(
                    top: 70,
                    left: 24,
                    right: 24,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle),
                          child: CircleAvatar(
                            radius: 35,
                            backgroundImage: NetworkImage(authController.avatarUrl),
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user['fullName'] ?? "Khách", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(user['phone'] ?? user['email'] ?? "Chưa có thông tin", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Get.to(() => const EditProfileScreen()),
                          icon: const Icon(Icons.edit_square, color: Colors.white70, size: 20),
                        )
                      ],
                    ),
                  ),
                  // Stats Card
                  Positioned(
                    bottom: -40,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem("Số dư ví", _formatCurrency(walletController.balance.value), Colors.blue),
                          _buildDivider(),
                          _buildStatItem("Điểm thưởng", "${walletController.points.value}", Colors.orange),
                          _buildDivider(),
                          _buildStatItem("Hạng", user['role'] == 'admin' ? 'Admin' : 'Thành viên', Colors.amber),
                        ],
                      )),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 60),

              // --- MENU CHỨC NĂNG ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Quản lý", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),
                    _buildMenuItem(icon: Icons.confirmation_number_outlined, title: "Vé của tôi", iconColor: Colors.orange,
                      onTap: () => Get.to(() => const MyBookingsScreen())),

                    const SizedBox(height: 20),
                    const Text("Công cụ thể thao", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),
                    _buildMenuItem(icon: Icons.scoreboard_outlined, title: "Tính điểm Cầu lông", iconColor: Colors.green,
                      onTap: () => Get.to(() => const BadmintonScoreScreen())),

                    const SizedBox(height: 20),
                    const Text("Tài khoản", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),
                    _buildMenuItem(icon: Icons.person_outline, title: "Chỉnh sửa thông tin",
                      onTap: () => Get.to(() => const EditProfileScreen())),
                    _buildMenuItem(icon: Icons.account_balance_wallet_outlined, title: "Quản lý thanh toán",
                      onTap: () => Get.to(() => const PaymentManagementScreen())),
                    _buildMenuItem(icon: Icons.history, title: "Lịch sử giao dịch",
                      onTap: () => Get.to(() => const TransactionHistoryScreen())),

                    const SizedBox(height: 20),
                    const Text("Tiện ích", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),
                    _buildMenuItem(icon: Icons.card_giftcard, title: "Ưu đãi của tôi",
                      onTap: () => Get.to(() => const MyOffersScreen())),
                    _buildMenuItem(icon: Icons.group_add_outlined, title: "Mời bạn bè", onTap: () {}),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => authController.logout(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          foregroundColor: Colors.redAccent,
                        ),
                        child: const Text("Đăng xuất", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDivider() => Container(height: 30, width: 1, color: Colors.grey[300]);

  Widget _buildMenuItem({
    required IconData icon, required String title, String? badge,
    Color iconColor = const Color(0xFF2962FF), required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), spreadRadius: 1, blurRadius: 5)],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null) Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
              child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
