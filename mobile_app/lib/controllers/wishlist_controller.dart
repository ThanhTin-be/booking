import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';

class WishlistController extends GetxController {
  final ApiService _api = ApiService();

  var isLoading = false.obs;
  var courts = <dynamic>[].obs;
  var courtIds = <String>{}.obs; // Set of court IDs for quick lookup

  @override
  void onInit() {
    super.onInit();
    fetchWishlist();
  }

  Future<void> fetchWishlist() async {
    try {
      isLoading.value = true;
      final response = await _api.getWishlist();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        courts.value = data['courts'] ?? [];
        courtIds.value = courts.map<String>((c) => c['_id'].toString()).toSet();
      }
    } catch (e) {
      debugPrint('fetchWishlist error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  bool isFavorite(String courtId) => courtIds.contains(courtId);

  Future<void> toggleFavorite(String courtId) async {
    try {
      if (isFavorite(courtId)) {
        final response = await _api.removeFromWishlist(courtId);
        if (response.statusCode == 200) {
          courtIds.remove(courtId);
          courts.removeWhere((c) => c['_id'] == courtId);
        }
      } else {
        final response = await _api.addToWishlist(courtId);
        if (response.statusCode == 200) {
          courtIds.add(courtId);
          fetchWishlist(); // Refresh to get full court data
        }
      }
    } catch (e) {
      debugPrint('toggleFavorite error: $e');
    }
  }
}

