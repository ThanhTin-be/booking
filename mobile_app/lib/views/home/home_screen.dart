import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: const Color(0xFFF8F9FE),
      body: CustomScrollView(
        slivers: [
          // --- SLIVER APP BAR ---
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF1E56D9),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E56D9), Color(0xFF00C2FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top bar: avatar + name + notification
                        Row(
                          children: [
                            Obx(() {
                              final user = _authController.user;
                              return Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(_authController.avatarUrl),
                                    radius: 20,
                                    backgroundColor: Colors.white.withOpacity(0.2),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Xin chào 👋",
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      Text(
                                        user['fullName'] ?? "Khách",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }),
                            const Spacer(),
                            _HeaderIconBtn(
                              icon: Icons.notifications_outlined,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _HeaderIconBtn(
                              icon: Icons.favorite_border_rounded,
                              onTap: () {},
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Search bar
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onSubmitted: (value) => _courtController.searchCourts(value),
                            style: GoogleFonts.poppins(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm sân cầu lông...',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.clear_rounded, color: Colors.grey[400]),
                                onPressed: () {
                                  _searchController.clear();
                                  _courtController.searchResults.clear();
                                },
                              ),
                              filled: false,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- COURT LIST ---
          SliverToBoxAdapter(
            child: Obx(() {
              final displayCourts = _courtController.searchResults.isNotEmpty
                  ? _courtController.searchResults
                  : _courtController.courts;

              if (_courtController.isLoading.value && displayCourts.isEmpty) {
                return const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (displayCourts.isEmpty) {
                return SizedBox(
                  height: 300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sports_tennis_rounded, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          "Không tìm thấy sân nào",
                          style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Sân gần bạn",
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          "${displayCourts.length} sân",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF1E56D9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RefreshIndicator(
                    onRefresh: () => _courtController.fetchCourts(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayCourts.length,
                      itemBuilder: (context, index) {
                        final court = displayCourts[index];
                        final courtId = court['_id'] ?? '';

                        return Obx(() => CourtCard(
                          name: court['name'] ?? '',
                          address: court['address'] ?? '',
                          distance: '',
                          openTime:
                              "${court['openTime'] ?? '06:00'} - ${court['closeTime'] ?? '22:00'}",
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
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}