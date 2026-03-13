import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';

class CourtController extends GetxController {
  final ApiService _api = ApiService();

  var isLoading = false.obs;
  var courts = <dynamic>[].obs;
  var searchResults = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchCourts();
  }

  Future<void> fetchCourts({String? category}) async {
    try {
      isLoading.value = true;
      final response = await _api.getCourts(category: category);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        courts.value = data['courts'] ?? [];
      }
    } catch (e) {
      debugPrint('fetchCourts error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> searchCourts(String keyword) async {
    if (keyword.trim().isEmpty) {
      searchResults.clear();
      return;
    }
    try {
      final response = await _api.searchCourts(keyword);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        searchResults.value = data['courts'] ?? [];
      }
    } catch (e) {
      debugPrint('searchCourts error: $e');
    }
  }

  Future<Map<String, dynamic>?> getCourtDetail(String courtId) async {
    try {
      final response = await _api.getCourtDetail(courtId);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('getCourtDetail error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getTimeSlots(String courtId, String date) async {
    try {
      final response = await _api.getTimeSlots(courtId, date);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('getTimeSlots error: $e');
    }
    return null;
  }
}

