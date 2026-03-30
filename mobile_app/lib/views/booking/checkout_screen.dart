import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/booking_controller.dart';
import '../../controllers/wallet_controller.dart';
import 'vnpay_webview_screen.dart';
import 'booking_detail_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final String courtId;
  final String courtName;
  final Map<String, List<String>> subCourtSlots; // {subCourtName: [timeSlot1, timeSlot2,...]}
  final String date;
  final String displayDate;
  final List<String> selectedTimeSlots;
  final List<String> selectedSlotIds;
  final int totalPrice;

  const CheckoutScreen({
    super.key,
    required this.courtId,
    required this.courtName,
    this.subCourtSlots = const {},
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

  int _selectedPaymentMethod = 0; // 0: cash, 1: QR, 2: wallet
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  int _discountAmount = 0;
  String _appliedVoucherCode = '';
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
      case 1: return 'vnpay';
      case 2: return 'wallet';
      default: return 'cash';
    }
  }

  Future<void> _applyDiscount() async {
    final code = _discountController.text.trim();
    if (code.isEmpty) return;
    final result = await _bookingController.applyDiscount(code, widget.totalPrice);
    if (result != null) {
      setState(() {
        _discountAmount = (result['discount']?['discountAmount'] ?? result['discountAmount'] ?? 0).toInt();
        _appliedVoucherCode = code;
      });
      Get.snackbar('Thành công', 'Đã áp dụng mã giảm giá', backgroundColor: Colors.green[50], colorText: Colors.green[800]);
    }
  }

  void _removeDiscount() {
    setState(() {
      _discountAmount = 0;
      _appliedVoucherCode = '';
      _discountController.clear();
    });
  }

  Future<void> _showVoucherPopup() async {
    showDialog(
      context: context,
      builder: (ctx) => _VoucherPopup(
        bookingController: _bookingController,
        orderTotal: widget.totalPrice,
        onSelect: (code) {
          _discountController.text = code;
          _applyDiscount();
        },
      ),
    );
  }

  Future<void> _submitBooking() async {
    if (_isSubmitting) return;
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      Get.snackbar('Thiếu thông tin', 'Vui lòng nhập đầy đủ họ tên và số điện thoại');
      return;
    }
    if (_selectedPaymentMethod == 2 && _walletController.balance.value < _finalPrice) {
      Get.snackbar('Số dư không đủ', 'Số dư ví không đủ. Vui lòng nạp thêm hoặc chọn phương thức khác.');
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      final result = await _bookingController.createBooking(
        courtId: widget.courtId,
        date: widget.date,
        timeSlotIds: widget.selectedSlotIds,
        paymentMethod: _getPaymentMethodString(),
        discountCode: _discountController.text.trim(),
        contactName: _nameController.text.trim(),
        contactPhone: _phoneController.text.trim(),
      );
      if (result == null) { setState(() => _isSubmitting = false); return; }

      final booking = result['booking'];
      final bookingId = booking?['id']?.toString() ?? '';
      if (bookingId.isEmpty) {
        Get.snackbar('Lỗi', 'Không nhận được mã booking');
        setState(() => _isSubmitting = false);
        return;
      }

      if (_selectedPaymentMethod == 1) {
        // === VNPay payment ===
        final paymentUrl = await _bookingController.createVnpayPayment(bookingId);
        if (paymentUrl == null) {
          Get.snackbar('Lỗi', 'Tạo thanh toán VNPay thất bại.');
          setState(() => _isSubmitting = false);
          return;
        }
        setState(() => _isSubmitting = false);
        if (!mounted) return;
        final vnpayResult = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => VnpayWebviewScreen(
              paymentUrl: paymentUrl,
              title: 'QR Chuyển khoản',
            ),
          ),
        );
        if (vnpayResult == true) {
          _showSuccessDialog(bookingId);
        }
      } else if (_selectedPaymentMethod == 2) {
        // === Wallet payment ===
        final paymentResult = await _bookingController.createPayment(bookingId, 'wallet');
        if (paymentResult == null) {
          Get.snackbar('Lỗi', 'Tạo thanh toán thất bại.');
          setState(() => _isSubmitting = false);
          return;
        }
        final paymentId = paymentResult['payment']?['id']?.toString() ?? '';
        final confirmed = await _bookingController.confirmPayment(paymentId);
        setState(() => _isSubmitting = false);
        if (confirmed) {
          _walletController.fetchBalance();
          _walletController.fetchTransactions();
          _showSuccessDialog(bookingId);
        } else {
          Get.snackbar('Lỗi', 'Xác nhận thanh toán ví thất bại');
        }
      } else {
        setState(() => _isSubmitting = false);
        _showSuccessDialog(bookingId);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      Get.snackbar('Lỗi', 'Đã xảy ra lỗi. Vui lòng thử lại.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text("Xác nhận đặt sân", style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        child: Column(children: [
          // ─── 1. THÔNG TIN SÂN ĐẶT ───
          _buildCard(
            icon: Icons.sports_tennis_rounded, iconColor: const Color(0xFF1E56D9),
            title: "Thông tin sân đặt",
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.courtName, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(widget.displayDate, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700])),
              ]),
              const SizedBox(height: 12),
              // Hiển thị từng sân con + các khung giờ
              ...widget.subCourtSlots.entries.map((entry) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1E56D9).withOpacity(0.12)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(color: Color(0xFF1E56D9), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(entry.key, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E56D9))),
                    const Spacer(),
                    Text("${entry.value.length} slot", style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                  ]),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: entry.value.map((time) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF1E56D9).withOpacity(0.2)),
                    ),
                    child: Text(time, style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E56D9))),
                  )).toList()),
                ]),
              )),
              // Fallback nếu không có subcourt data
              if (widget.subCourtSlots.isEmpty)
                Wrap(spacing: 6, runSpacing: 6, children: widget.selectedTimeSlots.map((slot) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E56D9).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1E56D9).withOpacity(0.2)),
                  ),
                  child: Text(slot, style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E56D9))),
                )).toList()),
            ]),
          ),
          const SizedBox(height: 12),

          // ─── 2. THÔNG TIN LIÊN HỆ ───
          _buildCard(
            icon: Icons.person_rounded, iconColor: const Color(0xFF8B5CF6),
            title: "Thông tin liên hệ",
            child: Column(children: [
              TextField(
                controller: _nameController,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  labelText: "Họ và tên",
                  labelStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.person_outline_rounded, color: Colors.grey[400], size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  labelText: "Số điện thoại",
                  labelStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.phone_android_rounded, color: Colors.grey[400], size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // ─── 3. PHƯƠNG THỨC THANH TOÁN ───
          _buildCard(
            icon: Icons.payment_rounded, iconColor: const Color(0xFFE67E22),
            title: "Phương thức thanh toán",
            child: Column(children: [
              _buildPaymentTile(0, "Thanh toán tại quầy", Icons.storefront_rounded, const Color(0xFFE67E22), "Thanh toán khi đến sân"),
              const SizedBox(height: 8),
              _buildPaymentTile(1, "QR chuyển khoản", Icons.qr_code_2_rounded, const Color(0xFF3B82F6), "Quét mã QR để thanh toán"),
              const SizedBox(height: 8),
              Obx(() => _buildPaymentTile(
                2, "Ví của tôi", Icons.account_balance_wallet_rounded, const Color(0xFF10B981),
                "Số dư: ${_formatCurrency(_walletController.balance.value)}",
                trailing: _walletController.balance.value < _finalPrice && _selectedPaymentMethod == 2
                  ? Text("Không đủ", style: GoogleFonts.poppins(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600))
                  : null,
              )),
            ]),
          ),
          const SizedBox(height: 12),

          // ─── 4. ƯU ĐÃI & GIẢM GIÁ ───
          _buildCard(
            icon: Icons.local_offer_rounded, iconColor: const Color(0xFFF59E0B),
            title: "Ưu đãi & Giảm giá",
            child: Column(children: [
              // Voucher input + áp dụng
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(children: [
                  const SizedBox(width: 8),
                  Icon(Icons.confirmation_number_outlined, size: 18, color: Colors.grey[400]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _discountController,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Nhập mã voucher",
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1E56D9), Color(0xFF3B82F6)]),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: const Color(0xFF1E56D9).withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _applyDiscount,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Center(child: Text("Áp dụng", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white))),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
              // Nút chọn voucher
              InkWell(
                onTap: _showVoucherPopup,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [const Color(0xFFFFF7ED), Colors.orange[50]!]),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.25)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.15), borderRadius: BorderRadius.circular(7)),
                      child: const Icon(Icons.confirmation_number_rounded, size: 15, color: Color(0xFFF59E0B)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text("Xem danh sách voucher của bạn", style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFB45309), fontWeight: FontWeight.w500))),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFB45309)),
                  ]),
                ),
              ),
              if (_appliedVoucherCode.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.green[50], borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(children: [
                    Icon(Icons.check_circle_rounded, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Expanded(child: Text("Mã $_appliedVoucherCode · Giảm ${_formatCurrency(_discountAmount)}",
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.green[800], fontWeight: FontWeight.w600))),
                    GestureDetector(onTap: _removeDiscount, child: Icon(Icons.close_rounded, size: 18, color: Colors.green[700])),
                  ]),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 12),

          // ─── 5. CHI TIẾT THANH TOÁN ───
          _buildCard(
            icon: Icons.receipt_long_rounded, iconColor: const Color(0xFF6366F1),
            title: "Chi tiết thanh toán",
            child: Column(children: [
              _priceRow("Giá gốc (${widget.selectedTimeSlots.length} slot)", widget.totalPrice),
              if (_discountAmount > 0) _priceRow("Giảm giá", _discountAmount, isDiscount: true),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text("Tổng thanh toán", style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
                Text(_formatCurrency(_finalPrice), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E56D9))),
              ]),
            ]),
          ),
        ]),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Row(children: [
            Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Tổng cộng", style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12)),
              Text(_formatCurrency(_finalPrice), style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1E56D9))),
            ])),
            SizedBox(
              height: 50, width: 180,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E56D9), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0,
                ),
                child: _isSubmitting
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text("THANH TOÁN", style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── HELPER WIDGETS ───

  Widget _buildCard({required IconData icon, required Color iconColor, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }

  Widget _buildPaymentTile(int value, String title, IconData icon, Color color, String subtitle, {Widget? trailing}) {
    final isSelected = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.06) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color.withOpacity(0.4) : Colors.grey[200]!, width: isSelected ? 1.5 : 1),
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87)),
            Text(subtitle, style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey[500])),
          ])),
          if (trailing != null) ...[trailing, const SizedBox(width: 8)],
          if (isSelected)
            Container(width: 22, height: 22, decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, size: 14, color: Colors.white))
          else
            Container(width: 22, height: 22, decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!, width: 2), shape: BoxShape.circle)),
        ]),
      ),
    );
  }

  Widget _priceRow(String label, int amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
        Text(isDiscount ? "- ${_formatCurrency(amount)}" : _formatCurrency(amount),
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: isDiscount ? Colors.green[700] : Colors.black87)),
      ]),
    );
  }

  String _formatCurrency(int amount) =>
    "${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ";

  void _showSuccessDialog(String bookingId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded, color: Colors.green[600], size: 56),
            ),
            const SizedBox(height: 20),
            Text(
              'Đặt sân thành công!',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Khung giờ đã được xác nhận.\nVui lòng đến sân đúng giờ nhé!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => BookingDetailScreen(bookingId: bookingId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E56D9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'XEM CHI TIẾT VÉ',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(ctx).pushNamedAndRemoveUntil('/home', (route) => false),
              child: Text(
                'Về trang chủ',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── VOUCHER POPUP ───

class _VoucherPopup extends StatelessWidget {
  final BookingController bookingController;
  final int orderTotal;
  final Function(String code) onSelect;

  const _VoucherPopup({required this.bookingController, required this.orderTotal, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Icon(Icons.confirmation_number_rounded, color: Color(0xFFF59E0B), size: 24),
            const SizedBox(width: 8),
            Expanded(child: Text("Voucher của bạn", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700))),
            GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close_rounded, size: 22, color: Colors.grey)),
          ]),
          const SizedBox(height: 16),
          Flexible(
            child: FutureBuilder<List<dynamic>>(
              future: bookingController.fetchVouchers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final vouchers = snapshot.data ?? [];
                if (vouchers.isEmpty) {
                  return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.local_offer_outlined, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text("Không có voucher nào", style: GoogleFonts.poppins(color: Colors.grey[500])),
                  ]));
                }
                return ListView.separated(
                  shrinkWrap: true, itemCount: vouchers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final v = vouchers[index];
                    final code = v['code'] ?? '';
                    final desc = v['description'] ?? '';
                    final validTo = v['validTo'] ?? '';
                    final usedCount = v['usedCount'] ?? 0;
                    final usageLimit = v['usageLimit'] ?? 100;
                    final minOrder = v['minOrderValue'] ?? 0;
                    final discountType = v['discountType'] ?? 'fixed';
                    final discountValue = v['discountValue'] ?? 0;
                    final isValid = usedCount < usageLimit && orderTotal >= minOrder;

                    return AnimatedOpacity(
                      opacity: isValid ? 1.0 : 0.5,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isValid ? const Color(0xFFFFF7ED) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isValid ? const Color(0xFFF59E0B).withOpacity(0.3) : Colors.grey[300]!),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isValid ? const Color(0xFFF59E0B) : Colors.grey[400],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(code, style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                            const Spacer(),
                            Text(
                              discountType == 'percent' ? "Giảm $discountValue%" : "Giảm ${_fmtC(discountValue)}",
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: isValid ? const Color(0xFFB45309) : Colors.grey),
                            ),
                          ]),
                          if (desc.isNotEmpty) ...[const SizedBox(height: 6), Text(desc, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]))],
                          const SizedBox(height: 6),
                          Row(children: [
                            Text("HSD: ${validTo.toString().length >= 10 ? validTo.toString().substring(0, 10) : validTo}", style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                            const Spacer(),
                            if (isValid)
                              GestureDetector(
                                onTap: () { Navigator.pop(context); onSelect(code); },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF1E56D9), Color(0xFF3B82F6)]),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [BoxShadow(color: const Color(0xFF1E56D9).withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))],
                                  ),
                                  child: Text("Dùng ngay", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                                ),
                              )
                            else
                              Text(
                                orderTotal < minOrder ? "Đơn tối thiểu ${_fmtC(minOrder)}" : "Đã hết lượt",
                                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                              ),
                          ]),
                        ]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  String _fmtC(dynamic amount) {
    final a = (amount is int) ? amount : (amount as num).toInt();
    return "${a.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ";
  }
}
