import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/wallet_controller.dart';
import '../booking/vnpay_webview_screen.dart';

class PaymentManagementScreen extends StatelessWidget {
  const PaymentManagementScreen({super.key});

  String _formatCurrency(int amount) =>
      "${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ";

  @override
  Widget build(BuildContext context) {
    final WalletController walletController = Get.put(WalletController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Quản lý thanh toán",
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ví của tôi section
            Obx(() => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E56D9), Color(0xFF00C2FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E56D9).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Ví của tôi",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatCurrency(walletController.balance.value),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Số dư khả dụng",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _showTopUpDialog(context, walletController),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                      label: Text(
                        "Nạp tiền qua VNPay",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1E56D9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            )),

            const SizedBox(height: 24),

            // Mệnh giá nạp nhanh
            Text(
              "Nạp nhanh",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: [50000, 100000, 200000, 300000, 500000, 1000000]
                  .map((amount) => _buildQuickTopUpCard(
                        context,
                        amount,
                        walletController,
                      ))
                  .toList(),
            ),

            const SizedBox(height: 24),

            // Phương thức thanh toán
            Text(
              "Phương thức thanh toán",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            _buildPaymentMethodItem(
              iconPath: Icons.qr_code_2_rounded,
              title: "VNPay QR",
              subtitle: "Thanh toán bằng mã QR VNPay",
              color: const Color(0xFF1E56D9),
              isActive: true,
            ),
            _buildPaymentMethodItem(
              iconPath: Icons.account_balance_wallet_rounded,
              title: "Ví ứng dụng",
              subtitle: "Thanh toán bằng số dư ví",
              color: const Color(0xFF10B981),
              isActive: true,
            ),
            _buildPaymentMethodItem(
              iconPath: Icons.storefront_rounded,
              title: "Tại quầy",
              subtitle: "Thanh toán khi đến sân",
              color: const Color(0xFFE67E22),
              isActive: true,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTopUpCard(
    BuildContext context,
    int amount,
    WalletController walletController,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _processTopUp(context, amount, walletController),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Center(
            child: Text(
              _formatCurrency(amount),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E56D9),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTopUpDialog(BuildContext context, WalletController walletController) {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E56D9).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_card_rounded, color: Color(0xFF1E56D9), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              "Nạp tiền vào ví",
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: "Số tiền (VND)",
                labelStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
                hintText: "Tối thiểu 10.000đ",
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.monetization_on_outlined, color: Color(0xFF1E56D9)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1E56D9), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Quick amount chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [50000, 100000, 200000, 500000].map((amt) {
                return ActionChip(
                  label: Text(
                    _formatCurrency(amt),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E56D9),
                    ),
                  ),
                  backgroundColor: const Color(0xFF1E56D9).withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: const Color(0xFF1E56D9).withOpacity(0.2)),
                  ),
                  onPressed: () {
                    amountController.text = amt.toString();
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Hủy",
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = int.tryParse(amountController.text.trim());
              if (amount == null || amount < 10000) {
                Get.snackbar('Lỗi', 'Số tiền nạp tối thiểu 10.000đ');
                return;
              }
              Navigator.pop(ctx);
              _processTopUp(context, amount, walletController);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E56D9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              "Nạp tiền",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processTopUp(
    BuildContext context,
    int amount,
    WalletController walletController,
  ) async {
    final paymentUrl = await walletController.createTopupUrl(amount);
    if (paymentUrl == null) return;

    if (!context.mounted) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => VnpayWebviewScreen(
          paymentUrl: paymentUrl,
          title: 'Nạp tiền ví',
        ),
      ),
    );

    if (result == true) {
      walletController.fetchBalance();
      walletController.fetchTransactions();
      Get.snackbar(
        'Thành công',
        'Nạp tiền vào ví thành công!',
        backgroundColor: Colors.green[50],
        colorText: Colors.green[800],
      );
    }
  }

  Widget _buildPaymentMethodItem({
    required IconData iconPath,
    required String title,
    required String subtitle,
    required Color color,
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(iconPath, color: color, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
        ),
        trailing: isActive
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Kích hoạt",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
