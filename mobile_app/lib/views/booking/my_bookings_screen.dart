import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/booking_controller.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BookingController _bookingController = Get.put(BookingController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  void _loadBookings() {
    _bookingController.fetchBookings('upcoming');
    _bookingController.fetchBookings('completed');
    _bookingController.fetchBookings('cancelled');
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Vé của tôi", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Sắp tới"),
            Tab(text: "Hoàn thành"),
            Tab(text: "Đã hủy"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingTab(_bookingController.upcomingBookings, isUpcoming: true),
          _buildBookingTab(_bookingController.completedBookings),
          _buildBookingTab(_bookingController.cancelledBookings),
        ],
      ),
    );
  }

  Widget _buildBookingTab(RxList<dynamic> bookingsList, {bool isUpcoming = false}) {
    return Obx(() {
      if (_bookingController.isLoading.value && bookingsList.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (bookingsList.isEmpty) {
        return Center(child: Text("Không có vé nào", style: TextStyle(color: Colors.grey[500])));
      }
      return RefreshIndicator(
        onRefresh: () async => _loadBookings(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookingsList.length,
          itemBuilder: (context, index) {
            final item = bookingsList[index];
            return _buildTicketCard(item, context, isUpcoming: isUpcoming);
          },
        ),
      );
    });
  }

  Widget _buildTicketCard(dynamic item, BuildContext context, {bool isUpcoming = false}) {
    final status = item['status'] ?? 'upcoming';
    Color statusColor = status == 'upcoming' ? Colors.green : (status == 'completed' ? Colors.blue : Colors.red);
    String statusText = status == 'upcoming' ? "Sắp tới" : (status == 'completed' ? "Hoàn tất" : "Đã hủy");

    final court = item['court'] is Map ? item['court'] : {};
    final courtName = court['name'] ?? item['courtName'] ?? 'Sân không rõ';
    final date = item['date'] ?? '';
    final timeSlots = item['timeSlots'] is List ? item['timeSlots'] : [];
    final time = timeSlots.isNotEmpty
        ? "${timeSlots.first['startTime'] ?? ''} - ${timeSlots.last['endTime'] ?? ''}"
        : '';
    final price = item['totalPrice'] ?? 0;
    final image = (court['images'] is List && court['images'].isNotEmpty)
        ? court['images'][0]
        : 'https://via.placeholder.com/150';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(image, width: 80, height: 80, fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(width: 80, height: 80, color: Colors.grey[300], child: const Icon(Icons.sports_tennis)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(courtName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(date, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatCurrency(price is int ? price : int.tryParse(price.toString()) ?? 0),
                        style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    if (isUpcoming) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          final bookingId = item['_id'];
                          if (bookingId != null) {
                            _showCancelDialog(context, bookingId);
                          }
                        },
                        child: const Text("Hủy vé", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ]
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hủy vé"),
        content: const Text("Bạn có chắc muốn hủy vé này?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Không")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _bookingController.cancelBooking(bookingId);
            },
            child: const Text("Hủy vé", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) =>
      "${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ";
}