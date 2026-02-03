import 'package:flutter/material.dart';
import '../../widgets/court_card.dart';
import '../booking/booking_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Dữ liệu giả lập các sân (Dummy Data)
  final List<Map<String, dynamic>> dummyCourts = [
    {
      "name": "PM PICKLEBALL",
      "address": "104 Tân Sơn, P.15, Q.Tân Bình",
      "distance": "497.4m",
      "openTime": "05:00 - 23:00",
      "imageUrl": "https://img.freepik.com/free-photo/pickleball-court-with-net_23-2151439498.jpg?w=1060", // Ảnh ví dụ
      "logoUrl": "https://cdn-icons-png.flaticon.com/512/33/33736.png", // Logo ví dụ
      "tags": ["Đơn ngày", "Sự kiện"],
      "isFavorite": false,
    },
    {
      "name": "SÂN BÓNG ĐÁ PM SPORT",
      "address": "104 Đ. Tân Sơn, P.15, Tân Bình",
      "distance": "498.3m",
      "openTime": "00:00 - 24:00",
      "imageUrl": "https://img.freepik.com/free-photo/soccer-field-stadium_1150-12821.jpg",
      "logoUrl": "https://cdn-icons-png.flaticon.com/512/867/867332.png",
      "tags": ["Đơn ngày"],
      "isFavorite": true,
    },
    {
      "name": "CLB Cầu Lông Chiến Thắng",
      "address": "45 Phạm Văn Đồng, Thủ Đức",
      "distance": "2.1km",
      "openTime": "06:00 - 22:00",
      "imageUrl": "https://img.freepik.com/free-photo/shuttlecock-badminton-racket-indoor-court_23-2148204642.jpg",
      "logoUrl": "https://cdn-icons-png.flaticon.com/512/103/103956.png",
      "tags": [],
      "isFavorite": false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Nền tổng thể xám nhạt
      appBar: AppBar(
        automaticallyImplyLeading: false, // Tắt nút back mặc định
        backgroundColor: Colors.transparent, // Trong suốt hoặc màu xanh tùy ý
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2962FF), Color(0xFF00B0FF)], // Gradient xanh thể thao
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            // Avatar nhỏ góc trái
            const CircleAvatar(
              backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=12"), // Ảnh đại diện giả
              radius: 18,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Xin chào,",
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                Text(
                  "Thanh Tín", // Tên user giả định
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Phần Header Tìm kiếm
          Container(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2962FF), Color(0xFF00B0FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sân...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: const Icon(Icons.qr_code_scanner, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Phần Danh sách Sân
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dummyCourts.length,
              itemBuilder: (context, index) {
                final court = dummyCourts[index];

                return CourtCard(
                  name: court["name"],
                  address: court["address"],
                  distance: court["distance"],
                  openTime: court["openTime"],
                  imageUrl: court["imageUrl"],
                  logoUrl: court["logoUrl"],
                  // Chuyển đổi an toàn từ dynamic sang List<String>
                  tags: List<String>.from(court["tags"]),
                  isFavorite: court["isFavorite"],
                  onTap: () {
                    print("Đã chọn sân: ${court['name']}");
                  },
                  onBookingTap: () {
                    // Điều hướng sang trang BookingGrid
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingScreen(courtName: court['name']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}