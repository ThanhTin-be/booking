import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '../config/config.dart';

class ApiService {
  final _box = GetStorage();

  String get baseUrl => AppConfig.apiBaseUrl;
  String get _token => _box.read('token') ?? '';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_token',
  };

  // ============ GENERIC HTTP METHODS ============

  Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);
    return await http.get(uri, headers: _headers);
  }

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
    return await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> delete(String endpoint) async {
    return await http.delete(Uri.parse('$baseUrl$endpoint'), headers: _headers);
  }

  // ============ AUTH ============

  Future<http.Response> forgotPassword(String email) =>
      post('/auth/forgot-password', body: {'email': email});

  Future<http.Response> resetPassword(String email, String code, String newPassword) =>
      post('/auth/reset-password', body: {'email': email, 'code': code, 'newPassword': newPassword});

  // ============ USER PROFILE ============

  Future<http.Response> updateProfile({String? fullName, String? phone, String? email, String? address}) {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (phone != null) body['phone'] = phone;
    if (email != null) body['email'] = email;
    if (address != null) body['address'] = address;
    return put('/users/profile', body: body);
  }

  Future<http.Response> getWalletInfo() => get('/users/wallet');

  // ============ COURTS ============

  Future<http.Response> getCourts({String? category, int page = 1, int limit = 20}) {
    final params = <String, String>{'page': '$page', 'limit': '$limit'};
    if (category != null) params['category'] = category;
    return get('/courts', queryParams: params);
  }

  Future<http.Response> getCourtDetail(String courtId) => get('/courts/$courtId');

  Future<http.Response> searchCourts(String keyword) =>
      get('/courts/search', queryParams: {'keyword': keyword});

  Future<http.Response> getNearbyCourts(double lat, double lng, {int maxDistance = 5000}) =>
      get('/courts/nearby', queryParams: {
        'lat': '$lat', 'lng': '$lng', 'maxDistance': '$maxDistance',
      });

  Future<http.Response> getSubCourts(String courtId) => get('/courts/$courtId/sub-courts');

  Future<http.Response> getTimeSlots(String courtId, String date) =>
      get('/courts/$courtId/time-slots', queryParams: {'date': date});

  // ============ BOOKINGS ============

  Future<http.Response> createBooking({
    required String courtId,
    String? subCourtId,
    required String date,
    required List<String> timeSlotIds,
    String paymentMethod = 'cash',
    String? discountCode,
    String? contactName,
    String? contactPhone,
  }) {
    final body = <String, dynamic>{
      'courtId': courtId,
      'date': date,
      'timeSlotIds': timeSlotIds,
      'paymentMethod': paymentMethod,
    };
    if (subCourtId != null) body['subCourtId'] = subCourtId;
    if (discountCode != null && discountCode.isNotEmpty) body['discountCode'] = discountCode;
    if (contactName != null) body['contactName'] = contactName;
    if (contactPhone != null) body['contactPhone'] = contactPhone;
    return post('/bookings', body: body);
  }

  Future<http.Response> getMyBookings({String? status, int page = 1}) {
    final params = <String, String>{'page': '$page'};
    if (status != null) params['status'] = status;
    return get('/bookings', queryParams: params);
  }

  Future<http.Response> getBookingDetail(String bookingId) => get('/bookings/$bookingId');

  Future<http.Response> cancelBooking(String bookingId) => put('/bookings/$bookingId/cancel');

  // ============ PAYMENTS ============

  Future<http.Response> createPayment(String bookingId, String method) =>
      post('/payments', body: {'bookingId': bookingId, 'method': method});

  Future<http.Response> confirmPayment(String paymentId) => put('/payments/$paymentId/confirm');

  Future<http.Response> getQRCode(String paymentId) => get('/payments/$paymentId/qr-code');

  Future<http.Response> checkPaymentStatus(String paymentId) => get('/payments/$paymentId/status');

  // ============ WALLET ============

  Future<http.Response> getWalletBalance() => get('/wallet/balance');

  Future<http.Response> topUp(int amount) => post('/wallet/top-up', body: {'amount': amount});

  Future<http.Response> getTransactionHistory({String? type, int page = 1}) {
    final params = <String, String>{'page': '$page'};
    if (type != null) params['type'] = type;
    return get('/wallet/transactions', queryParams: params);
  }

  // ============ VNPAY ============

  Future<http.Response> createVnpayPaymentUrl(String bookingId) =>
      post('/vnpay/create-payment-url', body: {'bookingId': bookingId});

  Future<http.Response> createVnpayTopupUrl(int amount) =>
      post('/vnpay/create-topup-url', body: {'amount': amount});

  Future<http.Response> processVnpayReturn(Map<String, String> vnpParams) =>
      post('/vnpay/process-return', body: vnpParams);

  // ============ WISHLIST ============

  Future<http.Response> getWishlist() => get('/wishlist');

  Future<http.Response> addToWishlist(String courtId) => post('/wishlist/$courtId');

  Future<http.Response> removeFromWishlist(String courtId) => delete('/wishlist/$courtId');

  // ============ NOTIFICATIONS ============

  Future<http.Response> getNotifications({int page = 1}) =>
      get('/notifications', queryParams: {'page': '$page'});

  Future<http.Response> markNotificationRead(String notifId) => put('/notifications/$notifId/read');

  Future<http.Response> markAllNotificationsRead() => put('/notifications/read-all');

  // ============ DISCOUNTS ============

  Future<http.Response> getMyVouchers() => get('/discounts/my-vouchers');

  Future<http.Response> applyDiscount(String code, int orderTotal) =>
      post('/discounts/apply', body: {'code': code, 'orderTotal': orderTotal});

  // ============ PAYMENT METHODS ============

  Future<http.Response> getPaymentMethods() => get('/payment-methods');

  Future<http.Response> addPaymentMethod({
    required String type, required String name,
    String? accountNumber, String? bankName, bool isDefault = false,
  }) => post('/payment-methods', body: {
    'type': type, 'name': name,
    'accountNumber': accountNumber ?? '', 'bankName': bankName ?? '',
    'isDefault': isDefault,
  });

  Future<http.Response> deletePaymentMethod(String id) => delete('/payment-methods/$id');
}

