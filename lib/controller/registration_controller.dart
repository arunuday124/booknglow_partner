import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../service/bunny_cdn_service.dart';
import '../view/dashboard.dart';

class RegistrationController extends GetxController {
  // Form controllers
  final salonNameController = TextEditingController();
  final ownerNameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  // Categories & Multi-selection (REQUIRED)
  final List<String> categories = ['Facial', 'Massage', 'Nails', 'Hair', 'Spa'];
  final RxList<String> selectedCategories = <String>[].obs;

  // Operating Hours (REQUIRED)
  final Rx<TimeOfDay?> openingTime = Rx<TimeOfDay?>(
    const TimeOfDay(hour: 9, minute: 0),
  );
  final Rx<TimeOfDay?> closingTime = Rx<TimeOfDay?>(
    const TimeOfDay(hour: 21, minute: 0),
  );

  // Salon Type (REQUIRED: Male, Female, Unisex)
  final List<String> salonTypes = ['Male', 'Female', 'Unisex'];
  final RxString selectedSalonType = ''.obs;

  void selectSalonType(String type) {
    selectedSalonType.value = type;
  }

  // Shop Image Selection & Cropping (OPTIONAL)
  final Rx<File?> selectedShopImage = Rx<File?>(null);
  final ImagePicker _picker = ImagePicker();

  // Location & Geolocation state
  final RxBool isFetchingLocation = false.obs;
  final Rx<Position?> currentPosition = Rx<Position?>(null);

  final RxBool isLoading = false.obs;

  @override
  void onClose() {
    salonNameController.dispose();
    ownerNameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.onClose();
  }

  /// Toggles category selection for multi-select (stores lowercase string)
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

  /// Formats TimeOfDay to user-friendly String (e.g. "9 AM" or "10 PM")
  String formatTime(TimeOfDay? time) {
    if (time == null) return 'Select Time';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute == 0 ? '' : ':${time.minute.toString().padLeft(2, '0')}';
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour$minute $period';
  }

  /// Pick shop image from gallery and crop (Optional)
  Future<void> pickAndCropShopImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

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
      }
    } catch (e) {
      if (e.toString().contains('MissingPluginException')) {
        Get.snackbar(
          'Rebuild Required',
          'Please stop the app completely and re-run (flutter run) to load the native image picker plugin.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade800,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      } else {
        Get.snackbar(
          'Image Error',
          'Could not pick or crop image: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
        );
      }
    }
  }

  /// Remove selected shop image
  void removeShopImage() {
    selectedShopImage.value = null;
  }

  /// Form Submission & Firestore Document Creation
  void submitRegistration() async {
    // 1. Validate Salon Name
    if (salonNameController.text.trim().isEmpty) {
      _showValidationError('Please enter your Salon / Business Name.');
      return;
    }

    // 2. Validate Owner Name
    if (ownerNameController.text.trim().isEmpty) {
      _showValidationError('Please enter the Owner Full Name.');
      return;
    }

    // 3. Validate Phone Number
    final String rawPhone = phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (rawPhone.length != 10) {
      _showValidationError('Please enter a valid 10-digit contact phone number.');
      return;
    }

    // 4. Validate Salon Type (Required)
    if (selectedSalonType.value.isEmpty) {
      _showValidationError('Please select a Salon Type.');
      return;
    }

    // 5. Validate Categories (Required)
    if (selectedCategories.isEmpty) {
      _showValidationError('Please select at least one business category.');
      return;
    }

    // 6. Validate Opening & Closing Times (Required)
    if (openingTime.value == null) {
      _showValidationError('Please select an Opening Time.');
      return;
    }

    if (closingTime.value == null) {
      _showValidationError('Please select a Closing Time.');
      return;
    }

    // 7. Validate Address (Required)
    if (addressController.text.trim().isEmpty) {
      _showValidationError('Please enter your Salon Address.');
      return;
    }

    isLoading.value = true;
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final FirebaseAuth auth = FirebaseAuth.instance;

      // Use authenticated user ID or generate a document ID
      final String salonId = auth.currentUser?.uid ?? firestore.collection('salons').doc().id;

      // Clean phone number to integer
      final String rawPhone = phoneController.text.replaceAll(RegExp(r'\D'), '');
      final int phoneNum = int.tryParse(rawPhone) ?? 0;

      // Fetch FCM Push Token
      String pushToken = "";
      try {
        pushToken = await FirebaseMessaging.instance.getToken() ?? "";
      } catch (e) {
        debugPrint('Error getting FCM push token: $e');
      }

      final GeoPoint locationGeoPoint = currentPosition.value != null
          ? GeoPoint(currentPosition.value!.latitude, currentPosition.value!.longitude)
          : const GeoPoint(0, 0);

      // Upload shop image to BunnyCDN if picked by user
      String shopImageUrl = "";
      if (selectedShopImage.value != null) {
        try {
          shopImageUrl = await BunnyCdnService.instance.uploadShopImage(
            file: selectedShopImage.value!,
            salonId: salonId,
          );
        } catch (e) {
          debugPrint('Error uploading shop image to BunnyCDN: $e');
        }
      }

      final Map<String, dynamic> salonData = {
        'address': addressController.text.trim(),
        'categories': selectedCategories.toList(),
        'closingHours': formatTime(closingTime.value),
        'createdAt': FieldValue.serverTimestamp(),
        'location': locationGeoPoint,
        'openingHours': formatTime(openingTime.value),
        'ownerName': ownerNameController.text.trim(),
        'phone': phoneNum,
        'pushToken': pushToken,
        'ratings': 0.0,
        'reviews': 0,
        'salonId': salonId,
        'salonName': salonNameController.text.trim(),
        'salonType': selectedSalonType.value.toLowerCase(), // 'male', 'female', 'unisex'
        'services': [],
        'shopImage': shopImageUrl,
      };

      // Save document to Firestore 'salons' collection
      await firestore.collection('salons').doc(salonId).set(salonData);

      Get.snackbar(
        'Registration Complete',
        'Welcome to Book\'N\'Glow Partner!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF041C16),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );

      // Redirect to Dashboard
      Get.offAll(() => const DashboardView());
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save salon details to Firestore: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetches current GPS location, reverse geocodes address into addressController, and captures Geolocation
  Future<void> fetchCurrentLocation() async {
    isFetchingLocation.value = true;
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showValidationError('Location services are disabled on your device. Please enable GPS.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showValidationError('Location permission was denied. Please allow location access to fetch address automatically.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showValidationError('Location permissions are permanently denied. Please enable location permission in system settings.');
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      currentPosition.value = position;

      try {
        final List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final Placemark place = placemarks.first;
          final List<String> addressParts = [];

          if (place.name != null && place.name!.isNotEmpty && place.name != place.street) {
            addressParts.add(place.name!);
          }
          if (place.street != null && place.street!.isNotEmpty) {
            addressParts.add(place.street!);
          }
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            addressParts.add(place.subLocality!);
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            addressParts.add(place.locality!);
          }
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            addressParts.add(place.administrativeArea!);
          }
          if (place.postalCode != null && place.postalCode!.isNotEmpty) {
            addressParts.add(place.postalCode!);
          }

          final String formattedAddress = addressParts.join(', ');
          if (formattedAddress.isNotEmpty) {
            addressController.text = formattedAddress;
          }
        }
      } catch (e) {
        debugPrint('Reverse geocoding notice: $e');
      }

      Get.snackbar(
        'Location Captured',
        'Address & geolocation coordinates updated successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF041C16),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.my_location_rounded, color: Colors.white),
      );
    } catch (e) {
      _showValidationError('Failed to fetch location: $e');
    } finally {
      isFetchingLocation.value = false;
    }
  }

  void _showValidationError(String message) {
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
}
