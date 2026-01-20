import 'package:flutter/material.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        leading: const BackButton(color: Colors.black), // Có nút Back để quay về Profile
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
          _buildBookingList(status: "upcoming"),
          _buildBookingList(status: "completed"),
          _buildBookingList(status: "cancelled"),
        ],
      ),
    );
  }

  Widget _buildBookingList({required String status}) {
    // Dữ liệu giả lập
    final List<Map<String, dynamic>> dummyBookings = [
      {
        "id": "#BK1001",
        "courtName": "PM PICKLEBALL",
        "subCourt": "Sân 5",
        "date": "20/01/2026",
        "time": "17:30 - 19:00",
        "price": "150.000 đ",
        "status": "upcoming",
        "image": "https://img.freepik.com/free-photo/pickleball-court-with-net_23-2151439498.jpg?w=1060",
      },
      {
        "id": "#BK0998",
        "courtName": "Sân Cầu Lông ABC",
        "subCourt": "Sân 2",
        "date": "15/01/2026",
        "time": "18:00 - 19:00",
        "price": "100.000 đ",
        "status": "completed",
        "image": "https://img.freepik.com/free-photo/shuttlecock-badminton-racket-indoor-court_23-2148204642.jpg",
      },
      {
        "id": "#BK0888",
        "courtName": "Sân Bóng Đá PM",
        "subCourt": "Sân 7",
        "date": "10/01/2026",
        "time": "16:00 - 17:30",
        "price": "200.000 đ",
        "status": "cancelled",
        "image": "https://img.freepik.com/free-photo/soccer-field-stadium_1150-12821.jpg",
      },
    ];

    final filteredList = dummyBookings.where((item) => item['status'] == status).toList();

    if (filteredList.isEmpty) {
      return Center(child: Text("Không có vé nào", style: TextStyle(color: Colors.grey[500])));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final item = filteredList[index];
        return _buildTicketCard(item, context);
      },
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> item, BuildContext context) {
    Color statusColor = item['status'] == 'upcoming' ? Colors.green : (item['status'] == 'completed' ? Colors.blue : Colors.red);
    String statusText = item['status'] == 'upcoming' ? "Đã thanh toán" : (item['status'] == 'completed' ? "Hoàn tất" : "Đã hủy");

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
                  child: Image.network(item['image'], width: 80, height: 80, fit: BoxFit.cover,
                    errorBuilder: (c,e,s) => Container(width: 80, height: 80, color: Colors.grey[300], child: const Icon(Icons.sports_tennis)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['courtName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text("${item['subCourt']} • ${item['date']}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(item['time'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(item['price'], style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}