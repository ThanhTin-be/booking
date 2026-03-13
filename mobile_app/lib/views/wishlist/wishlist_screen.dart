import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/wishlist_controller.dart';
import '../../widgets/court_card.dart';
import '../booking/booking_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final WishlistController controller = Get.put(WishlistController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E56D9), Color(0xFF00C2FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Sân yêu thích ❤️",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(() => Text(
                    "${controller.courts.length} sân đã lưu",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.courts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.courts.isEmpty) return _buildEmptyState();

        return RefreshIndicator(
          onRefresh: () => controller.fetchWishlist(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.redAccent.withOpacity(0.08),
                  Colors.pinkAccent.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite_border_rounded, size: 72, color: Colors.redAccent.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            "Chưa có sân yêu thích",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Hãy thả tim các sân bạn quan tâm\nđể xem lại tại đây nhé!",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }
}