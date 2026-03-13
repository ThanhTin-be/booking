import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/court_controller.dart';
import '../../controllers/wishlist_controller.dart';
import '../../widgets/court_card.dart';
import '../booking/booking_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final CourtController _courtController = Get.put(CourtController());
  final WishlistController _wishlistController = Get.put(WishlistController());
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2962FF), Color(0xFF00B0FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Obx(() {
          final user = _authController.user;
          return Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(_authController.avatarUrl),
                radius: 18,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Xin chào,", style: TextStyle(fontSize: 12, color: Colors.white70)),
                  Text(
                    user['fullName'] ?? "Khách",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ],
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
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
          // Search bar
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
              controller: _searchController,
              onSubmitted: (value) {
                _courtController.searchCourts(value);
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sân...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _courtController.searchResults.clear();
                  },
                ),
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

          // Court list
          Expanded(
            child: Obx(() {
              final displayCourts = _courtController.searchResults.isNotEmpty
                  ? _courtController.searchResults
                  : _courtController.courts;

              if (_courtController.isLoading.value && displayCourts.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (displayCourts.isEmpty) {
                return const Center(child: Text("Không tìm thấy sân nào"));
              }

              return RefreshIndicator(
                onRefresh: () => _courtController.fetchCourts(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayCourts.length,
                  itemBuilder: (context, index) {
                    final court = displayCourts[index];
                    final courtId = court['_id'] ?? '';

                    return Obx(() => CourtCard(
                      name: court['name'] ?? '',
                      address: court['address'] ?? '',
                      distance: '',
                      openTime: "${court['openTime'] ?? '06:00'} - ${court['closeTime'] ?? '22:00'}",
                      imageUrl: (court['images'] != null && court['images'].isNotEmpty)
                          ? court['images'][0]
                          : 'https://via.placeholder.com/400x200',
                      logoUrl: court['logoUrl'] ?? '',
                      tags: List<String>.from(court['tags'] ?? []),
                      isFavorite: _wishlistController.isFavorite(courtId),
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
                    ));
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}