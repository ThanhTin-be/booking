import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/wallet_controller.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WalletController _controller = Get.find<WalletController>();

  final _filters = const [null, 'top_up', 'payment', 'refund'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _controller.fetchTransactions();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _controller.fetchTransactions(type: _filters[_tabController.index]);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxScrolled) => [
          // Gradient AppBar with wallet balance summary
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF1E3A5F),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Get.back(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Lịch sử giao dịch",
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  width: 40,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF60A5FA),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Obx(() => Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Số dư: ${_formatCurrency(_controller.balance.value)}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${_controller.points.value} điểm",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF2563EB),
                  unselectedLabelColor: const Color(0xFF9CA3AF),
                  indicatorColor: const Color(0xFF2563EB),
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                  unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 13),
                  tabs: const [
                    Tab(text: "Tất cả"),
                    Tab(text: "Nạp tiền"),
                    Tab(text: "Thanh toán"),
                    Tab(text: "Hoàn tiền"),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: Obx(() {
          if (_controller.isLoading.value && _controller.transactions.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            );
          }
          if (_controller.transactions.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            color: const Color(0xFF2563EB),
            onRefresh: () => _controller.fetchTransactions(type: _filters[_tabController.index]),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: _controller.transactions.length,
              itemBuilder: (context, index) {
                final item = _controller.transactions[index] as Map<String, dynamic>;

                // Group header by date
                final dateStr = _getDateOnly(item['createdAt'] ?? '');
                final prevDateStr = index > 0
                    ? _getDateOnly((_controller.transactions[index - 1] as Map<String, dynamic>)['createdAt'] ?? '')
                    : '';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dateStr != prevDateStr) ...[
                      if (index > 0) const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          _formatDateHeader(item['createdAt'] ?? ''),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                    _buildTransactionCard(item),
                  ],
                );
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.receipt_long_rounded, size: 48, color: Color(0xFF93A3C0)),
          ),
          const SizedBox(height: 20),
          Text(
            "Chưa có giao dịch nào",
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF4B5563)),
          ),
          const SizedBox(height: 8),
          Text(
            "Các giao dịch sẽ hiển thị tại đây",
            style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> item) {
    final type = item['type'] ?? 'payment';
    final amount = (item['amount'] ?? 0) is int ? item['amount'] : (item['amount'] as num).toInt();
    final isPositive = type == 'top_up' || type == 'vnpay_topup' || type == 'refund';
    final status = item['status'] ?? 'success';
    final description = item['description'] ?? item['title'] ?? 'Giao dịch';
    final createdAt = item['createdAt'] ?? '';

    // Related booking info
    final relatedBooking = item['relatedBooking'];
    String? bookingCode;
    if (relatedBooking is Map) {
      bookingCode = relatedBooking['bookingCode'];
    }

    IconData icon;
    Color iconBgColor;
    Color iconColor;
    String typeLabel;

    if (type == 'top_up' || type == 'vnpay_topup') {
      icon = Icons.account_balance_wallet_rounded;
      iconBgColor = const Color(0xFFECFDF5);
      iconColor = const Color(0xFF059669);
      typeLabel = type == 'vnpay_topup' ? 'Nạp VNPay' : 'Nạp tiền';
    } else if (type == 'refund') {
      icon = Icons.replay_rounded;
      iconBgColor = const Color(0xFFF0F9FF);
      iconColor = const Color(0xFF0EA5E9);
      typeLabel = 'Hoàn tiền';
    } else {
      icon = Icons.shopping_cart_rounded;
      iconBgColor = const Color(0xFFFFF7ED);
      iconColor = const Color(0xFFEA580C);
      typeLabel = 'Thanh toán';
    }

    // Status colors
    Color statusBgColor;
    Color statusTextColor;
    String statusLabel;
    IconData statusIcon;

    if (status == 'success') {
      statusBgColor = const Color(0xFFECFDF5);
      statusTextColor = const Color(0xFF059669);
      statusLabel = 'Thành công';
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'pending') {
      statusBgColor = const Color(0xFFFFFBEB);
      statusTextColor = const Color(0xFFD97706);
      statusLabel = 'Đang xử lý';
      statusIcon = Icons.hourglass_top_rounded;
    } else {
      statusBgColor = const Color(0xFFFEF2F2);
      statusTextColor = const Color(0xFFDC2626);
      statusLabel = 'Thất bại';
      statusIcon = Icons.cancel_rounded;
    }

    // Amount color based on status
    Color amountColor;
    if (status == 'success') {
      amountColor = isPositive ? const Color(0xFF059669) : const Color(0xFFDC2626);
    } else if (status == 'pending') {
      amountColor = const Color(0xFFD97706);
    } else {
      amountColor = const Color(0xFF9CA3AF);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'success'
              ? const Color(0xFFE5E7EB)
              : status == 'pending'
                  ? const Color(0xFFFDE68A)
                  : const Color(0xFFFECACA),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showTransactionDetail(item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon with gradient-like background
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: const Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Type badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: iconBgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              typeLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: iconColor,
                              ),
                            ),
                          ),
                          if (bookingCode != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                bookingCode,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            _formatTime(createdAt),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Amount & status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${isPositive ? '+' : '-'}${_formatCurrency(amount.abs())}",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusTextColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: statusTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTransactionDetail(Map<String, dynamic> item) {
    final type = item['type'] ?? 'payment';
    final amount = (item['amount'] ?? 0) is int ? item['amount'] : (item['amount'] as num).toInt();
    final isPositive = type == 'top_up' || type == 'vnpay_topup' || type == 'refund';
    final status = item['status'] ?? 'success';
    final description = item['description'] ?? item['title'] ?? 'Giao dịch';
    final createdAt = item['createdAt'] ?? '';
    final txnId = item['_id'] ?? '';

    final relatedBooking = item['relatedBooking'];
    String? bookingCode;
    if (relatedBooking is Map) {
      bookingCode = relatedBooking['bookingCode'];
    }

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    if (status == 'success') {
      statusColor = const Color(0xFF059669);
      statusLabel = 'Thành công';
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'pending') {
      statusColor = const Color(0xFFD97706);
      statusLabel = 'Đang xử lý';
      statusIcon = Icons.hourglass_top_rounded;
    } else {
      statusColor = const Color(0xFFDC2626);
      statusLabel = 'Thất bại';
      statusIcon = Icons.cancel_rounded;
    }

    String typeLabel;
    if (type == 'top_up' || type == 'vnpay_topup') {
      typeLabel = type == 'vnpay_topup' ? 'Nạp tiền qua VNPay' : 'Nạp tiền';
    } else if (type == 'refund') {
      typeLabel = 'Hoàn tiền';
    } else {
      typeLabel = 'Thanh toán';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Status icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              statusLabel,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${isPositive ? '+' : '-'}${_formatCurrency(amount.abs())}",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 24),
            // Details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _detailRow("Loại giao dịch", typeLabel),
                  _divider(),
                  _detailRow("Mô tả", description),
                  if (bookingCode != null) ...[
                    _divider(),
                    _detailRow("Mã đặt sân", bookingCode),
                  ],
                  _divider(),
                  _detailRow("Thời gian", _formatFullDate(createdAt)),
                  _divider(),
                  _detailRow("Mã giao dịch", txnId.length > 10 ? '...${txnId.substring(txnId.length - 10)}' : txnId),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  "Đóng",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF9CA3AF)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1F2937)),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(color: const Color(0xFFE5E7EB).withOpacity(0.5), height: 1);
  }

  String _formatCurrency(int amount) =>
      "${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ";

  String _getDateOnly(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate);
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    } catch (_) {
      return '';
    }
  }

  String _formatDateHeader(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final transDate = DateTime(dt.year, dt.month, dt.day);

      if (transDate == today) return 'Hôm nay';
      if (transDate == today.subtract(const Duration(days: 1))) return 'Hôm qua';

      final weekdays = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];
      return "${weekdays[dt.weekday - 1]}, ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (_) {
      return isoDate;
    }
  }

  String _formatTime(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return isoDate;
    }
  }

  String _formatFullDate(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} - ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (_) {
      return isoDate;
    }
  }
}
