import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/notification_controller.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationController controller = Get.put(NotificationController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông báo"),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => controller.markAllAsRead(),
            child: const Text("Đọc tất cả", style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.notifications.isEmpty) {
          return const Center(child: Text("Không có thông báo nào"));
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchNotifications(),
          child: ListView.separated(
            itemCount: controller.notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = controller.notifications[index];
              final isRead = item['isRead'] ?? false;
              final title = item['title'] ?? '';
              final content = item['message'] ?? item['content'] ?? '';
              final createdAt = item['createdAt'] ?? '';
              final type = item['type'] ?? 'info';

              // Icon & color based on type
              IconData icon;
              Color color;
              switch (type) {
                case 'booking':
                  icon = Icons.check_circle;
                  color = Colors.green;
                  break;
                case 'promotion':
                  icon = Icons.local_offer;
                  color = Colors.orange;
                  break;
                case 'reminder':
                  icon = Icons.access_time;
                  color = Colors.blue;
                  break;
                case 'payment':
                  icon = Icons.payment;
                  color = Colors.purple;
                  break;
                default:
                  icon = Icons.notifications;
                  color = Colors.blue;
              }

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(icon, color: color),
                ),
                title: Text(title, style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(content, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(_formatTime(createdAt), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
                isThreeLine: true,
                tileColor: isRead ? null : Colors.blue.withOpacity(0.02),
                onTap: () {
                  final notifId = item['_id'];
                  if (notifId != null && !isRead) {
                    controller.markAsRead(notifId);
                  }
                  _showNotificationDetail(context, item, icon, color);
                },
              );
            },
          ),
        );
      }),
    );
  }

  String _formatTime(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      if (diff.inDays < 7) return '${diff.inDays} ngày trước';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  void _showNotificationDetail(BuildContext context, dynamic item, IconData icon, Color color) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(width: 12),
                Expanded(child: Text(item['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 16),
            Text(_formatTime(item['createdAt'] ?? ''), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 16),
            Text(item['message'] ?? item['content'] ?? '', style: const TextStyle(fontSize: 16, height: 1.5)),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Đóng")),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
