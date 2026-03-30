import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class MyOffersScreen extends StatefulWidget {
  const MyOffersScreen({super.key});

  @override
  State<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends State<MyOffersScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _vouchers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchVouchers();
  }

  Future<void> _fetchVouchers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _api.getMyVouchers();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _vouchers = data['vouchers'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Không thể tải danh sách ưu đãi';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi kết nối đến server';
        _isLoading = false;
      });
    }
  }

  Color _getVoucherColor(int index) {
    const colors = [
      Color(0xFFFF6B35),
      Color(0xFF1E56D9),
      Color(0xFF7C3AED),
      Color(0xFF059669),
      Color(0xFFDB2777),
      Color(0xFFD97706),
    ];
    return colors[index % colors.length];
  }

  String _formatDiscountValue(Map<String, dynamic> voucher) {
    if (voucher['discountType'] == 'percent') {
      return '${voucher['discountValue']}%';
    } else {
      final value = voucher['discountValue'] ?? 0;
      if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(0)}k';
      }
      return '${value}đ';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatCurrency(int amount) =>
      "${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ";

  int _daysRemaining(String? dateStr) {
    if (dateStr == null) return 0;
    try {
      final expiry = DateTime.parse(dateStr);
      return expiry.difference(DateTime.now()).inDays;
    } catch (e) {
      return 0;
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép mã: $code'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1E56D9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          "Ưu đãi của tôi",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.black, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _vouchers.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _fetchVouchers,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _vouchers.length,
                        itemBuilder: (context, index) {
                          final voucher = _vouchers[index] as Map<String, dynamic>;
                          return _buildVoucherCard(voucher, index);
                        },
                      ),
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_giftcard_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Chưa có ưu đãi nào",
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            "Hãy quay lại sau để nhận voucher mới!",
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 80, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(_error!, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchVouchers,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("Thử lại"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E56D9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(Map<String, dynamic> voucher, int index) {
    final color = _getVoucherColor(index);
    final daysLeft = _daysRemaining(voucher['validTo']);
    final isExpiringSoon = daysLeft <= 3 && daysLeft >= 0;
    final code = voucher['code'] ?? '';
    final description = voucher['description'] ?? '';
    final minOrder = voucher['minOrderValue'] ?? 0;
    final maxDiscount = voucher['maxDiscountAmount'];
    final usageLimit = voucher['usageLimit'] ?? 0;
    final usedCount = voucher['usedCount'] ?? 0;
    final remaining = usageLimit - usedCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left side — discount value
              Container(
                width: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      _formatDiscountValue(voucher),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      "GIẢM",
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Dotted divider
                    Row(
                      children: List.generate(
                        8,
                        (i) => Expanded(
                          child: Container(
                            height: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (remaining > 0)
                      Text(
                        "Còn $remaining lượt",
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              // Right side — details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row with expiry badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              description.isNotEmpty ? description : code,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: const Color(0xFF1A1A2E),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isExpiringSoon)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Sắp hết!",
                                style: GoogleFonts.poppins(
                                  color: Colors.redAccent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Conditions
                      if (minOrder > 0)
                        _buildConditionTag(Icons.shopping_bag_outlined, "Đơn tối thiểu ${_formatCurrency(minOrder)}"),
                      if (maxDiscount != null && voucher['discountType'] == 'percent')
                        _buildConditionTag(Icons.arrow_downward_rounded, "Giảm tối đa ${_formatCurrency(maxDiscount)}"),
                      const Spacer(),
                      // Bottom row: expiry + copy code
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 13, color: isExpiringSoon ? Colors.redAccent : Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                "HSD: ${_formatDate(voucher['validTo'])}",
                                style: GoogleFonts.poppins(
                                  color: isExpiringSoon ? Colors.redAccent : Colors.grey[500],
                                  fontSize: 11,
                                  fontWeight: isExpiringSoon ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _copyCode(code),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: color.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.copy_rounded, size: 13, color: color),
                                  const SizedBox(width: 4),
                                  Text(
                                    code,
                                    style: GoogleFonts.poppins(
                                      color: color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
  }

  Widget _buildConditionTag(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
