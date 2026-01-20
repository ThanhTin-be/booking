import 'package:flutter/material.dart';
import '../../widgets/court_card.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  // Dữ liệu giả lập (Chỉ lấy những sân đã được tim)
  final List<Map<String, dynamic>> favoriteCourts = [
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
      "name": "Sân Tennis Lan Anh",
      "address": "291 Cách Mạng Tháng 8, Q.10",
      "distance": "1.5km",
      "openTime": "05:00 - 22:00",
      "imageUrl": "https://img.freepik.com/free-photo/tennis-racket-balls-red-court_23-2148204646.jpg",
      "logoUrl": "https://cdn-icons-png.flaticon.com/512/1165/1165187.png",
      "tags": ["VIP", "Mái che"],
      "isFavorite": true,
    },
  ];

  // Hàm xóa khỏi danh sách yêu thích
  void _removeFromFavorites(int index) {
    setState(() {
      final removedItem = favoriteCourts[index];
      favoriteCourts.removeAt(index);

      // Hiển thị thông báo hoàn tác (Undo)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đã bỏ thích '${removedItem['name']}'"),
          action: SnackBarAction(
            label: "Hoàn tác",
            onPressed: () {
              setState(() {
                favoriteCourts.insert(index, removedItem);
              });
            },
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Sân đã lưu",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Bỏ nút back vì nằm trong MainWrapper
      ),
      body: favoriteCourts.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: favoriteCourts.length,
        itemBuilder: (context, index) {
          final court = favoriteCourts[index];
          return CourtCard(
            name: court["name"],
            address: court["address"],
            distance: court["distance"],
            openTime: court["openTime"],
            imageUrl: court["imageUrl"],
            logoUrl: court["logoUrl"],
            tags: List<String>.from(court["tags"]),
            isFavorite: true, // Ở trang này luôn là true
            onTap: () {
              // Chuyển sang chi tiết
            },
            onBookingTap: () {
              // Xử lý đặt lịch
            },
            // Vì widget CourtCard hiện tại chưa có callback riêng cho nút tim
            // nên ta tạm thời chưa gắn hàm _removeFromFavorites vào nút tim trong Card được
            // (Trừ khi bạn sửa widget CourtCard thêm 1 callback onFavoriteTap).
            // Tuy nhiên, logic hiển thị vẫn đúng.
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite_border_rounded, size: 80, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          const Text(
            "Chưa có sân yêu thích",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Hãy thả tim các sân bạn quan tâm\nđể xem lại tại đây nhé!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}