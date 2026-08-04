import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  final RxString revenue = '₹ 42.8k'.obs;
  final RxString revenueGrowth = '+12% vs last week'.obs;
  final RxInt totalBookings = 24.obs;
  final RxInt pendingBookings = 8.obs;

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
