import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/booking_controller.dart';
import '../../config/config.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final BookingController _bookingController = Get.find<BookingController>();
  Map<String, dynamic>? booking;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => isLoading = true);
    final data = await _bookingController.fetchBookingDetail(widget.bookingId);
    if (mounted) {
      setState(() {
        booking = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E56D9)))
          : booking == null
              ? _buildError()
              : _buildContent(context),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text("Không thể tải chi tiết vé", style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 15)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text("Quay lại"),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final b = booking!;
    final court = b['court'] is Map ? b['court'] as Map<String, dynamic> : <String, dynamic>{};
    final subCourt = b['subCourt'] is Map ? b['subCourt'] as Map<String, dynamic> : null;
    final timeSlots = b['timeSlots'] is List ? b['timeSlots'] as List : [];
    final discount = b['discount'] is Map ? b['discount'] as Map<String, dynamic> : null;

    final status = b['status'] ?? 'pending';
    final bookingCode = b['bookingCode'] ?? '';
    final date = b['date'] ?? '';
    final startTime = b['startTime'] ?? '';
    final endTime = b['endTime'] ?? '';
    final totalPrice = (b['totalPrice'] ?? 0) as num;
    final discountAmount = (b['discountAmount'] ?? 0) as num;
    final finalPrice = (b['finalPrice'] ?? 0) as num;
    final paymentMethod = b['paymentMethod'] ?? 'cash';
    final contactName = b['contactName'] ?? '';
    final contactPhone = b['contactPhone'] ?? '';
    final createdAt = b['createdAt'] ?? '';

    final courtName = court['name'] ?? 'Sân không rõ';
    final courtAddress = court['address'] ?? '';
    final rawImages = (court['images'] is List && (court['images'] as List).isNotEmpty)
        ? court['images'] as List
        : [];
    final courtImage = rawImages.isNotEmpty ? AppConfig.toFullImageUrl(rawImages[0] as String) : '';

    final statusInfo = _getStatusInfo(status);
    final paymentLabel = _getPaymentMethodLabel(paymentMethod);
    final canCancel = status == 'pending' || status == 'confirmed';

    return CustomScrollView(
      slivers: [
        // --- HERO IMAGE HEADER ---
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: const Color(0xFF0D47A1),
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                courtImage.isNotEmpty
                    ? Image.network(courtImage, fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                              color: const Color(0xFF1565C0),
                              child: const Icon(Icons.sports_tennis, color: Colors.white38, size: 80),
                            ))
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0D47A1), Color(0xFF1E88E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(Icons.sports_tennis, color: Colors.white24, size: 80),
                      ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                // Court info on image
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courtName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (courtAddress.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Colors.white70, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                courtAddress,
                                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // --- BODY ---
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ===== BOOKING CODE & STATUS CARD =====
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Booking code
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Mã vé", style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  bookingCode,
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0D47A1),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: bookingCode));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Đã sao chép mã vé $bookingCode"),
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  child: Icon(Icons.copy_rounded, size: 16, color: Colors.grey[400]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: statusInfo.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusInfo.color.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusInfo.icon, size: 16, color: statusInfo.color),
                            const SizedBox(width: 6),
                            Text(
                              statusInfo.label,
                              style: GoogleFonts.poppins(
                                color: statusInfo.color,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ===== DATE & TIME CARD =====
                _buildSectionCard(
                  icon: Icons.calendar_today_rounded,
                  iconColor: const Color(0xFF1E88E5),
                  title: "Thời gian đặt sân",
                  children: [
                    _buildInfoRow(Icons.event_rounded, "Ngày", _formatDisplayDate(date)),
                    _buildInfoRow(Icons.access_time_rounded, "Giờ", "$startTime – $endTime"),
                    if (subCourt != null)
                      _buildInfoRow(Icons.grid_view_rounded, "Sân con", subCourt['name'] ?? ''),
                  ],
                ),

                const SizedBox(height: 12),

                // ===== TIME SLOTS DETAIL =====
                if (timeSlots.isNotEmpty) ...[
                  _buildSectionCard(
                    icon: Icons.view_timeline_rounded,
                    iconColor: const Color(0xFF7C4DFF),
                    title: "Chi tiết các slot",
                    children: _buildGroupedSlots(timeSlots),
                  ),
                  const SizedBox(height: 12),
                ],

                // ===== PAYMENT CARD =====
                _buildSectionCard(
                  icon: Icons.receipt_long_rounded,
                  iconColor: const Color(0xFFFF9800),
                  title: "Thanh toán",
                  children: [
                    _buildInfoRow(Icons.payment_rounded, "Phương thức", paymentLabel),
                    _buildPriceRow("Tổng tiền sân", totalPrice.toInt()),
                    if (discountAmount > 0) ...[
                      _buildPriceRow("Giảm giá", -discountAmount.toInt(), isDiscount: true),
                      if (discount != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 32, bottom: 4),
                          child: Text(
                            "Mã: ${discount['code'] ?? ''}",
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.green[600]),
                          ),
                        ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const SizedBox(width: 32),
                          Text(
                            "Thành tiền",
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Text(
                            _formatCurrency(finalPrice.toInt()),
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0D47A1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ===== CONTACT INFO =====
                if (contactName.isNotEmpty || contactPhone.isNotEmpty)
                  _buildSectionCard(
                    icon: Icons.person_outline_rounded,
                    iconColor: const Color(0xFF26A69A),
                    title: "Thông tin liên hệ",
                    children: [
                      if (contactName.isNotEmpty)
                        _buildInfoRow(Icons.badge_outlined, "Họ tên", contactName),
                      if (contactPhone.isNotEmpty)
                        _buildInfoRow(Icons.phone_outlined, "Điện thoại", contactPhone),
                    ],
                  ),

                if (contactName.isNotEmpty || contactPhone.isNotEmpty) const SizedBox(height: 12),

                // ===== BOOKING TIME =====
                _buildSectionCard(
                  icon: Icons.info_outline_rounded,
                  iconColor: Colors.grey[600]!,
                  title: "Thông tin khác",
                  children: [
                    _buildInfoRow(Icons.schedule_rounded, "Thời gian đặt", _formatCreatedAt(createdAt)),
                  ],
                ),

                const SizedBox(height: 24),

                // ===== CANCEL BUTTON =====
                if (canCancel) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showCancelDialog(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.cancel_outlined),
                      label: Text("Hủy vé", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
  // ===== GROUPED SLOTS BY SUB-COURT =====

  List<Widget> _buildGroupedSlots(List timeSlots) {
    // Group slots by subCourt name
    final Map<String, List<dynamic>> grouped = {};
    for (var slot in timeSlots) {
      final sc = slot['subCourt'] is Map ? slot['subCourt'] : null;
      final scName = sc != null ? (sc['name'] ?? 'Không rõ') : 'Không rõ';
      grouped.putIfAbsent(scName, () => []);
      grouped[scName]!.add(slot);
    }

    // Sort slots in each group by startTime
    for (var list in grouped.values) {
      list.sort((a, b) => (a['startTime'] ?? '').compareTo(b['startTime'] ?? ''));
    }

    final widgets = <Widget>[];
    final entries = grouped.entries.toList();

    for (int i = 0; i < entries.length; i++) {
      final scName = entries[i].key;
      final slots = entries[i].value;

      // Sub-court header
      if (i > 0) widgets.add(const SizedBox(height: 10));
      widgets.add(
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF7C4DFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.grid_view_rounded, size: 16, color: Color(0xFF7C4DFF)),
            ),
            const SizedBox(width: 10),
            Text(
              scName,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF37474F),
              ),
            ),
          ],
        ),
      );

      // Time slot rows (indented)
      for (var slot in slots) {
        final slotStart = slot['startTime'] ?? '';
        final slotEnd = slot['endTime'] ?? '';
        final slotPrice = (slot['price'] ?? 0) as num;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 6, bottom: 2),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[350],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "$slotStart – $slotEnd",
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                  ),
                ),
                Text(
                  _formatCurrency(slotPrice.toInt()),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0D47A1),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return widgets;
  }

  // ===== BUILDING BLOCKS =====

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
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
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.grey[800]),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[400]),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800]),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, int amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 32),
          Text(label, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
          const Spacer(),
          Text(
            isDiscount ? "- ${_formatCurrency(amount.abs())}" : _formatCurrency(amount),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDiscount ? Colors.green[600] : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  // ===== FORMATTERS =====

  String _formatCurrency(int amount) =>
      "${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ";

  String _formatDisplayDate(String dateStr) {
    // "YYYY-MM-DD" → "DD/MM/YYYY"
    if (dateStr.length >= 10) {
      final parts = dateStr.split('-');
      if (parts.length == 3) return "${parts[2]}/${parts[1]}/${parts[0]}";
    }
    return dateStr;
  }

  String _formatCreatedAt(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} – "
          "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (_) {
      return isoDate;
    }
  }

  _StatusInfo _getStatusInfo(String status) {
    switch (status) {
      case 'pending':
        return _StatusInfo("Đang giữ", Colors.orange, Icons.hourglass_top_rounded);
      case 'confirmed':
        return _StatusInfo("Đã xác nhận", Colors.green, Icons.check_circle_outline_rounded);
      case 'completed':
        return _StatusInfo("Hoàn tất", Colors.blue, Icons.task_alt_rounded);
      case 'cancelled':
        return _StatusInfo("Đã hủy", Colors.red, Icons.cancel_outlined);
      default:
        return _StatusInfo(status, Colors.grey, Icons.info_outline);
    }
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Tiền mặt';
      case 'vnpay':
        return 'VNPay';
      case 'momo':
        return 'MoMo';
      case 'wallet':
        return 'Ví điện tử';
      case 'bank':
        return 'Chuyển khoản';
      default:
        return method;
    }
  }

  // ===== CANCEL DIALOG =====

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Hủy vé", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Bạn có chắc muốn hủy vé này? Thao tác này không thể hoàn tác.",
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Không", style: GoogleFonts.poppins(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _bookingController.cancelBooking(widget.bookingId);
              Navigator.pop(context); // go back to list
            },
            child: Text("Hủy vé", style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  final IconData icon;
  _StatusInfo(this.label, this.color, this.icon);
}
