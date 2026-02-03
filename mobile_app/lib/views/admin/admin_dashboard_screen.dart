import 'package:flutter/material.dart';
import 'discount_management_screen.dart';
import 'user_management_screen.dart';
import 'revenue_report_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Admin Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tổng quan hệ thống",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Stats Row 1
            Row(
              children: [
                _buildStatCard("Người dùng", "1,250", Icons.people, Colors.blue),
                const SizedBox(width: 16),
                _buildStatCard("Sân hiện có", "45", Icons.sports_tennis, Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            
            // Stats Row 2
            Row(
              children: [
                _buildStatCard("Đặt sân mới", "12", Icons.book_online, Colors.orange),
                const SizedBox(width: 16),
                _buildStatCard("Doanh thu", "25.5M", Icons.monetization_on, Colors.red),
              ],
            ),
            
            const SizedBox(height: 30),
            
            const Text(
              "Quản lý chức năng",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            _buildAdminMenuItem(
              context,
              "Quản lý sân",
              "Thêm, sửa, xóa thông tin các sân thể thao",
              Icons.stadium,
              Colors.indigo,
              () {},
            ),
            _buildAdminMenuItem(
              context,
              "Quản lý đặt lịch",
              "Xem và duyệt các yêu cầu đặt sân",
              Icons.calendar_month,
              Colors.teal,
              () {},
            ),
            _buildAdminMenuItem(
              context,
              "Quản lý Discount",
              "Tạo mã khuyến mãi và ưu đãi cho người dùng",
              Icons.confirmation_number_outlined,
              Colors.orange,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DiscountManagementScreen()),
                );
              },
            ),
            _buildAdminMenuItem(
              context,
              "Quản lý người dùng",
              "Phân quyền và quản lý tài khoản thành viên",
              Icons.admin_panel_settings,
              Colors.brown,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                );
              },
            ),
            _buildAdminMenuItem(
              context,
              "Báo cáo doanh thu",
              "Thống kê chi tiết theo ngày/tháng/năm",
              Icons.bar_chart,
              Colors.deepPurple,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RevenueReportScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminMenuItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
