import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../controllers/auth_controller.dart';
import '../views/booking/checkout_screen.dart';

/// Các bước trong luồng hội thoại chatbot
enum ChatStep {
  idle,
  selectArea,
  selectCourt,
  selectDate,
  selectTimeSlots,
  confirmPhone,
  confirmBooking,
  processing,
  done,
}

/// Loại tin nhắn trong chat
enum MessageType {
  bot,
  user,
  courtList,
  timeSlotGrid,
  bookingSummary,
  quickReply,
  typing,
}

/// Một tin nhắn trong chat
class ChatMessage {
  final MessageType type;
  final String? text;
  final dynamic data; // Dữ liệu bổ sung (danh sách sân, slots, ...)
  final DateTime timestamp;

  ChatMessage({
    required this.type,
    this.text,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatbotController extends GetxController {
  final ApiService _api = ApiService();

  // ============ STATE ============
  var currentStep = ChatStep.idle.obs;
  var messages = <ChatMessage>[].obs;
  var isTyping = false.obs;

  // ============ DỮ LIỆU ĐÃ CHỌN ============
  var searchKeyword = ''.obs;
  var foundCourts = <dynamic>[].obs;
  var selectedCourt = Rxn<Map<String, dynamic>>();
  var selectedDate = ''.obs;
  var timeSlots = <dynamic>[].obs;
  var subCourts = <dynamic>[].obs;
  var selectedSubCourt = Rxn<Map<String, dynamic>>();
  var selectedSlotIds = <String>[].obs;
  var contactPhone = ''.obs;
  var bookingResult = Rxn<Map<String, dynamic>>();

  // ============ LIFECYCLE ============
  @override
  void onInit() {
    super.onInit();
    _startConversation();
  }

  void resetConversation() {
    messages.clear();
    currentStep.value = ChatStep.idle;
    searchKeyword.value = '';
    foundCourts.clear();
    selectedCourt.value = null;
    selectedDate.value = '';
    timeSlots.clear();
    subCourts.clear();
    selectedSubCourt.value = null;
    selectedSlotIds.clear();
    contactPhone.value = '';
    bookingResult.value = null;
    _startConversation();
  }

  // ============ BẮT ĐẦU HỘI THOẠI ============
  void _startConversation() {
    _addBotMessage(
      'Xin chào! 🏸 Tôi là trợ lý đặt sân cầu lông.\n\n'
      'Bạn muốn tìm sân ở khu vực nào? Hãy nhập tên quận/khu vực nhé!',
    );
    currentStep.value = ChatStep.selectArea;
  }

  // ============ BƯỚC 1: TÌM SÂN THEO KHU VỰC ============
  Future<void> searchByArea(String keyword) async {
    if (keyword.trim().isEmpty) return;

    searchKeyword.value = keyword.trim();
    _addUserMessage(keyword.trim());
    await _showTyping();

    try {
      final response = await _api.searchCourts(keyword.trim());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final courts = data['courts'] as List? ?? [];

        if (courts.isEmpty) {
          _addBotMessage(
            'Rất tiếc, tôi không tìm thấy sân nào tại "$keyword" 😔\n\n'
            'Bạn có muốn tìm ở khu vực khác không?',
          );
          // Giữ nguyên step để user nhập lại
        } else {
          foundCourts.value = courts;
          _addBotMessage(
            '🏸 Tìm thấy ${courts.length} sân tại "$keyword":',
          );
          messages.add(ChatMessage(
            type: MessageType.courtList,
            data: courts,
          ));
          _addBotMessage('👉 Bạn muốn chọn sân nào?');
          currentStep.value = ChatStep.selectCourt;
        }
      } else {
        _addBotMessage('Có lỗi xảy ra khi tìm sân. Bạn thử lại nhé!');
      }
    } catch (e) {
      debugPrint('searchByArea error: $e');
      _addBotMessage('Không thể kết nối đến server. Bạn thử lại nhé! 🔄');
    }
  }

  // ============ BƯỚC 2: CHỌN SÂN ============
  void selectCourt(Map<String, dynamic> court) {
    selectedCourt.value = court;
    _addUserMessage('Chọn: ${court['name']}');

    _addBotMessage(
      '✅ Bạn đã chọn ${court['name']}\n'
      '📍 ${court['address'] ?? ''}\n\n'
      'Bạn muốn đặt sân ngày nào? Hãy chọn ngày bên dưới 👇',
    );
    currentStep.value = ChatStep.selectDate;
  }

  // ============ BƯỚC 2.5: CHỌN NGÀY ============
  Future<void> selectDate(String date) async {
    selectedDate.value = date;

    // Format date cho đẹp
    final parts = date.split('-');
    final displayDate = '${parts[2]}/${parts[1]}/${parts[0]}';
    _addUserMessage('📅 Ngày: $displayDate');
    await _showTyping();

    try {
      final courtId = selectedCourt.value?['_id'] ?? '';
      final response = await _api.getTimeSlots(courtId, date);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final slots = data['timeSlots'] as List? ?? [];
        final subs = data['subCourts'] as List? ?? [];
        timeSlots.value = slots;
        subCourts.value = subs;

        final availableSlots = slots.where((s) => s['status'] == 'available').toList();
        if (availableSlots.isEmpty) {
          _addBotMessage(
            'Rất tiếc, ngày $displayDate không còn khung giờ trống 😔\n\n'
            'Bạn có muốn chọn ngày khác không?',
          );
          currentStep.value = ChatStep.selectDate;
        } else {
          _addBotMessage(
            '⏰ Có ${availableSlots.length} khung giờ còn trống ngày $displayDate.\n'
            'Hãy chọn các khung giờ bạn muốn:',
          );
          messages.add(ChatMessage(
            type: MessageType.timeSlotGrid,
            data: {
              'slots': slots,
              'subCourts': subs,
            },
          ));
          currentStep.value = ChatStep.selectTimeSlots;
        }
      } else {
        _addBotMessage('Có lỗi khi lấy khung giờ. Bạn thử lại nhé!');
      }
    } catch (e) {
      debugPrint('selectDate error: $e');
      _addBotMessage('Lỗi kết nối. Bạn thử lại nhé! 🔄');
    }
  }

  // ============ BƯỚC 2.5: CHỌN SLOTS ============
  void confirmSelectedSlots(List<Map<String, dynamic>> slots, Map<String, dynamic>? subCourt) {
    if (slots.isEmpty) {
      _addBotMessage('Bạn chưa chọn khung giờ nào. Hãy chọn ít nhất 1 slot nhé!');
      return;
    }

    selectedSlotIds.value = slots.map((s) => s['_id'] as String).toList();
    selectedSubCourt.value = subCourt;

    // Sắp xếp theo thời gian
    slots.sort((a, b) => (a['startTime'] as String).compareTo(b['startTime'] as String));
    final startTime = slots.first['startTime'];
    final endTime = slots.last['endTime'];
    final totalPrice = slots.fold<int>(0, (sum, s) => sum + ((s['price'] as num?)?.toInt() ?? 0));
    final subCourtName = subCourt?['name'] ?? '';

    _addUserMessage(
      '⏰ $startTime – $endTime'
      '${subCourtName.isNotEmpty ? ' ($subCourtName)' : ''}\n'
      '💰 ${_formatCurrency(totalPrice)}',
    );

    // Bước 3: Xác nhận SĐT
    currentStep.value = ChatStep.confirmPhone;
    _checkPhoneNumber();
  }

  // ============ BƯỚC 3: XÁC NHẬN SĐT ============
  void _checkPhoneNumber() {
    try {
      final authController = Get.find<AuthController>();
      final userPhone = authController.user['phone'] ?? '';

      if (userPhone.toString().isNotEmpty) {
        contactPhone.value = userPhone.toString();
        _addBotMessage(
          '📱 Số điện thoại của bạn: $userPhone\n\n'
          'Xác nhận dùng số này?',
        );
        messages.add(ChatMessage(
          type: MessageType.quickReply,
          data: [
            {'label': '✅ Xác nhận', 'action': 'confirmPhone'},
            {'label': '✏️ Sửa', 'action': 'editPhone'},
          ],
        ));
      } else {
        _addBotMessage(
          '📱 Bạn chưa có số điện thoại. Hãy nhập số điện thoại liên hệ nhé!\n'
          '(10 số, bắt đầu bằng 0)',
        );
      }
    } catch (e) {
      _addBotMessage(
        '📱 Hãy nhập số điện thoại liên hệ nhé!\n'
        '(10 số, bắt đầu bằng 0)',
      );
    }
  }

  void confirmPhone() {
    _addUserMessage('📱 Xác nhận: ${contactPhone.value}');
    currentStep.value = ChatStep.confirmBooking;
    _showBookingSummary();
  }

  void editPhone() {
    _addBotMessage(
      'Hãy nhập số điện thoại mới:\n'
      '(10 số, bắt đầu bằng 0)',
    );
    contactPhone.value = '';
  }

  void submitPhone(String phone) {
    // Validate
    final cleaned = phone.replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(r'^0\d{9}$').hasMatch(cleaned)) {
      _addBotMessage(
        '❌ Số điện thoại không hợp lệ.\n'
        'Vui lòng nhập đúng 10 số, bắt đầu bằng 0.',
      );
      return;
    }

    contactPhone.value = cleaned;
    _addUserMessage('📱 SĐT: $cleaned');

    // Hỏi lưu SĐT
    _addBotMessage('Bạn có muốn lưu số điện thoại này để lần sau không cần nhập lại không?');
    messages.add(ChatMessage(
      type: MessageType.quickReply,
      data: [
        {'label': '✅ Có, lưu lại', 'action': 'savePhone'},
        {'label': '❌ Không', 'action': 'skipSavePhone'},
      ],
    ));
  }

  Future<void> savePhone() async {
    try {
      // Dùng AuthController.updateProfile để cập nhật + persist vào storage
      final authController = Get.find<AuthController>();
      await authController.updateProfile(phone: contactPhone.value);
      _addBotMessage('✅ Đã lưu số điện thoại! Lần sau bạn không cần nhập lại nữa.');
    } catch (e) {
      debugPrint('savePhone error: $e');
      _addBotMessage('⚠️ Không thể lưu SĐT, nhưng vẫn tiếp tục đặt sân nhé.');
    }
    currentStep.value = ChatStep.confirmBooking;
    _showBookingSummary();
  }

  void skipSavePhone() {
    currentStep.value = ChatStep.confirmBooking;
    _showBookingSummary();
  }

  // ============ BƯỚC 4: XÁC NHẬN BOOKING ============
  void _showBookingSummary() {
    final court = selectedCourt.value;
    final slots = timeSlots.where((s) => selectedSlotIds.contains(s['_id'])).toList();
    slots.sort((a, b) => (a['startTime'] as String).compareTo(b['startTime'] as String));

    final startTime = slots.isNotEmpty ? slots.first['startTime'] : '';
    final endTime = slots.isNotEmpty ? slots.last['endTime'] : '';
    final totalPrice = slots.fold<int>(0, (sum, s) => sum + ((s['price'] as num?)?.toInt() ?? 0));

    // Format date đẹp
    final dateParts = selectedDate.value.split('-');
    final displayDate = dateParts.length == 3
        ? '${dateParts[2]}/${dateParts[1]}/${dateParts[0]}'
        : selectedDate.value;

    final summary = {
      'courtName': court?['name'] ?? '',
      'subCourtName': selectedSubCourt.value?['name'] ?? '',
      'address': court?['address'] ?? '',
      'date': displayDate,
      'startTime': startTime,
      'endTime': endTime,
      'totalPrice': totalPrice,
      'phone': contactPhone.value,
    };

    _addBotMessage('📋 Xác nhận thông tin đặt sân:');
    messages.add(ChatMessage(
      type: MessageType.bookingSummary,
      data: summary,
    ));
    messages.add(ChatMessage(
      type: MessageType.quickReply,
      data: [
        {'label': '✅ Xác nhận đặt sân', 'action': 'confirmBooking'},
        {'label': '✏️ Sửa thông tin', 'action': 'editBooking'},
      ],
    ));
  }

  // ============ BƯỚC 5: TẠO BOOKING → CHUYỂN TRANG THANH TOÁN ============
  Future<void> createBooking() async {
    _addUserMessage('✅ Xác nhận đặt sân');
    currentStep.value = ChatStep.processing;
    await _showTyping();

    // Chuẩn bị dữ liệu cho CheckoutScreen TRƯỚC KHI tạo booking
    // Vì CheckoutScreen tự tạo booking (xem _submitBooking ở CheckoutScreen)
    // Nên chatbot chỉ cần thu thập đủ thông tin rồi chuyển trang
    _navigateToCheckout();
  }

  void _navigateToCheckout() {
    final court = selectedCourt.value;
    if (court == null) return;

    final courtId = court['_id']?.toString() ?? '';
    final courtName = court['name']?.toString() ?? '';

    // Lấy danh sách slots đã chọn
    final selectedSlots = timeSlots
        .where((s) => selectedSlotIds.contains(s['_id']))
        .toList();
    selectedSlots.sort((a, b) => (a['startTime'] as String).compareTo(b['startTime'] as String));

    // Nhóm theo sân con
    final Map<String, List<String>> subCourtSlots = {};
    final List<String> selectedTimeStrings = [];
    final List<String> slotIds = [];

    for (var slot in selectedSlots) {
      final scName = slot['subCourt'] is Map
          ? (slot['subCourt']['name'] ?? 'Sân chính')
          : (selectedSubCourt.value?['name'] ?? 'Sân chính');
      final timeStr = slot['startTime']?.toString() ?? '';
      subCourtSlots.putIfAbsent(scName, () => []);
      subCourtSlots[scName]!.add(timeStr);
      selectedTimeStrings.add(timeStr);
      slotIds.add(slot['_id']?.toString() ?? '');
    }
    // Sort time strings
    for (var list in subCourtSlots.values) {
      list.sort();
    }
    selectedTimeStrings.sort();

    final totalPrice = selectedSlots.fold<int>(
      0, (sum, s) => sum + ((s['price'] as num?)?.toInt() ?? 0),
    );

    // Format date
    final dateParts = selectedDate.value.split('-');
    final displayDate = dateParts.length == 3
        ? '${dateParts[2]}/${dateParts[1]}/${dateParts[0]}'
        : selectedDate.value;

    _addBotMessage('Đang chuyển sang trang thanh toán... 💳');
    currentStep.value = ChatStep.done;

    // Đóng chatbot rồi mở CheckoutScreen
    Future.delayed(const Duration(milliseconds: 800), () {
      Get.back(); // Đóng chatbot screen
      Future.delayed(const Duration(milliseconds: 200), () {
        Get.to(
          () => CheckoutScreen(
            courtId: courtId,
            courtName: courtName,
            subCourtSlots: subCourtSlots,
            date: selectedDate.value,
            displayDate: displayDate,
            selectedTimeSlots: selectedTimeStrings,
            selectedSlotIds: slotIds,
            totalPrice: totalPrice,
          ),
        );
      });
    });
  }

  void retryBooking() {
    _showBookingSummary();
  }

  void editBooking() {
    _addBotMessage(
      'Bạn muốn sửa gì?\n',
    );
    messages.add(ChatMessage(
      type: MessageType.quickReply,
      data: [
        {'label': '🏸 Đổi sân', 'action': 'changeCourt'},
        {'label': '📅 Đổi ngày/giờ', 'action': 'changeDate'},
        {'label': '📱 Đổi SĐT', 'action': 'changePhone'},
      ],
    ));
  }

  void changeCourt() {
    selectedCourt.value = null;
    selectedDate.value = '';
    selectedSlotIds.clear();
    _addBotMessage('Bạn muốn tìm sân ở khu vực nào?');
    currentStep.value = ChatStep.selectArea;
  }

  void changeDate() {
    selectedDate.value = '';
    selectedSlotIds.clear();
    _addBotMessage('Bạn muốn đặt sân ngày nào?');
    currentStep.value = ChatStep.selectDate;
  }

  void changePhone() {
    editPhone();
    currentStep.value = ChatStep.confirmPhone;
  }

  // ============ HELPERS ============
  void _addBotMessage(String text) {
    messages.add(ChatMessage(type: MessageType.bot, text: text));
  }

  void _addUserMessage(String text) {
    messages.add(ChatMessage(type: MessageType.user, text: text));
  }

  Future<void> _showTyping() async {
    isTyping.value = true;
    await Future.delayed(const Duration(milliseconds: 800));
    isTyping.value = false;
  }

  String _formatCurrency(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return '${buffer}đ';
  }

  /// Xử lý input từ user tùy step hiện tại
  void handleUserInput(String text) {
    switch (currentStep.value) {
      case ChatStep.selectArea:
        searchByArea(text);
        break;
      case ChatStep.confirmPhone:
        if (contactPhone.value.isEmpty) {
          submitPhone(text);
        }
        break;
      default:
        _addBotMessage('Xin lỗi, tôi chưa hiểu. Bạn thử lại nhé! 😊');
        break;
    }
  }

  /// Xử lý action từ quick reply buttons
  void handleAction(String action) {
    switch (action) {
      case 'confirmPhone':
        confirmPhone();
        break;
      case 'editPhone':
        editPhone();
        break;
      case 'savePhone':
        savePhone();
        break;
      case 'skipSavePhone':
        skipSavePhone();
        break;
      case 'confirmBooking':
        createBooking();
        break;
      case 'editBooking':
        editBooking();
        break;
      case 'retryBooking':
        retryBooking();
        break;
      case 'changeCourt':
        changeCourt();
        break;
      case 'changeDate':
        changeDate();
        break;
      case 'changePhone':
        changePhone();
        break;
      case 'goHome':
        Get.back();
        break;
    }
  }
}
