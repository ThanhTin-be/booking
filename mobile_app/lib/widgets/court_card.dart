import 'package:flutter/material.dart';

class CourtCard extends StatelessWidget {
  final String name;
  final String address;
  final String distance;
  final String openTime;
  final String imageUrl;
  final String logoUrl;
  final List<String> tags;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onBookingTap;

  const CourtCard({
    super.key,
    required this.name,
    required this.address,
    required this.distance,
    required this.openTime,
    required this.imageUrl,
    required this.logoUrl,
    this.tags = const [],
    this.isFavorite = false,
    required this.onTap,
    required this.onBookingTap,
  });

  @override
  Widget build(BuildContext context) {
    // Màu chủ đạo lấy từ Theme hoặc mặc định
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // --- PHẦN 1: ẢNH BÌA & CÁC NÚT TRÊN ẢNH ---
            Stack(
              children: [
                // Ảnh nền
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    // Xử lý khi lỗi ảnh thì hiện khung xám
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: Icon(Icons.broken_image, color: Colors.grey[600]),
                      );
                    },
                    // Hiển thị khung chờ khi đang tải ảnh
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                ),

                // Tags (Góc trái trên) - Ví dụ: Đơn ngày, Sự kiện
                Positioned(
                  top: 12,
                  left: 12,
                  child: Row(
                    children: tags.map((tag) {
                      // Màu tag khác nhau dựa vào nội dung (Ví dụ đơn giản)
                      Color tagColor = tag == "Đơn ngày" ? Colors.green : Colors.pinkAccent;
                      return Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: tagColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Nút Tim & Share (Góc phải trên)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      _buildCircleBtn(
                        icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.black54,
                        onTap: () {},
                      ),
                      const SizedBox(width: 8),
                      _buildCircleBtn(
                        icon: Icons.share_outlined,
                        color: Colors.black54,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // --- PHẦN 2: THÔNG TIN CHI TIẾT ---
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo sân (tròn)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                      image: DecorationImage(
                        image: NetworkImage(logoUrl),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {}, // Bỏ qua lỗi ảnh logo
                      ),
                    ),
                    // Fallback nếu logo lỗi
                    child: logoUrl.isEmpty
                        ? const Icon(Icons.sports_tennis)
                        : null,
                  ),

                  const SizedBox(width: 12),

                  // Cột thông tin chữ
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tên sân
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Địa chỉ + Khoảng cách
                        Row(
                          children: [
                            Text(
                              "($distance) ",
                              style: const TextStyle(
                                color: Colors.orange, // Màu cam cho khoảng cách
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                address,
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Giờ mở cửa
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              openTime,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),

                  // Nút ĐẶT LỊCH
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: onBookingTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300], // Nền xám như hình
                          foregroundColor: Colors.black54,   // Chữ đen nhạt
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        child: const Text(
                          "ĐẶT LỊCH",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget con hỗ trợ vẽ nút tròn nhỏ
  Widget _buildCircleBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}