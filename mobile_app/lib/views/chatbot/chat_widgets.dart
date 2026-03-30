import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// =====================================================
/// BOT MESSAGE BUBBLE
/// =====================================================
class BotMessageBubble extends StatelessWidget {
  final String text;

  const BotMessageBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 60, top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF1E56D9), Color(0xFF42A5F5)],
              ),
            ),
            child: const Center(
              child: Text('🏸', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: const Color(0xFF2D3142),
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// =====================================================
/// USER MESSAGE BUBBLE
/// =====================================================
class UserMessageBubble extends StatelessWidget {
  final String text;

  const UserMessageBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 60, right: 12, top: 4, bottom: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E56D9), Color(0xFF3B7DED)],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E56D9).withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// =====================================================
/// COURT LIST MESSAGE — Danh sách sân bấm được
/// =====================================================
class CourtListMessage extends StatelessWidget {
  final List<dynamic> courts;
  final void Function(Map<String, dynamic>) onSelect;

  const CourtListMessage({
    super.key,
    required this.courts,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: List.generate(courts.length, (index) {
          final court = courts[index] as Map<String, dynamic>;
          final name = court['name'] ?? '';
          final address = court['address'] ?? '';
          final price = court['pricePerHour'] ?? court['pricePerSlot'] ?? 0;

          return GestureDetector(
            onTap: () => onSelect(court),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8ECF4), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E56D9), Color(0xFF42A5F5)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: const Color(0xFF2D3142),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                address,
                                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '💰 ${_formatCurrency(price)}/giờ',
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (court['ratingAvg'] != null && court['ratingAvg'] > 0)
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFA726)),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${court['ratingAvg']}',
                                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF1E56D9)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  String _formatCurrency(dynamic amount) {
    final val = (amount is int) ? amount : (amount as num).toInt();
    final str = val.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return '${buffer}đ';
  }
}

/// =====================================================
/// TIME SLOT GRID — Lưới chọn slot giờ
/// =====================================================
class TimeSlotGridMessage extends StatefulWidget {
  final List<dynamic> slots;
  final List<dynamic> subCourts;
  final void Function(List<Map<String, dynamic>> selected, Map<String, dynamic>? subCourt) onConfirm;

  const TimeSlotGridMessage({
    super.key,
    required this.slots,
    required this.subCourts,
    required this.onConfirm,
  });

  @override
  State<TimeSlotGridMessage> createState() => _TimeSlotGridMessageState();
}

class _TimeSlotGridMessageState extends State<TimeSlotGridMessage> {
  final Set<String> _selectedIds = {};
  String? _selectedSubCourtId;

  @override
  void initState() {
    super.initState();
    if (widget.subCourts.isNotEmpty) {
      _selectedSubCourtId = widget.subCourts.first['_id'];
    }
  }

  List<dynamic> get _filteredSlots {
    if (_selectedSubCourtId == null) return widget.slots;
    return widget.slots.where((s) {
      final sc = s['subCourt'];
      if (sc is Map) return sc['_id'] == _selectedSubCourtId;
      return s['subCourt'] == _selectedSubCourtId;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSlots;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sub-court tabs
            if (widget.subCourts.length > 1) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widget.subCourts.map((sc) {
                    final isActive = sc['_id'] == _selectedSubCourtId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSubCourtId = sc['_id'];
                            _selectedIds.clear();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: isActive
                                ? const LinearGradient(colors: [Color(0xFF1E56D9), Color(0xFF42A5F5)])
                                : null,
                            color: isActive ? null : const Color(0xFFF4F6FB),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            sc['name'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isActive ? Colors.white : Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Slot grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filtered.map((slot) {
                final id = slot['_id'] as String;
                final status = slot['status'] ?? 'available';
                final isAvailable = status == 'available';
                final isExpired = status == 'expired';
                final isSelected = _selectedIds.contains(id);
                final startTime = slot['startTime'] ?? '';

                return GestureDetector(
                  onTap: isAvailable
                      ? () {
                          setState(() {
                            if (isSelected) {
                              _selectedIds.remove(id);
                            } else {
                              _selectedIds.add(id);
                            }
                          });
                        }
                      : null,
                  child: Container(
                    width: 72,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(colors: [Color(0xFF1E56D9), Color(0xFF42A5F5)])
                          : null,
                      color: isSelected
                          ? null
                          : isAvailable
                              ? const Color(0xFFF0FFF4)
                              : isExpired
                                  ? const Color(0xFFF5F5F5)
                                  : const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1E56D9)
                            : isAvailable
                                ? const Color(0xFFA5D6A7)
                                : isExpired
                                    ? Colors.grey[300]!
                                    : const Color(0xFFEF9A9A),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        startTime,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : isAvailable
                                  ? const Color(0xFF2E7D32)
                                  : isExpired
                                      ? Colors.grey[400]
                                      : Colors.red[300],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            // Legend
            Row(
              children: [
                _legendDot(const Color(0xFFF0FFF4), 'Trống'),
                const SizedBox(width: 12),
                _legendDot(const Color(0xFFFFF0F0), 'Đã đặt'),
                const SizedBox(width: 12),
                _legendDot(const Color(0xFF1E56D9), 'Đã chọn'),
              ],
            ),

            const SizedBox(height: 14),

            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedIds.isEmpty
                    ? null
                    : () {
                        final selected = widget.slots
                            .where((s) => _selectedIds.contains(s['_id']))
                            .map((s) => Map<String, dynamic>.from(s as Map))
                            .toList();
                        final subCourt = widget.subCourts.firstWhere(
                          (sc) => sc['_id'] == _selectedSubCourtId,
                          orElse: () => null,
                        );
                        widget.onConfirm(
                          selected,
                          subCourt != null ? Map<String, dynamic>.from(subCourt as Map) : null,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E56D9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Text(
                  _selectedIds.isEmpty
                      ? 'Chọn khung giờ'
                      : 'Xác nhận ${_selectedIds.length} slot',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.grey[300]!, width: 0.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey[600])),
      ],
    );
  }
}

/// =====================================================
/// BOOKING SUMMARY CARD
/// =====================================================
class BookingSummaryCard extends StatelessWidget {
  final Map<String, dynamic> summary;

  const BookingSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8F9FE), Colors.white],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E56D9).withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E56D9).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('🏸', 'Sân', '${summary['courtName']}${summary['subCourtName'] != '' ? ' – ${summary['subCourtName']}' : ''}'),
            const SizedBox(height: 8),
            _row('📍', 'Địa chỉ', '${summary['address']}'),
            const SizedBox(height: 8),
            _row('📅', 'Ngày', '${summary['date']}'),
            const SizedBox(height: 8),
            _row('⏰', 'Giờ', '${summary['startTime']} – ${summary['endTime']}'),
            const SizedBox(height: 8),
            _row('💰', 'Giá', _formatCurrency(summary['totalPrice'] ?? 0)),
            const SizedBox(height: 8),
            _row('📱', 'SĐT', '${summary['phone']}'),
          ],
        ),
      ),
    );
  }

  Widget _row(String emoji, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 8),
        SizedBox(
          width: 55,
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3142),
            ),
          ),
        ),
      ],
    );
  }

  String _formatCurrency(dynamic amount) {
    final val = (amount is int) ? amount : (amount as num).toInt();
    final str = val.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return '${buffer}đ';
  }
}

/// =====================================================
/// QUICK REPLY BUTTONS
/// =====================================================
class QuickReplyButtons extends StatelessWidget {
  final List<dynamic> actions;
  final void Function(String action) onTap;

  const QuickReplyButtons({super.key, required this.actions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: actions.map((a) {
          final label = a['label'] ?? '';
          final action = a['action'] ?? '';
          return GestureDetector(
            onTap: () => onTap(action),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E56D9), Color(0xFF3B7DED)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E56D9).withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// =====================================================
/// TYPING INDICATOR
/// =====================================================
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 54, right: 60, top: 4, bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final delay = i * 0.2;
                final t = (_controller.value - delay).clamp(0.0, 1.0);
                final y = (t < 0.5 ? t * 2 : 2 - t * 2) * 4;
                return Transform.translate(
                  offset: Offset(0, -y),
                  child: Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E56D9).withOpacity(0.4 + t * 0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

/// =====================================================
/// DATE PICKER CARD
/// =====================================================
class DatePickerCard extends StatelessWidget {
  final void Function(String date) onDateSelected;

  const DatePickerCard({super.key, required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    // Show next 14 days
    final today = DateTime.now();
    final days = List.generate(14, (i) => today.add(Duration(days: i)));

    String _weekDay(int weekday) {
      switch (weekday) {
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📅 Chọn ngày:',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: days.map((day) {
                  final isToday = day.day == today.day && day.month == today.month;
                  final dateStr =
                      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                  final weekDay = _weekDay(day.weekday);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => onDateSelected(dateStr),
                      child: Container(
                        width: 56,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isToday
                              ? const LinearGradient(colors: [Color(0xFF1E56D9), Color(0xFF42A5F5)])
                              : null,
                          color: isToday ? null : const Color(0xFFF4F6FB),
                          borderRadius: BorderRadius.circular(12),
                          border: isToday ? null : Border.all(color: const Color(0xFFE8ECF4)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              weekDay,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isToday ? Colors.white70 : Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${day.day}',
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: isToday ? Colors.white : const Color(0xFF2D3142),
                              ),
                            ),
                            Text(
                              'Th${day.month}',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: isToday ? Colors.white70 : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
