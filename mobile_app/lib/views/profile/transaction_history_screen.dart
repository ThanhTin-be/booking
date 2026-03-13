import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/wallet_controller.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final WalletController controller = Get.find<WalletController>();
    controller.fetchTransactions();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch sử giao dịch"),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.transactions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.transactions.isEmpty) {
          return const Center(child: Text("Chưa có giao dịch nào"));
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchTransactions(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.transactions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = controller.transactions[index];
              final type = item['type'] ?? 'payment';
              final amount = (item['amount'] ?? 0).toInt();
              final isPositive = type == 'top_up' || type == 'refund';
              final status = item['status'] ?? 'success';
              final description = item['description'] ?? item['title'] ?? 'Giao dịch';
              final createdAt = item['createdAt'] ?? '';

              IconData icon;
              Color color;
              if (type == 'top_up') {
                icon = Icons.account_balance_wallet;
                color = Colors.green;
              } else if (type == 'refund') {
                icon = Icons.replay;
                color = Colors.green;
              } else {
                icon = Icons.payment;
                color = Colors.red;
              }

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color),
                ),
                title: Text(description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(_formatDate(createdAt), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                      status == 'success' ? "Thành công" : status,
                      style: TextStyle(
                        color: status == 'success' ? Colors.green : Colors.red,
                        fontSize: 12, fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  "${isPositive ? '+' : '-'}${_formatCurrency(amount.abs())}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isPositive ? Colors.green : Colors.black),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  String _formatCurrency(int amount) =>
      "${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ";

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate);
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return isoDate;
    }
  }
}
