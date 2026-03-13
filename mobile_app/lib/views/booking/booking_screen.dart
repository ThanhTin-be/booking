import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  Map<String, dynamic> slotMap = {}; // key: "row_col" -> slot data

  // UI state
  final Set<String> selectedKeys = {};
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();

  // Sizing
  final double slotWidth = 60.0;
  final double slotMargin = 1.0;

  @override
  void initState() {
    super.initState();
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

      // Build unique time headers
      final timeSet = <String>{};
      for (var slot in allTimeSlots) {
        timeSet.add(slot['startTime']);
      }
      timeHeaders = timeSet.toList()..sort();

      // Build slotMap: "subCourtIndex_timeIndex" -> slot
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != selectedDate) {
      selectedDate = picked;
      _loadTimeSlots();
    }
  }

  void _toggleSlot(int r, int c) {
    String key = "${r}_$c";
    final slot = slotMap[key];
    if (slot == null) return;
    if (slot['status'] != 'available') return;

    setState(() {
      if (selectedKeys.contains(key)) {
        selectedKeys.remove(key);
      } else {
        selectedKeys.add(key);
      }
    });
  }

  // Helpers
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    double totalHours = totalSlots * 0.5;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        leading: const BackButton(color: Colors.white),
        title: Text(widget.courtName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(_displayDate, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  const SizedBox(width: 4),
                  const Icon(Icons.calendar_month, color: Colors.white, size: 16),
                ],
              ),
            ),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Legend
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLegendItem(Colors.white, "Trống", border: true),
                      _buildLegendItem(primaryColor, "Đang chọn"),
                      _buildLegendItem(Colors.redAccent, "Đã đặt"),
                      _buildLegendItem(Colors.grey, "Khóa"),
                    ],
                  ),
                ),

                // Grid
                Expanded(
                  child: subCourts.isEmpty
                      ? const Center(child: Text("Chưa có sân con nào"))
                      : Row(
                          children: [
                            // Sub-court names
                            SizedBox(
                              width: 70,
                              child: Column(
                                children: [
                                  const SizedBox(height: 40),
                                  Expanded(
                                    child: ListView.builder(
                                      physics: const ClampingScrollPhysics(),
                                      itemCount: subCourts.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          height: 50 + (slotMargin * 2),
                                          alignment: Alignment.center,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFE1F5FE),
                                            border: Border(bottom: BorderSide(color: Colors.white)),
                                          ),
                                          child: Text(
                                            subCourts[index]['name'] ?? 'Sân ${index + 1}',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
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
                                child: SizedBox(
                                  width: timeHeaders.length * (slotWidth + slotMargin * 2),
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: 40,
                                        child: Row(
                                          children: timeHeaders.map((time) => Container(
                                            width: slotWidth + slotMargin * 2,
                                            alignment: Alignment.center,
                                            child: Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                          )).toList(),
                                        ),
                                      ),
                                      Expanded(
                                        child: ListView.builder(
                                          physics: const ClampingScrollPhysics(),
                                          itemCount: subCourts.length,
                                          itemBuilder: (context, rowIndex) {
                                            return SizedBox(
                                              height: 50 + (slotMargin * 2),
                                              child: Row(
                                                children: List.generate(timeHeaders.length, (colIndex) {
                                                  String key = "${rowIndex}_$colIndex";
                                                  final slot = slotMap[key];
                                                  final status = slot?['status'] ?? 'available';
                                                  bool isBooked = status == 'booked';
                                                  bool isLocked = status == 'locked';
                                                  bool isSelected = selectedKeys.contains(key);

                                                  Color cellColor = Colors.white;
                                                  if (isLocked) cellColor = Colors.grey[400]!;
                                                  if (isBooked) cellColor = Colors.redAccent;
                                                  if (isSelected) cellColor = primaryColor;

                                                  return GestureDetector(
                                                    onTap: () => _toggleSlot(rowIndex, colIndex),
                                                    child: Container(
                                                      width: slotWidth,
                                                      margin: EdgeInsets.all(slotMargin),
                                                      decoration: BoxDecoration(
                                                        color: cellColor,
                                                        border: Border.all(color: Colors.grey[200]!),
                                                      ),
                                                      child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
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

                // Bottom bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -4))],
                  ),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text("Thời lượng: ${totalHours % 1 == 0 ? totalHours.toInt() : totalHours} giờ",
                                    style: const TextStyle(fontSize: 14, color: Colors.black87)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(totalPrice == 0 ? "0 đ" : formatCurrency(totalPrice),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2962FF))),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: totalSlots > 0
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CheckoutScreen(
                                        courtId: widget.courtId,
                                        courtName: widget.courtName,
                                        date: _dateString,
                                        displayDate: _displayDate,
                                        selectedTimeSlots: selectedTimeStrings,
                                        selectedSlotIds: selectedSlotIds,
                                        totalPrice: totalPrice,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("TIẾP THEO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLegendItem(Color color, String label, {bool border = false}) {
    return Row(
      children: [
        Container(
          width: 16, height: 16,
          decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(4),
            border: border ? Border.all(color: Colors.grey[300]!) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

