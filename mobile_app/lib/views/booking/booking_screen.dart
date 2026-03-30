import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/court_controller.dart';
import 'checkout_screen.dart';

class BookingScreen extends StatefulWidget {
  final String courtId;
  final String courtName;

  const BookingScreen({super.key, required this.courtId, required this.courtName});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final CourtController _courtController = Get.find<CourtController>();

  // API data
  List<dynamic> subCourts = [];
  List<dynamic> allTimeSlots = [];
  List<String> timeHeaders = [];
  Map<String, dynamic> slotMap = {};

  // UI state
  final Set<String> selectedKeys = {};
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();

  // Date strip
  late List<DateTime> _dateStrip;

  // Sizing
  final double slotWidth = 64.0;
  final double slotHeight = 52.0;
  final double slotMargin = 1.5;

  @override
  void initState() {
    super.initState();
    _dateStrip = List.generate(14, (i) => DateTime.now().add(Duration(days: i)));
    _loadTimeSlots();
  }

  String get _dateString =>
      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

  String get _displayDate =>
      "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}";

  Future<void> _loadTimeSlots() async {
    setState(() => isLoading = true);
    final data = await _courtController.getTimeSlots(widget.courtId, _dateString);
    if (data != null) {
      subCourts = data['subCourts'] ?? [];
      allTimeSlots = data['timeSlots'] ?? [];

      final timeSet = <String>{};
      for (var slot in allTimeSlots) {
        timeSet.add(slot['startTime']);
      }
      timeHeaders = timeSet.toList()..sort();

      slotMap.clear();
      for (var slot in allTimeSlots) {
        final scId = slot['subCourt'] is Map ? slot['subCourt']['_id'] : slot['subCourt'];
        final scIndex = subCourts.indexWhere((sc) => sc['_id'] == scId);
        final tIndex = timeHeaders.indexOf(slot['startTime']);
        if (scIndex != -1 && tIndex != -1) {
          slotMap["${scIndex}_$tIndex"] = slot;
        }
      }
    }
    setState(() {
      isLoading = false;
      selectedKeys.clear();
    });
  }

  void _selectDate(DateTime date) {
    setState(() => selectedDate = date);
    _loadTimeSlots();
  }

  void _toggleSlot(int r, int c) {
    String key = "${r}_$c";
    final slot = slotMap[key];
    if (slot == null) return;
    final status = slot['status'];
    if (status != 'available') return;

    // Bắt login khi chọn slot
    if (!AuthController.requireLogin(context, message: 'Đăng nhập để chọn khung giờ và đặt sân')) {
      return;
    }

    setState(() {
      if (selectedKeys.contains(key)) {
        selectedKeys.remove(key);
      } else {
        selectedKeys.add(key);
      }
    });
  }

  int get totalSlots => selectedKeys.length;
  int get totalPrice {
    int sum = 0;
    for (var key in selectedKeys) {
      final slot = slotMap[key];
      if (slot != null) sum += ((slot['price'] ?? 50000) as num).toInt();
    }
    return sum;
  }

  List<String> get selectedSlotIds {
    return selectedKeys.map((key) {
      final slot = slotMap[key];
      return slot?['_id']?.toString() ?? '';
    }).where((id) => id.isNotEmpty).toList();
  }

  List<String> get selectedTimeStrings {
    return selectedKeys.map((key) {
      final slot = slotMap[key];
      return slot?['startTime']?.toString() ?? '';
    }).where((t) => t.isNotEmpty).toList()..sort();
  }

  String formatCurrency(int amount) {
    String price = amount.toString();
    String result = "";
    int count = 0;
    for (int i = price.length - 1; i >= 0; i--) {
      count++;
      result = price[i] + result;
      if (count == 3 && i > 0) {
        result = ".$result";
        count = 0;
      }
    }
    return "$result đ";
  }

  String _weekday(int wd) {
    switch (wd) {
      case 1: return 'T2';
      case 2: return 'T3';
      case 3: return 'T4';
      case 4: return 'T5';
      case 5: return 'T6';
      case 6: return 'T7';
      case 7: return 'CN';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalHours = totalSlots * 0.5;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          // --- CUSTOM APP BAR ---
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1E88E5), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Title bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.courtName,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "Chọn khung giờ để đặt sân",
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // --- HORIZONTAL DATE PICKER ---
                  SizedBox(
                    height: 72,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _dateStrip.length,
                      itemBuilder: (context, index) {
                        final date = _dateStrip[index];
                        final isSelected = date.year == selectedDate.year &&
                            date.month == selectedDate.month &&
                            date.day == selectedDate.day;
                        final isToday = date.year == DateTime.now().year &&
                            date.month == DateTime.now().month &&
                            date.day == DateTime.now().day;

                        return GestureDetector(
                          onTap: () => _selectDate(date),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            width: 52,
                            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [Colors.white, Color(0xFFE3F2FD)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    )
                                  : null,
                              color: isSelected ? null : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: isToday && !isSelected
                                  ? Border.all(color: Colors.white.withOpacity(0.5), width: 1.5)
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _weekday(date.weekday),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected ? const Color(0xFF1E56D9) : Colors.white.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${date.day}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? const Color(0xFF0D47A1) : Colors.white,
                                  ),
                                ),
                                if (isToday)
                                  Container(
                                    width: 5, height: 5,
                                    margin: const EdgeInsets.only(top: 2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? const Color(0xFF1E56D9) : Colors.amber[300],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // --- LEGEND ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem(Colors.white, "Trống", border: true),
                _buildLegendItem(const Color(0xFF1E56D9), "Đang chọn"),
                _buildLegendItem(const Color(0xFFEF5350), "Đã đặt"),
                _buildLegendItem(const Color(0xFFFF9800), "Đang giữ"),
                _buildLegendItem(const Color(0xFFBDBDBD), "Quá giờ"),
              ],
            ),
          ),

          // --- TIME SLOT GRID ---
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E56D9)))
                : subCourts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy_rounded, size: 56, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              "Chưa có sân con nào",
                              style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          // Sub-court names column
                          Container(
                            width: 74,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(right: BorderSide(color: Colors.grey[200]!)),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F7FB),
                                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                                  ),
                                  child: Text(
                                    "Sân",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    physics: const ClampingScrollPhysics(),
                                    itemCount: subCourts.length,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        height: slotHeight + (slotMargin * 2),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: index % 2 == 0
                                              ? const Color(0xFFF0F5FF)
                                              : const Color(0xFFF8FAFF),
                                          border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
                                        ),
                                        child: Text(
                                          subCourts[index]['name'] ?? 'Sân ${index + 1}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1E56D9),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Time grid
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: SizedBox(
                                width: timeHeaders.length * (slotWidth + slotMargin * 2),
                                child: Column(
                                  children: [
                                    // Time headers
                                    SizedBox(
                                      height: 40,
                                      child: Row(
                                        children: timeHeaders.map((time) => Container(
                                          width: slotWidth + slotMargin * 2,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF5F7FB),
                                            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                                          ),
                                          child: Text(
                                            time,
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        )).toList(),
                                      ),
                                    ),
                                    // Slot grid
                                    Expanded(
                                      child: ListView.builder(
                                        physics: const ClampingScrollPhysics(),
                                        itemCount: subCourts.length,
                                        itemBuilder: (context, rowIndex) {
                                          return SizedBox(
                                            height: slotHeight + (slotMargin * 2),
                                            child: Row(
                                              children: List.generate(timeHeaders.length, (colIndex) {
                                                String key = "${rowIndex}_$colIndex";
                                                final slot = slotMap[key];
                                                final status = slot?['status'] ?? 'available';
                                                bool isBooked = status == 'booked';
                                                bool isLocked = status == 'locked';
                                                bool isExpired = status == 'expired';
                                                bool isUnavailable = isBooked || isLocked || isExpired;
                                                bool isSelected = selectedKeys.contains(key);
                                                final price = ((slot?['price'] ?? 50000) as num).toInt();

                                                Color cellColor = Colors.white;
                                                Color textColor = Colors.grey[700]!;
                                                if (isExpired) {
                                                  cellColor = const Color(0xFFF5F5F5);
                                                  textColor = const Color(0xFFBDBDBD);
                                                }
                                                if (isLocked) {
                                                  cellColor = const Color(0xFFFFF3E0);
                                                  textColor = const Color(0xFFFF9800);
                                                }
                                                if (isBooked) {
                                                  cellColor = const Color(0xFFFFEBEE);
                                                  textColor = const Color(0xFFEF5350);
                                                }
                                                if (isSelected) {
                                                  cellColor = const Color(0xFF1E56D9);
                                                  textColor = Colors.white;
                                                }

                                                return GestureDetector(
                                                  onTap: isUnavailable ? null : () => _toggleSlot(rowIndex, colIndex),
                                                  child: AnimatedContainer(
                                                    duration: const Duration(milliseconds: 200),
                                                    width: slotWidth,
                                                    margin: EdgeInsets.all(slotMargin),
                                                    decoration: BoxDecoration(
                                                      color: cellColor,
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(
                                                        color: isSelected
                                                            ? const Color(0xFF1E56D9)
                                                            : isBooked
                                                                ? const Color(0xFFEF5350).withOpacity(0.3)
                                                                : isExpired
                                                                    ? Colors.grey[300]!
                                                                    : Colors.grey[200]!,
                                                        width: isSelected ? 2 : 1,
                                                      ),
                                                      boxShadow: isSelected
                                                          ? [
                                                              BoxShadow(
                                                                color: const Color(0xFF1E56D9).withOpacity(0.3),
                                                                blurRadius: 6,
                                                                offset: const Offset(0, 2),
                                                              ),
                                                            ]
                                                          : null,
                                                    ),
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        if (isSelected)
                                                          const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                                                        else if (isBooked)
                                                          Icon(Icons.close_rounded, size: 14, color: textColor)
                                                        else if (isLocked)
                                                          Icon(Icons.hourglass_top_rounded, size: 14, color: textColor)
                                                        else if (isExpired)
                                                          Icon(Icons.schedule_rounded, size: 14, color: textColor)
                                                        else
                                                          Text(
                                                            _formatPrice(price),
                                                            style: GoogleFonts.poppins(
                                                              fontSize: 9,
                                                              fontWeight: FontWeight.w600,
                                                              color: textColor,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
          ),

          // --- BOTTOM SUMMARY BAR ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (totalSlots > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E56D9).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "$totalSlots slot",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E56D9),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              "${totalHours % 1 == 0 ? totalHours.toInt() : totalHours} giờ",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalPrice == 0 ? "0 đ" : formatCurrency(totalPrice),
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0D47A1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: totalSlots > 0
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  // Nhóm các slot đã chọn theo sân con
                                  final Map<String, List<String>> subCourtSlots = {};
                                  for (var key in selectedKeys) {
                                    final parts = key.split('_');
                                    final scIdx = int.tryParse(parts.first) ?? -1;
                                    final tIdx = int.tryParse(parts.last) ?? -1;
                                    if (scIdx >= 0 && scIdx < subCourts.length && tIdx >= 0 && tIdx < timeHeaders.length) {
                                      final scName = subCourts[scIdx]['name']?.toString() ?? 'Sân $scIdx';
                                      final slot = slotMap[key];
                                      final timeStr = slot?['startTime']?.toString() ?? timeHeaders[tIdx];
                                      subCourtSlots.putIfAbsent(scName, () => []);
                                      subCourtSlots[scName]!.add(timeStr);
                                    }
                                  }
                                  // Sắp xếp time slots trong mỗi sân con
                                  for (var list in subCourtSlots.values) {
                                    list.sort();
                                  }
                                  return CheckoutScreen(
                                    courtId: widget.courtId,
                                    courtName: widget.courtName,
                                    subCourtSlots: subCourtSlots,
                                    date: _dateString,
                                    displayDate: _displayDate,
                                    selectedTimeSlots: selectedTimeStrings,
                                    selectedSlotIds: selectedSlotIds,
                                    totalPrice: totalPrice,
                                  );
                                },
                              ),
                            ).then((_) => _loadTimeSlots()); // Reload slots khi quay lại
                          }
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: totalSlots > 0
                            ? const LinearGradient(
                                colors: [Color(0xFFF57C00), Color(0xFFFFB300)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: totalSlots > 0 ? null : Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: totalSlots > 0
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFF57C00).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "TIẾP THEO",
                            style: GoogleFonts.poppins(
                              color: totalSlots > 0 ? Colors.white : Colors.grey[500],
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: totalSlots > 0 ? Colors.white : Colors.grey[500],
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}tr';
    if (amount >= 1000) return '${(amount / 1000).toInt()}k';
    return '$amount';
  }

  Widget _buildLegendItem(Color color, String label, {bool border = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14, height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: border ? Border.all(color: Colors.grey[300]!) : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[700]),
        ),
      ],
    );
  }
}
