import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';

class NotificationController extends GetxController {
  final ApiService _api = ApiService();

  var isLoading = false.obs;
  var notifications = <dynamic>[].obs;
  var unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      final response = await _api.getNotifications();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        notifications.value = data['notifications'] ?? [];
        unreadCount.value = data['unreadCount'] ?? 0;
      }
    } catch (e) {
      debugPrint('fetchNotifications error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(String notifId) async {
    try {
      final response = await _api.markNotificationRead(notifId);
      if (response.statusCode == 200) {
        final index = notifications.indexWhere((n) => n['_id'] == notifId);
        if (index != -1) {
          notifications[index]['isRead'] = true;
          notifications.refresh();
          unreadCount.value = notifications.where((n) => n['isRead'] == false).length;
        }
      }
    } catch (e) {
      debugPrint('markAsRead error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final response = await _api.markAllNotificationsRead();
      if (response.statusCode == 200) {
        for (var n in notifications) {
          n['isRead'] = true;
        }
        notifications.refresh();
        unreadCount.value = 0;
      }
    } catch (e) {
      debugPrint('markAllAsRead error: $e');
    }
  }
}

