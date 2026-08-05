import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../view/help_and_support.dart';
import '../view/login.dart';
import '../view/salon_details.dart';
import '../view/transaction_details.dart';

class ProfileController extends GetxController {
  // Observable salon profile fields (loaded dynamically from Firestore)
  final RxString salonName = ''.obs;
  final RxString address = ''.obs;
  final RxString ownerName = ''.obs;
  final RxString phone = ''.obs;
  final RxString shopImage = ''.obs;
  final RxString openingHours = ''.obs;
  final RxString closingHours = ''.obs;
  final RxList<String> categories = <String>[].obs;

  // Form controllers for editing Salon Details
  final salonNameController = TextEditingController();
  final ownerNameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final shopImageUrlController = TextEditingController();

  // Operating Hours
  final Rx<TimeOfDay?> openingTime = Rx<TimeOfDay?>(
    const TimeOfDay(hour: 9, minute: 0),
  );
  final Rx<TimeOfDay?> closingTime = Rx<TimeOfDay?>(
    const TimeOfDay(hour: 21, minute: 0),
  );

  // Categories Selection
  final List<String> availableCategories = ['Facial', 'Massage', 'Nails', 'Hair', 'Spa'];
  final RxList<String> selectedCategories = <String>[].obs;

  // Shop Image Selection
  final Rx<File?> selectedShopImage = Rx<File?>(null);
  final ImagePicker _picker = ImagePicker();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSalonProfile();
  }

  @override
  void onClose() {
    salonNameController.dispose();
    ownerNameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    shopImageUrlController.dispose();
    super.onClose();
  }

  /// Fetches salon details from Cloud Firestore for current authenticated user
  Future<void> fetchSalonProfile() async {
    try {
      if (salonName.value.isEmpty) {
        isLoading.value = true;
      }
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
          phone.value = data['phone']?.toString() ?? '';
          shopImage.value = data['shopImage']?.toString() ?? '';
          openingHours.value = data['openingHours']?.toString() ?? '9 AM';
          closingHours.value = data['closingHours']?.toString() ?? '9 PM';

          if (data['categories'] != null && data['categories'] is List) {
            final List list = data['categories'] as List;
            categories.assignAll(list.map((e) => e.toString()).toList());
          }

          // Populate edit form defaults
          initEditForm();
        }
      }
    } catch (e) {
      debugPrint('Error fetching salon profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Populates text controllers and selections from reactive variables
  void initEditForm() {
    salonNameController.text = salonName.value;
    ownerNameController.text = ownerName.value;
    phoneController.text = phone.value;
    addressController.text = address.value;
    shopImageUrlController.text = shopImage.value;
    selectedCategories.assignAll(categories);

    openingTime.value = _parseTimeString(openingHours.value) ??
        const TimeOfDay(hour: 9, minute: 0);
    closingTime.value = _parseTimeString(closingHours.value) ??
        const TimeOfDay(hour: 21, minute: 0);
  }

  /// Toggle category selection
  void toggleCategory(String category) {
    final lowerCat = category.toLowerCase();
    if (selectedCategories.contains(lowerCat)) {
      selectedCategories.remove(lowerCat);
    } else {
      selectedCategories.add(lowerCat);
    }
  }

  /// Opens time picker for Opening Time
  Future<void> selectOpeningTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: openingTime.value ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      openingTime.value = picked;
    }
  }

  /// Opens time picker for Closing Time
  Future<void> selectClosingTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: closingTime.value ?? const TimeOfDay(hour: 21, minute: 0),
    );
    if (picked != null) {
      closingTime.value = picked;
    }
  }

  /// Formats TimeOfDay to user-friendly String
  String formatTime(TimeOfDay? time) {
    if (time == null) return 'Select Time';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute == 0 ? '' : ':${time.minute.toString().padLeft(2, '0')}';
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour$minute $period';
  }

  TimeOfDay? _parseTimeString(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    try {
      final clean = timeStr.trim().toUpperCase();
      final isPm = clean.contains('PM');
      final isAm = clean.contains('AM');
      final digits = clean.replaceAll(RegExp(r'[^0-9:]'), '');
      final parts = digits.split(':');
      if (parts.isEmpty || parts[0].isEmpty) return null;
      int hour = int.parse(parts[0]);
      int minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      if (isPm && hour < 12) hour += 12;
      if (isAm && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  /// Pick shop image from gallery and crop
  Future<void> pickAndCropShopImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      try {
        final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Shop Photo',
              toolbarColor: const Color(0xFF041C16),
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.ratio16x9,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              title: 'Crop Shop Photo',
              aspectRatioLockEnabled: false,
            ),
          ],
        );

        if (croppedFile != null) {
          selectedShopImage.value = File(croppedFile.path);
        } else {
          selectedShopImage.value = File(pickedFile.path);
        }
      } catch (_) {
        // Fallback to picked file if cropping fails or is unavailable
        selectedShopImage.value = File(pickedFile.path);
      }
    } catch (e) {
      Get.snackbar(
        'Image Error',
        'Could not pick image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  /// Remove selected shop image
  void removeShopImage() {
    selectedShopImage.value = null;
    shopImageUrlController.clear();
  }

  /// Save changes to Firestore
  Future<void> saveSalonDetails() async {
    if (salonNameController.text.trim().isEmpty) {
      _showError('Please enter your Salon Name.');
      return;
    }
    if (ownerNameController.text.trim().isEmpty) {
      _showError('Please enter the Owner Name.');
      return;
    }
    final String rawPhone = phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (rawPhone.length != 10) {
      _showError('Please enter a valid 10-digit contact phone number.');
      return;
    }
    if (addressController.text.trim().isEmpty) {
      _showError('Please enter Salon Address.');
      return;
    }
    if (selectedCategories.isEmpty) {
      _showError('Please select at least one category.');
      return;
    }

    isSaving.value = true;
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final String rawPhone = phoneController.text.replaceAll(RegExp(r'\D'), '');
        final dynamic phoneVal = int.tryParse(rawPhone) ?? phoneController.text.trim();

        String finalShopImage = shopImageUrlController.text.trim();
        if (selectedShopImage.value != null) {
          finalShopImage = selectedShopImage.value!.path;
        }

        final Map<String, dynamic> updatedData = {
          'salonName': salonNameController.text.trim(),
          'ownerName': ownerNameController.text.trim(),
          'phone': phoneVal,
          'address': addressController.text.trim(),
          'openingHours': formatTime(openingTime.value),
          'closingHours': formatTime(closingTime.value),
          'categories': selectedCategories.toList(),
          'shopImage': finalShopImage,
        };

        await FirebaseFirestore.instance
            .collection('salons')
            .doc(currentUser.uid)
            .update(updatedData);

        // Update local reactive variables
        salonName.value = salonNameController.text.trim();
        ownerName.value = ownerNameController.text.trim();
        phone.value = phoneController.text.trim();
        address.value = addressController.text.trim();
        openingHours.value = formatTime(openingTime.value);
        closingHours.value = formatTime(closingTime.value);
        categories.assignAll(selectedCategories);
        shopImage.value = finalShopImage;

        Get.snackbar(
          'Success',
          'Salon details updated successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF041C16),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );

        Get.back();
      }
    } catch (e) {
      _showError('Failed to save salon details: $e');
    } finally {
      isSaving.value = false;
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Validation Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade700,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void onSalonDetailsTap() {
    initEditForm();
    Get.to(() => const SalonDetailsView());
  }

  void onTransactionDetailsTap() {
    Get.to(() => const TransactionDetailsView());
  }

  void onPayoutSettingsTap() {
    Get.snackbar(
      'Coming Soon',
      'Payout Settings & Direct Bank Transfers will be available in an upcoming update.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF041C16),
      colorText: Colors.white,
      icon: const Icon(Icons.schedule_rounded, color: Color(0xFFEFE0D3)),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void onHelpAndSupportTap() {
    Get.to(() => const HelpAndSupportView());
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

