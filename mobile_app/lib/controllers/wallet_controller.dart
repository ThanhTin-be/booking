import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';

class WalletController extends GetxController {
  final ApiService _api = ApiService();

  var isLoading = false.obs;
  var balance = 0.obs;
  var points = 0.obs;
  var tier = 'member'.obs;
  var transactions = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchBalance();
  }

  Future<void> fetchBalance() async {
    try {
      final response = await _api.getWalletBalance();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final w = data['wallet'] ?? {};
        balance.value = (w['balance'] ?? 0).toInt();
        points.value = (w['points'] ?? 0).toInt();
        tier.value = w['tier'] ?? 'member';
      }
    } catch (e) {
      debugPrint('fetchBalance error: $e');
    }
  }

  Future<void> topUp(int amount) async {
    try {
      isLoading.value = true;
      final response = await _api.topUp(amount);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final w = data['wallet'] ?? {};
        balance.value = (w['balance'] ?? 0).toInt();
        points.value = (w['points'] ?? 0).toInt();
        tier.value = w['tier'] ?? 'member';
        Get.snackbar('Thành công', 'Nạp tiền thành công');
      } else {
        Get.snackbar('Lỗi', data['message'] ?? 'Nạp tiền thất bại');
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Lỗi kết nối');
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> createTopupUrl(int amount) async {
    try {
      isLoading.value = true;
      final response = await _api.createVnpayTopupUrl(amount);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['paymentUrl'];
      } else {
        final data = jsonDecode(response.body);
        Get.snackbar('Lỗi', data['message'] ?? 'Tạo nạp tiền thất bại');
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Lỗi kết nối');
    } finally {
      isLoading.value = false;
    }
    return null;
  }

  Future<void> fetchTransactions({String? type}) async {
    try {
      isLoading.value = true;
      final response = await _api.getTransactionHistory(type: type);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        transactions.value = data['transactions'] ?? [];
      }
    } catch (e) {
      debugPrint('fetchTransactions error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}

