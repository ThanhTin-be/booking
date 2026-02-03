import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dữ liệu mẫu
    final List<Map<String, dynamic>> notifications = [
      {
        "title": "Đặt sân thành công",
        "content": "Sân PM PICKLEBALL của bạn đã được xác nhận vào lúc 17:30 ngày 25/10.",
        "time": "2 phút trước",
        "icon": Icons.check_circle,
        "color": Colors.green,
        "isRead": false,
      },
      {
        "title": "Ưu đãi mới hấp dẫn",
        "content": "Giảm ngay 20% khi đặt sân vào khung giờ vàng 10:00 - 14:00.",
        "time": "1 giờ trước",
        "icon": Icons.local_offer,
        "color": Colors.orange,
        "isRead": false,
      },
      {
        "title": "Nhắc nhở lịch đặt",
        "content": "Bạn có lịch hẹn tại sân Cầu Lông Chiến Thắng sau 30 phút nữa.",
        "time": "3 giờ trước",
        "icon": Icons.access_time,
        "color": Colors.blue,
        "isRead": true,
      },
      {
        "title": "Cập nhật ứng dụng",
        "content": "Phiên bản 1.0.2 đã sẵn sàng. Hãy cập nhật để trải nghiệm tính năng mới.",
        "time": "1 ngày trước",
        "icon": Icons.system_update_alt,
        "color": Colors.purple,
        "isRead": true,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông báo"),
        centerTitle: true,
      ),
      body: ListView.separated(
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = notifications[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: item['color'].withOpacity(0.1),
              child: Icon(item['icon'], color: item['color']),
            ),
            title: Text(
              item['title'],
              style: TextStyle(
                fontWeight: item['isRead'] ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(item['content'], style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Text(item['time'], style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
            isThreeLine: true,
            tileColor: item['isRead'] ? null : Colors.blue.withOpacity(0.02),
            onTap: () {
              // Xử lý khi bấm vào thông báo
              _showNotificationDetail(context, item);
            },
          );
        },
      ),
    );
  }

  void _showNotificationDetail(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(item['icon'], color: item['color'], size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['title'],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              item['time'],
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            Text(
              item['content'],
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Đóng"),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
