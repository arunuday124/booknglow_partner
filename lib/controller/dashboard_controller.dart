import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'profile_controller.dart';

class DailyLogModel {
  final String title;
  final String status;
  final String time;
  final String service;
  final Color indicatorColor;

  DailyLogModel({
    required this.title,
    required this.status,
    required this.time,
    required this.service,
    required this.indicatorColor,
  });
}

class DashboardController extends GetxController {
  // Navigation Index (0: Dashboard, 1: Bookings, 2: Services, 3: Profile)
  final RxInt selectedNavIndex = 0.obs;

  // Salon Details & Metrics
  final RxString salonName = 'Zen Salon'.obs;
  final RxString ownerName = ''.obs;
  final RxString revenue = '₹ 42.8k'.obs;
  final RxString revenueGrowth = '+12% vs last week'.obs;
  final RxInt totalBookings = 24.obs;
  final RxInt pendingBookings = 8.obs;

  // Reviews Metrics
  final RxString reviewsRating = '4.8 ★'.obs;
  final RxInt totalReviews = 128.obs;

  /// Returns owner or salon first name (e.g. "Arunuday Debnath" -> "Arunuday")
  String get firstName {
    String name = ownerName.value.trim();
    if (name.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null &&
          user.displayName != null &&
          user.displayName!.trim().isNotEmpty) {
        name = user.displayName!.trim();
      }
    }
    if (name.isEmpty) {
      name = salonName.value.trim();
    }
    if (name.isEmpty) return 'Partner';
    return name.split(RegExp(r'\s+')).first;
  }

  @override
  void onInit() {
    super.onInit();
    fetchDashboardMetrics();
  }

  /// Fetches salon rating and review metrics dynamically from Firestore
  Future<void> fetchDashboardMetrics({bool force = false}) async {
    // 1. Check ProfileController in memory first (0 network calls)
    if (!force && Get.isRegistered<ProfileController>()) {
      final profile = Get.find<ProfileController>();
      if (profile.salonName.value.isNotEmpty || profile.ownerName.value.isNotEmpty) {
        if (profile.salonName.value.isNotEmpty) salonName.value = profile.salonName.value;
        if (profile.ownerName.value.isNotEmpty) ownerName.value = profile.ownerName.value;
        return;
      }
    }

    if (!force && salonName.value.isNotEmpty && ownerName.value.isNotEmpty && salonName.value != 'Zen Salon') {
      return; // Return immediately from memory without extra Firebase calls
    }

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('salons')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['ownerName'] != null &&
              data['ownerName'].toString().isNotEmpty) {
            ownerName.value = data['ownerName'].toString();
          }
          if (data['salonName'] != null &&
              data['salonName'].toString().isNotEmpty) {
            salonName.value = data['salonName'].toString();
          }
          if (data['ratings'] != null) {
            final double r = double.tryParse(data['ratings'].toString()) ?? 4.8;
            reviewsRating.value = '${r.toStringAsFixed(1)} ★';
          }
          if (data['reviews'] != null) {
            totalReviews.value =
                int.tryParse(data['reviews'].toString()) ?? 128;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching dashboard metrics: $e');
    }
  }

  // Next Up Booking Details
  final RxString nextClientName = 'Ananya Sharma'.obs;
  final RxString nextService = 'Hair Cut & Botanical...'.obs;
  final RxString nextTime = '10:30 AM'.obs;
  final RxString nextStaff = 'Rahul V.'.obs;
  final RxString nextTimeLeft = 'In 15m'.obs;

  // Daily Logs List
  final RxList<DailyLogModel> dailyLogs = <DailyLogModel>[
    DailyLogModel(
      title: 'Priya K.',
      service: 'Pedicure',
      status: 'Completed',
      time: '09:45 AM',
      indicatorColor: const Color(0xFF655B49), // Olive / Brown
    ),
    DailyLogModel(
      title: 'Vikram M.',
      service: 'No Show',
      status: 'Hair Coloring',
      time: '09:15 AM',
      indicatorColor: const Color(0xFFDC2626), // Red
    ),
    DailyLogModel(
      title: 'Sanya D.',
      service: 'Arrived',
      status: 'Manicure',
      time: '10:15 AM',
      indicatorColor: const Color(0xFF22C55E), // Green
    ),
  ].obs;

  void changeNavIndex(int index) {
    selectedNavIndex.value = index;
  }

  void onViewAllActivity() {
    Get.snackbar(
      'Activity Logs',
      'Opening full activity logs history...',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}
