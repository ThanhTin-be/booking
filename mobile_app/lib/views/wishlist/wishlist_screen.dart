import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/wishlist_controller.dart';
import '../../widgets/court_card.dart';
import '../booking/booking_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final WishlistController controller = Get.put(WishlistController());

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Sân đã lưu", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.courts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.courts.isEmpty) return _buildEmptyState();

        return RefreshIndicator(
          onRefresh: () => controller.fetchWishlist(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.courts.length,
            itemBuilder: (context, index) {
              final court = controller.courts[index];
              final courtId = court['_id'] ?? '';

              return CourtCard(
                name: court['name'] ?? '',
                address: court['address'] ?? '',
                distance: '',
                openTime: "${court['openTime'] ?? '06:00'} - ${court['closeTime'] ?? '22:00'}",
                imageUrl: (court['images'] != null && court['images'].isNotEmpty)
                    ? court['images'][0]
                    : 'https://via.placeholder.com/400x200',
                logoUrl: court['logoUrl'] ?? '',
                tags: List<String>.from(court['tags'] ?? []),
                isFavorite: true,
                onTap: () {},
                onBookingTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingScreen(
                        courtId: courtId,
                        courtName: court['name'] ?? '',
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
            child: Icon(Icons.favorite_border_rounded, size: 80, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          const Text("Chưa có sân yêu thích", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Hãy thả tim các sân bạn quan tâm\nđể xem lại tại đây nhé!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}