import 'package:flutter/material.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dữ liệu mẫu
    final List<Map<String, dynamic>> transactions = [
      {
        "title": "Thanh toán sân Cầu lông A",
        "date": "20/10/2023 - 14:30",
        "amount": "-150.000đ",
        "status": "Thành công",
        "icon": Icons.payment,
        "color": Colors.red,
      },
      {
        "title": "Nạp tiền vào ví",
        "date": "18/10/2023 - 09:15",
        "amount": "+500.000đ",
        "status": "Thành công",
        "icon": Icons.account_balance_wallet,
        "color": Colors.green,
      },
      {
        "title": "Thanh toán sân Cầu lông B",
        "date": "15/10/2023 - 18:00",
        "amount": "-200.000đ",
        "status": "Thành công",
        "icon": Icons.payment,
        "color": Colors.red,
      },
      {
        "title": "Hoàn tiền hủy sân",
        "date": "12/10/2023 - 10:00",
        "amount": "+150.000đ",
        "status": "Thành công",
        "icon": Icons.replay,
        "color": Colors.green,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch sử giao dịch"),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = transactions[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item['color'].withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(item['icon'], color: item['color']),
            ),
            title: Text(
              item['title'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(item['date'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  item['status'],
                  style: TextStyle(
                    color: item['status'] == "Thành công" ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: Text(
              item['amount'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: item['amount'].startsWith('+') ? Colors.green : Colors.black,
              ),
            ),
          );
        },
      ),
    );
  }
}
