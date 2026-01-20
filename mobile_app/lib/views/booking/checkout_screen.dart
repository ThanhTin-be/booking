import 'package:flutter/material.dart';

class CheckoutScreen extends StatefulWidget {
  final String courtName;
  final String date;
  final List<String> selectedTimeSlots; // Danh sách giờ đã chọn (VD: ["17:30", "18:00"])
  final int totalPrice;

  const CheckoutScreen({
    super.key,
    required this.courtName,
    required this.date,
    required this.selectedTimeSlots,
    required this.totalPrice,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Quản lý phương thức thanh toán đang chọn
  int _selectedPaymentMethod = 0; // 0: Tiền mặt, 1: Chuyển khoản, 2: MoMo

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Xác nhận thanh toán",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. THÔNG TIN SÂN (SUMMARY CARD) ---
            _buildSectionTitle("Thông tin đặt sân"),
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Ảnh thumbnail sân
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          "https://via.placeholder.com/150", // Placeholder ảnh sân
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 60, height: 60, color: Colors.grey[300], child: const Icon(Icons.sports_tennis),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.courtName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(widget.date, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  // Danh sách khung giờ
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Khung giờ:", style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.selectedTimeSlots.map((slot) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: primaryColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              slot,
                              style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold),
                            ),
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildTextField(label: "Họ và tên", icon: Icons.person_outline, initialValue: "Thanh Tín"),
                  const SizedBox(height: 12),
                  _buildTextField(label: "Số điện thoại", icon: Icons.phone_android, initialValue: "0909 123 456"),
                ],
              ),
            ),

            // --- 3. PHƯƠNG THỨC THANH TOÁN ---
            _buildSectionTitle("Phương thức thanh toán"),
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildPaymentOption(0, "Thanh toán tại sân", Icons.storefront, Colors.orange),
                  const Divider(height: 1),
                  _buildPaymentOption(1, "Chuyển khoản ngân hàng (QR)", Icons.qr_code_2, Colors.blue),
                  const Divider(height: 1),
                  _buildPaymentOption(2, "Ví MoMo", Icons.account_balance_wallet, Colors.pink),
                ],
              ),
            ),

            // --- 4. ƯU ĐÃI ---
            _buildSectionTitle("Ưu đãi & Giảm giá"),
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.discount_outlined, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Nhập mã giảm giá",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
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
            _buildPriceRow("Giảm giá", 0, isDiscount: true),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Tổng thanh toán", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  _formatCurrency(widget.totalPrice),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 100), // Khoảng trống dưới cùng
          ],
        ),
      ),

      // --- BOTTOM BAR ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
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
                    Text(
                      _formatCurrency(widget.totalPrice),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 180,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Xử lý thanh toán -> Chuyển sang trang Success
                    _showSuccessDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("THANH TOÁN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildTextField({required String label, required IconData icon, required String initialValue}) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildPaymentOption(int value, String title, IconData icon, Color iconColor) {
    return RadioListTile(
      value: value,
      groupValue: _selectedPaymentMethod,
      onChanged: (val) {
        setState(() {
          _selectedPaymentMethod = val as int;
        });
      },
      activeColor: Theme.of(context).primaryColor,
      title: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, int amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            isDiscount ? "- ${_formatCurrency(amount)}" : _formatCurrency(amount),
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDiscount ? Colors.green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    // Format đơn giản: 50000 -> 50.000 đ
    return "${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ";
  }

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
            const Text("Mã vé của bạn đã được gửi đến email. Vui lòng đến sân đúng giờ nhé!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Quay về trang chủ
                  Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                },
                child: const Text("VỀ TRANG CHỦ"),
              ),
            )
          ],
        ),
      ),
    );
  }
}