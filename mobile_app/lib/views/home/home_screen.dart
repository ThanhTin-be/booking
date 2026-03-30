import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/config.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/court_controller.dart';
import '../../controllers/wishlist_controller.dart';
import '../../widgets/court_card.dart';
import '../booking/booking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();
  final CourtController _courtController = Get.put(CourtController());
  final WishlistController _wishlistController = Get.put(WishlistController());
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _hasSearchText = false;

  int _selectedFilter = 0;
  final List<Map<String, dynamic>> _filters = [
    {'label': 'Tất cả', 'icon': Icons.grid_view_rounded},
    {'label': 'Gần bạn', 'icon': Icons.near_me_rounded},
    {'label': 'Ưu đãi', 'icon': Icons.local_offer_rounded},
    {'label': 'Yêu thích', 'icon': Icons.favorite_rounded},
    {'label': 'Mới nhất', 'icon': Icons.new_releases_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final hasText = _searchController.text.trim().isNotEmpty;
      if (hasText != _hasSearchText) {
        setState(() => _hasSearchText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- SLIVER APP BAR ---
          SliverAppBar(
            expandedHeight: 210,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF1E56D9),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF1E88E5), Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -40,
                      right: -30,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 30,
                      left: -50,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.04),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 60,
                      right: 60,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    // Main content
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top bar: avatar + greeting
                            Obx(() {
                              final user = _authController.user;
                              return Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                                    ),
                                    child: CircleAvatar(
                                      backgroundImage: NetworkImage(_authController.avatarUrl),
                                      radius: 22,
                                      backgroundColor: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Xin chào 👋",
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                      Text(
                                        user['fullName'] ?? "Khách",
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  // Location pin badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.location_on_rounded, color: Colors.amber[300], size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          "TP.HCM",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }),

                            const SizedBox(height: 20),

                            // Search bar
                            Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) {
                                  _debounce?.cancel();
                                  if (value.trim().isEmpty) {
                                    _courtController.isSearching.value = false;
                                    _courtController.searchResults.clear();
                                    return;
                                  }
                                  _debounce = Timer(const Duration(milliseconds: 500), () {
                                    _courtController.searchCourts(value.trim());
                                  });
                                },
                                style: GoogleFonts.poppins(fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Tìm sân cầu lông gần bạn...',
                                  hintStyle: GoogleFonts.poppins(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Container(
                                    padding: const EdgeInsets.all(12),
                                    child: Icon(Icons.search_rounded, color: Colors.grey[500], size: 24),
                                  ),
                                  suffixIcon: _hasSearchText
                                      ? IconButton(
                                          icon: Icon(Icons.close_rounded, color: Colors.grey[500], size: 22),
                                          onPressed: () {
                                            _searchController.clear();
                                            _courtController.isSearching.value = false;
                                            _courtController.searchResults.clear();
                                          },
                                        )
                                      : IconButton(
                                          icon: Icon(Icons.tune_rounded, color: Colors.grey[400], size: 22),
                                          onPressed: () {},
                                        ),
                                  filled: false,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- FILTER CHIPS ---
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
              child: SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedFilter == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFF1E56D9), Color(0xFF42A5F5)],
                                )
                              : null,
                          color: isSelected ? null : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: isSelected
                              ? null
                              : Border.all(color: Colors.grey[200]!),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF1E56D9).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _filters[index]['icon'],
                              size: 16,
                              color: isSelected ? Colors.white : Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _filters[index]['label'],
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? Colors.white : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // --- SECTION HEADER ---
          SliverToBoxAdapter(
            child: Obx(() {
              final rawCourts = _courtController.isSearching.value
                  ? _courtController.searchResults
                  : _courtController.courts;
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E56D9), Color(0xFF42A5F5)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Sân gần bạn",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1F36),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E56D9).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${rawCourts.length} sân",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF1E56D9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          // --- COURT LIST ---
          SliverToBoxAdapter(
            child: Obx(() {
              final rawCourts = _courtController.isSearching.value
                  ? _courtController.searchResults
                  : _courtController.courts;

              // Sắp xếp: sân yêu thích lên đầu
              final displayCourts = List.from(rawCourts);
              displayCourts.sort((a, b) {
                final aFav = _wishlistController.isFavorite(a['_id'] ?? '');
                final bFav = _wishlistController.isFavorite(b['_id'] ?? '');
                if (aFav && !bFav) return -1;
                if (!aFav && bFav) return 1;
                return 0;
              });

              if (_courtController.isLoading.value && displayCourts.isEmpty) {
                // Shimmer loading placeholders
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    children: List.generate(3, (i) => _buildShimmerCard()),
                  ),
                );
              }

              if (displayCourts.isEmpty) {
                return SizedBox(
                  height: 300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E56D9).withOpacity(0.06),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.sports_tennis_rounded, size: 56, color: Colors.grey[350]),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Không tìm thấy sân nào",
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Thử tìm kiếm với từ khóa khác nhé!",
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => _courtController.fetchCourts(),
                color: const Color(0xFF1E56D9),
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
                          ? AppConfig.toFullImageUrl(court['images'][0])
                          : '',
                      logoUrl: AppConfig.toFullImageUrl(court['logoUrl']),
                      tags: List<String>.from(court['tags'] ?? []),
                      isFavorite: _wishlistController.isFavorite(courtId),
                      onFavoriteTap: () => _wishlistController.toggleFavorite(courtId),
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

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image placeholder
          Container(
            height: 170,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(
                colors: [Colors.grey[200]!, Colors.grey[100]!, Colors.grey[200]!],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Info placeholder
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Logo placeholder
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: 150, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 8),
                      Container(height: 10, width: 200, decoration: BoxDecoration(color: Colors.grey[150], borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 6),
                      Container(height: 10, width: 100, decoration: BoxDecoration(color: Colors.grey[150], borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}