import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';

class PaymentMethodController extends GetxController {
  final ApiService _api = ApiService();

  var isLoading = false.obs;
  var methods = <dynamic>[].obs;
  var vouchers = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchPaymentMethods();
    fetchVouchers();
  }

  Future<void> fetchPaymentMethods() async {
    try {
      isLoading.value = true;
      final response = await _api.getPaymentMethods();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        methods.value = data['paymentMethods'] ?? [];
      }
    } catch (e) {
      debugPrint('fetchPaymentMethods error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addPaymentMethod({
    required String type, required String name,
    String? accountNumber, String? bankName, bool isDefault = false,
  }) async {
    try {
      isLoading.value = true;
      final response = await _api.addPaymentMethod(
        type: type, name: name,
        accountNumber: accountNumber, bankName: bankName, isDefault: isDefault,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        Get.snackbar('Thành công', 'Thêm phương thức thanh toán thành công');
        fetchPaymentMethods();
      } else {
        Get.snackbar('Lỗi', data['message'] ?? 'Thêm thất bại');
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Lỗi kết nối');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deletePaymentMethod(String id) async {
    try {
      final response = await _api.deletePaymentMethod(id);
      if (response.statusCode == 200) {
        methods.removeWhere((m) => m['_id'] == id);
        Get.snackbar('Thành công', 'Đã xóa phương thức thanh toán');
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Lỗi kết nối');
    }
  }

  Future<void> fetchVouchers() async {
    try {
      final response = await _api.getMyVouchers();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        vouchers.value = data['vouchers'] ?? [];
      }
    } catch (e) {
      debugPrint('fetchVouchers error: $e');
    }
  }
}

