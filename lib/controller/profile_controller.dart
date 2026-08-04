import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:google_sign_in/google_sign_in.dart';

import '../view/login.dart';

class ProfileController extends GetxController {
  // Observable salon profile fields (loaded dynamically from Firestore)
  final RxString salonName = ''.obs;
  final RxString address = ''.obs;
  final RxString ownerName = ''.obs;
  final RxString shopImage = ''.obs;

  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSalonProfile();
  }

  /// Fetches salon details from Cloud Firestore for current authenticated user
  Future<void> fetchSalonProfile() async {
    try {
      isLoading.value = true;
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('salons')
            .doc(currentUser.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          salonName.value = data['salonName']?.toString() ?? '';
          address.value = data['address']?.toString() ?? '';
          ownerName.value = data['ownerName']?.toString() ?? '';
          shopImage.value = data['shopImage']?.toString() ?? '';
        }
      }
    } catch (e) {
      debugPrint('Error fetching salon profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void onSalonDetailsTap() {
    Get.snackbar(
      'Salon Details',
      'Manage your branding and contact info',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF041C16),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void onTransactionDetailsTap() {
    Get.snackbar(
      'Transaction Details',
      'View and manage your recent bookings and payment history.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF041C16),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void onPayoutSettingsTap() {
    Get.snackbar(
      'Payout Settings',
      'Bank details and revenue reports',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF041C16),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void onHelpAndSupportTap() {
    Get.snackbar(
      'Help & Support',
      'Get assistance and read FAQs',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF041C16),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  /// Handles User Logout
  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      try {
        await GoogleSignIn.instance.initialize();
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
      Get.snackbar(
        'Logged Out',
        'You have been logged out successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF041C16),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      Get.offAll(() => const SalonOwnerLoginView());
    } catch (e) {
      Get.snackbar(
        'Logout Error',
        'Failed to log out: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }
}
