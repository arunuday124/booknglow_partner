import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../view/dashboard.dart';
import '../view/registration.dart';

class AuthController extends GetxController {
  // Reactive state for loading indicators
  final RxBool isLoadingGoogle = false.obs;
  final RxBool isLoadingApple = false.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Real Google Sign In + Firebase Auth Implementation (v7 GoogleSignIn.instance API)
  Future<void> loginWithGoogle() async {
    if (isLoadingGoogle.value || isLoadingApple.value) return;

    isLoadingGoogle.value = true;
    try {
      // 0. Initialize GoogleSignIn instance for v7 API
      await GoogleSignIn.instance.initialize();

      // 1. Force account selection popup by clearing any cached Google session
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}

      // 2. Trigger Google Sign-In account picker flow using v7 API (GoogleSignIn.instance)
      final googleUser = await GoogleSignIn.instance.authenticate();

      // 3. Obtain authentication credentials
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // 4. Create a Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 5. Sign in to Firebase Auth
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      Get.snackbar(
        'Google Login Successful',
        'Signed in as ${userCredential.user?.displayName ?? googleUser.email}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF041C16),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
      );

      // 6. Check if salon profile exists in Firestore
      if (userCredential.user != null) {
        await _checkExistingUserAndNavigate(userCredential.user!);
      } else {
        Get.offAll(() => const RegistrationView());
      }
    } catch (e) {
      Get.snackbar(
        'Authentication Error',
        'Failed to log in with Google: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isLoadingGoogle.value = false;
    }
  }

  /// Handles Apple Sign-In action (shows Coming Soon toast)
  void loginWithApple() {
    Get.snackbar(
      'Coming Soon',
      'Apple Sign-In is coming soon!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF041C16),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }

  /// Checks if current user has already registered a salon in Firestore
  Future<void> _checkExistingUserAndNavigate(User user) async {
    try {
      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('salons')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        // Registered user -> Navigate directly to Dashboard
        Get.offAll(() => const DashboardView());
      } else {
        // First-time user -> Navigate to Registration Form
        Get.offAll(() => const RegistrationView());
      }
    } catch (e) {
      // Fallback to Registration View on error
      Get.offAll(() => const RegistrationView());
    }
  }

  /// Opens Privacy Policy
  void openPrivacyPolicy() {
    Get.snackbar(
      'Privacy Policy',
      'Navigating to Privacy Policy...',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  /// Opens Support page
  void openSupport() {
    Get.snackbar(
      'Support',
      'Navigating to Support Desk...',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}
