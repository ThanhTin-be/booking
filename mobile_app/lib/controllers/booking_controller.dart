import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';

class BookingController extends GetxController {
  final ApiService _api = ApiService();

  var isLoading = false.obs;
  var upcomingBookings = <dynamic>[].obs;
  var completedBookings = <dynamic>[].obs;
  var cancelledBookings = <dynamic>[].obs;

  Future<void> fetchBookings(String status) async {
    try {
      isLoading.value = true;
      final response = await _api.getMyBookings(status: status);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['bookings'] ?? [];
        if (status == 'upcoming') upcomingBookings.value = list;
        else if (status == 'completed') completedBookings.value = list;
        else if (status == 'cancelled') cancelledBookings.value = list;
      }
    } catch (e) {
      debugPrint('fetchBookings error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> createBooking({
    required String courtId,
    String? subCourtId,
    required String date,
    required List<String> timeSlotIds,
    String paymentMethod = 'cash',
    String? discountCode,
    String? contactName,
    String? contactPhone,
  }) async {
    try {
      isLoading.value = true;
      final response = await _api.createBooking(
        courtId: courtId,
        subCourtId: subCourtId,
        date: date,
        timeSlotIds: timeSlotIds,
        paymentMethod: paymentMethod,
        discountCode: discountCode,
        contactName: contactName,
        contactPhone: contactPhone,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        Get.snackbar('Thành công', data['message'] ?? 'Đặt sân thành công!');
        return data;
      } else {
        Get.snackbar('Lỗi', data['message'] ?? 'Đặt sân thất bại');
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Lỗi kết nối');
    } finally {
      isLoading.value = false;
    }
    return null;
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      isLoading.value = true;
      final response = await _api.cancelBooking(bookingId);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        Get.snackbar('Thành công', data['message'] ?? 'Hủy booking thành công');
        // Refresh danh sách
        fetchBookings('upcoming');
        fetchBookings('cancelled');
      } else {
        Get.snackbar('Lỗi', data['message'] ?? 'Hủy thất bại');
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Lỗi kết nối');
    } finally {
      isLoading.value = false;
    }
  }

  // ============ PAYMENTS ============
  Future<Map<String, dynamic>?> createPayment(String bookingId, String method) async {
    try {
      final response = await _api.createPayment(bookingId, method);
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('createPayment error: $e');
    }
    return null;
  }

  Future<bool> confirmPayment(String paymentId) async {
    try {
      final response = await _api.confirmPayment(paymentId);
      if (response.statusCode == 200) return true;
    } catch (e) {
      debugPrint('confirmPayment error: $e');
    }
    return false;
  }

  Future<Map<String, dynamic>?> getQRCode(String paymentId) async {
    try {
      final response = await _api.getQRCode(paymentId);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('getQRCode error: $e');
    }
    return null;
  }

  // ============ DISCOUNT ============
  Future<Map<String, dynamic>?> applyDiscount(String code, int orderTotal) async {
    try {
      final response = await _api.applyDiscount(code, orderTotal);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data;
      } else {
        Get.snackbar('Lỗi', data['message'] ?? 'Mã giảm giá không hợp lệ');
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Lỗi kết nối');
    }
    return null;
  }
}

