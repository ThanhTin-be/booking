import 'package:flutter/material.dart';

class MyOffersScreen extends StatelessWidget {
  const MyOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> vouchers = [
      {
        "title": "Giảm 20k cho sân mới",
        "code": "WELCOME20",
        "expiry": "31/12/2023",
        "description": "Áp dụng cho khách hàng lần đầu đặt sân trên ứng dụng.",
        "discount": "20k",
        "color": Colors.orange,
      },
      {
        "title": "Ưu đãi giờ vàng",
        "code": "HAPPYHOUR",
        "expiry": "15/11/2023",
        "description": "Giảm 10% khi đặt sân từ 10:00 - 14:00 ngày thường.",
        "discount": "10%",
        "color": Colors.blue,
      },
      {
        "title": "Khách hàng thân thiết",
        "code": "LOYALTY50",
        "expiry": "30/11/2023",
        "description": "Giảm 50k cho đơn hàng từ 500k trở lên.",
        "discount": "50k",
        "color": Colors.purple,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ưu đãi của tôi"),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vouchers.length,
        itemBuilder: (context, index) {
          final voucher = vouchers[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Cột trái (Discount)
                    Container(
                      width: 100,
                      color: voucher['color'],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            voucher['discount'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "OFF",
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Cột phải (Details)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              voucher['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              voucher['description'],
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "HSD: ${voucher['expiry']}",
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                                ),
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: voucher['color'],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    minimumSize: const Size(0, 30),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text("Dùng ngay", style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
