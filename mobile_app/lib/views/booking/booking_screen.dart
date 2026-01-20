import 'package:flutter/material.dart';
import 'checkout_screen.dart';
class BookingScreen extends StatefulWidget {
  final String courtName;

  const BookingScreen({super.key, required this.courtName});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // Dữ liệu giả lập
  final List<String> timeSlots = [
    "15:30", "16:00", "16:30", "17:00", "17:30",
    "18:00", "18:30", "19:00", "19:30", "20:00", "20:30", "21:00"
  ];
  final List<String> subCourts = List.generate(10, (index) => "Sân ${index + 1}");

  // State quản lý chọn ô
  final Set<String> selectedSlots = {};
  final Set<String> bookedSlots = {"0_5", "0_6", "0_7", "1_5", "1_6", "2_0", "2_1"};
  final Set<String> lockedSlots = {"0_1", "0_2", "1_0", "1_1", "3_0", "3_1", "3_2"};

  // Giá tiền mỗi slot (30 phút)
  final int pricePerSlot = 50000;

  // Kích thước ô
  final double slotWidth = 60.0;
  final double slotMargin = 1.0;

  void _toggleSlot(int r, int c) {
    String key = "${r}_$c";
    if (bookedSlots.contains(key) || lockedSlots.contains(key)) return;

    setState(() {
      if (selectedSlots.contains(key)) {
        selectedSlots.remove(key);
      } else {
        selectedSlots.add(key);
      }
    });
  }

  // Hàm format tiền tệ thủ công
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

    // Tính toán tổng
    int totalSlots = selectedSlots.length;
    double totalHours = totalSlots * 0.5;
    int totalPrice = totalSlots * pricePerSlot;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          "Đặt lịch trực quan",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Text("20/01/2026", style: TextStyle(color: Colors.white, fontSize: 12)),
                SizedBox(width: 4),
                Icon(Icons.calendar_month, color: Colors.white, size: 16),
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // --- CHÚ THÍCH ---
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

          // --- GRID VIEW ---
          Expanded(
            child: Row(
              children: [
                // Cột trái: Tên sân
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
                              height: 50 + (slotMargin * 2), // Điều chỉnh chiều cao cho khớp với margin
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE1F5FE),
                                border: Border(bottom: BorderSide(color: Colors.white)),
                              ),
                              child: Text(
                                subCourts[index],
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Cột phải: Lưới giờ
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      // --- SỬA LỖI Ở ĐÂY: Tính thêm cả margin ---
                      width: timeSlots.length * (slotWidth + slotMargin * 2),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 40,
                            child: Row(
                              children: timeSlots.map((time) => Container(
                                // Tính thêm margin cho header giờ để căn thẳng hàng
                                width: slotWidth + slotMargin * 2,
                                alignment: Alignment.center,
                                child: Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                              )).toList(),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              physics: const ClampingScrollPhysics(),
                              itemCount: subCourts.length,
                              itemBuilder: (context, rowIndex) {
                                return SizedBox(
                                  // Điều chỉnh chiều cao cho khớp với margin
                                  height: 50 + (slotMargin * 2),
                                  child: Row(
                                    children: List.generate(timeSlots.length, (colIndex) {
                                      String key = "${rowIndex}_$colIndex";
                                      bool isBooked = bookedSlots.contains(key);
                                      bool isLocked = lockedSlots.contains(key);
                                      bool isSelected = selectedSlots.contains(key);

                                      Color cellColor = Colors.white;
                                      if (isLocked) cellColor = Colors.grey[400]!;
                                      if (isBooked) cellColor = Colors.redAccent;
                                      if (isSelected) cellColor = primaryColor;

                                      return GestureDetector(
                                        onTap: () => _toggleSlot(rowIndex, colIndex),
                                        child: Container(
                                          width: slotWidth,
                                          margin: EdgeInsets.all(slotMargin), // Sử dụng biến margin
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

          // --- BOTTOM BAR ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
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
                          Text(
                            "Thời lượng: ${totalHours % 1 == 0 ? totalHours.toInt() : totalHours} giờ",
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        totalPrice == 0 ? "0 đ" : formatCurrency(totalPrice),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2962FF),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: totalSlots > 0 ? () {
                      // Logic tạo danh sách các khung giờ đã chọn để gửi sang trang sau
                      // Ví dụ chuyển đổi rowIndex, colIndex thành giờ thực tế
                      // Ở đây tôi giả lập danh sách giờ dựa trên selectedSlots để demo
                      List<String> selectedTimeStrings = [];

                      // Logic chuyển đổi đơn giản (Bạn có thể tinh chỉnh sau)
                      for(var slot in selectedSlots) {
                        // slot có dạng "rowIndex_colIndex" (vd: "0_1")
                        // Lấy colIndex để tra ngược lại list timeSlots
                        int colIndex = int.parse(slot.split('_')[1]);
                        selectedTimeStrings.add(timeSlots[colIndex]);
                      }
                      selectedTimeStrings.sort(); // Sắp xếp lại giờ cho đẹp

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutScreen(
                            courtName: widget.courtName,
                            date: "20/01/2026", // Ngày đang chọn
                            selectedTimeSlots: selectedTimeStrings,
                            totalPrice: totalPrice,
                          ),
                        ),
                      );
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      "TIẾP THEO",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildLegendItem(Color color, String label, {bool border = false}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: border ? Border.all(color: Colors.grey[300]!) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}