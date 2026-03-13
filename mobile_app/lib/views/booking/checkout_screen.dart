import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/booking_controller.dart';
import '../../controllers/wallet_controller.dart';
import 'qr_payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final String courtId;
  final String courtName;
  final String date;
  final String displayDate;
  final List<String> selectedTimeSlots;
  final List<String> selectedSlotIds;
  final int totalPrice;

  const CheckoutScreen({
    super.key,
    required this.courtId,
    required this.courtName,
    required this.date,
    required this.displayDate,
    required this.selectedTimeSlots,
    required this.selectedSlotIds,
    required this.totalPrice,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final BookingController _bookingController = Get.put(BookingController());
  final AuthController _authController = Get.find<AuthController>();
  final WalletController _walletController = Get.put(WalletController());

  int _selectedPaymentMethod = 0; // 0: cash, 1: bank_transfer, 2: momo, 3: wallet
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  int _discountAmount = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = _authController.user;
    _nameController.text = user['fullName'] ?? '';
    _phoneController.text = user['phone'] ?? '';
    _walletController.fetchBalance();
  }

  int get _finalPrice => (widget.totalPrice - _discountAmount).clamp(0, widget.totalPrice);

  String _getPaymentMethodString() {
    switch (_selectedPaymentMethod) {
      case 1: return 'bank_transfer';
      case 2: return 'momo';
      case 3: return 'wallet';
      default: return 'cash';
    }
  }

  Future<void> _applyDiscount() async {
    final code = _discountController.text.trim();
    if (code.isEmpty) return;
    final result = await _bookingController.applyDiscount(code, widget.totalPrice);
    if (result != null) {
      setState(() {
        _discountAmount = (result['discountAmount'] ?? 0).toInt();
      });
      Get.snackbar('Thành công', 'Đã áp dụng mã giảm giá');
    }
  }

  Future<void> _submitBooking() async {
    if (_isSubmitting) return;

    // Validate contact info
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      Get.snackbar('Thiếu thông tin', 'Vui lòng nhập đầy đủ họ tên và số điện thoại');
      return;
    }

    // Check wallet balance before proceeding with wallet payment
    if (_selectedPaymentMethod == 3 && _walletController.balance.value < _finalPrice) {
      Get.snackbar('Số dư không đủ',
          'Số dư ví của bạn không đủ. Vui lòng nạp thêm hoặc chọn phương thức khác.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Step 1: Create booking via API
      final result = await _bookingController.createBooking(
        courtId: widget.courtId,
        date: widget.date,
        timeSlotIds: widget.selectedSlotIds,
        paymentMethod: _getPaymentMethodString(),
        discountCode: _discountController.text.trim(),
        contactName: _nameController.text.trim(),
        contactPhone: _phoneController.text.trim(),
      );

      if (result == null) {
        setState(() => _isSubmitting = false);
        return;
      }

      final booking = result['booking'];
      final bookingId = booking?['id']?.toString() ?? '';

      if (bookingId.isEmpty) {
        Get.snackbar('Lỗi', 'Không nhận được mã booking');
        setState(() => _isSubmitting = false);
        return;
      }

      // Step 2: Create payment for non-cash methods
      if (_selectedPaymentMethod != 0) {
        final paymentResult = await _bookingController.createPayment(
          bookingId,
          _getPaymentMethodString(),
        );

        if (paymentResult == null) {
          Get.snackbar('Lỗi', 'Tạo thanh toán thất bại. Vui lòng thử lại.');
          setState(() => _isSubmitting = false);
          return;
        }

        final paymentId = paymentResult['payment']?['id']?.toString() ?? '';

        // Step 3: Handle based on payment method
        if (_selectedPaymentMethod == 3) {
          // Wallet payment: confirm immediately to deduct balance
          final confirmed = await _bookingController.confirmPayment(paymentId);
          setState(() => _isSubmitting = false);

          if (confirmed) {
            _walletController.fetchBalance(); // Refresh wallet balance
            _walletController.fetchTransactions(); // Refresh transaction history
            _showSuccessDialog();
          } else {
            Get.snackbar('Lỗi', 'Xác nhận thanh toán ví thất bại');
          }
        } else {
          // Bank / MoMo: navigate to QR payment screen
          setState(() => _isSubmitting = false);
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QRPaymentScreen(
                paymentMethod: _selectedPaymentMethod == 2 ? "MoMo" : "Bank",
                amount: _finalPrice,
                paymentId: paymentId,
              ),
            ),
          );
        }
      } else {
        // Cash payment: no payment creation needed, just show success
        setState(() => _isSubmitting = false);
        _showSuccessDialog();
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      Get.snackbar('Lỗi', 'Đã xảy ra lỗi. Vui lòng thử lại.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text("Xác nhận thanh toán", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. THÔNG TIN SÂN ---
            _buildSectionTitle("Thông tin đặt sân"),
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network("https://via.placeholder.com/150", width: 60, height: 60, fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(width: 60, height: 60, color: Colors.grey[300], child: const Icon(Icons.sports_tennis)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.courtName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(widget.displayDate, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Khung giờ:", style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Wrap(
                          spacing: 8, runSpacing: 8,
                          children: widget.selectedTimeSlots.map((slot) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: primaryColor.withOpacity(0.3)),
                            ),
                            child: Text(slot, style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold)),
                          )).toList(),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),

            // --- 2. THÔNG TIN LIÊN HỆ ---
            _buildSectionTitle("Thông tin liên hệ"),
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Họ và tên", prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: "Số điện thoại", prefixIcon: const Icon(Icons.phone_android, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

            // --- 3. PHƯƠNG THỨC THANH TOÁN ---
            _buildSectionTitle("Phương thức thanh toán"),
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _buildPaymentOption(0, "Thanh toán tại sân", Icons.storefront, Colors.orange),
                  const Divider(height: 1),
                  _buildPaymentOption(1, "Chuyển khoản ngân hàng (QR)", Icons.qr_code_2, Colors.blue),
                  const Divider(height: 1),
                  _buildPaymentOption(2, "Ví MoMo", Icons.account_balance_wallet, Colors.pink),
                  const Divider(height: 1),
                  Obx(() => _buildPaymentOption(
                    3,
                    "Ví của tôi (${_formatCurrency(_walletController.balance.value)})",
                    Icons.wallet,
                    Colors.teal,
                  )),
                ],
              ),
            ),

            // --- 4. ƯU ĐÃI ---
            _buildSectionTitle("Ưu đãi & Giảm giá"),
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.discount_outlined, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _discountController,
                      decoration: const InputDecoration(hintText: "Nhập mã giảm giá", border: InputBorder.none),
                    ),
                  ),
                  TextButton(
                    onPressed: _applyDiscount,
                    child: const Text("Áp dụng", style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),

            // --- 5. CHI TIẾT THANH TOÁN ---
            _buildSectionTitle("Chi tiết thanh toán"),
            const SizedBox(height: 8),
            _buildPriceRow("Tạm tính", widget.totalPrice),
            _buildPriceRow("Phí dịch vụ", 0),
            _buildPriceRow("Giảm giá", _discountAmount, isDiscount: true),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Tổng thanh toán", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(_formatCurrency(_finalPrice), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor)),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Tổng cộng", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(_formatCurrency(_finalPrice), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
                  ],
                ),
              ),
              SizedBox(
                width: 180, height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700], foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("THANH TOÁN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) =>
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87));

  Widget _buildPaymentOption(int value, String title, IconData icon, Color iconColor) {
    return RadioListTile(
      value: value,
      groupValue: _selectedPaymentMethod,
      onChanged: (val) => setState(() => _selectedPaymentMethod = val as int),
      activeColor: Theme.of(context).primaryColor,
      title: Row(children: [Icon(icon, color: iconColor), const SizedBox(width: 12), Text(title, style: const TextStyle(fontSize: 14))]),
    );
  }

  Widget _buildPriceRow(String label, int amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(isDiscount ? "- ${_formatCurrency(amount)}" : _formatCurrency(amount),
            style: TextStyle(fontWeight: FontWeight.w500, color: isDiscount ? Colors.green : Colors.black87)),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) =>
      "${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ";

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text("Đặt sân thành công!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Mã vé của bạn đã được gửi đến email. Vui lòng đến sân đúng giờ nhé!",
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false),
                child: const Text("VỀ TRANG CHỦ"),
              ),
            )
          ],
        ),
      ),
    );
  }
}

