import 'package:flutter/material.dart';

class DiscountManagementScreen extends StatelessWidget {
  const DiscountManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dữ liệu mẫu danh sách mã giảm giá
    final List<Map<String, dynamic>> discounts = [
      {
        "code": "KM30",
        "description": "Giảm 30% cho lần đầu",
        "expiry": "31/12/2023",
        "status": "Đang chạy",
        "usage": "150/500",
      },
      {
        "code": "GIOTHANG",
        "description": "Giảm 20k khung giờ vàng",
        "expiry": "15/11/2023",
        "status": "Hết hạn",
        "usage": "200/200",
      },
      {
        "code": "CHUPANH",
        "description": "Giảm 50k đặt sân trên 1M",
        "expiry": "20/12/2023",
        "status": "Đang chạy",
        "usage": "45/100",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý Discount"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: discounts.length,
        itemBuilder: (context, index) {
          final item = discounts[index];
          final bool isActive = item['status'] == "Đang chạy";

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.confirmation_number_outlined, color: isActive ? Colors.orange : Colors.grey),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['code'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(item['description'], style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text("HSD: ${item['expiry']}", style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item['status'],
                        style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(item['usage'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
