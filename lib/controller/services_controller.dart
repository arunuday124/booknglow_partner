import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceModel {
  final String serviceName;
  final String catagory;
  final String duration;
  final int price;
  final String salonId;

  ServiceModel({
    required this.serviceName,
    required this.catagory,
    required this.duration,
    required this.price,
    required this.salonId,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map, String defaultSalonId) {
    return ServiceModel(
      serviceName: map['serviceName'] ?? map['title'] ?? 'Unnamed Service',
      catagory: map['catagory'] ?? map['category'] ?? map['tag'] ?? 'general',
      duration: map['duration'] ?? '30 min',
      price: (map['price'] is int)
          ? map['price']
          : (int.tryParse(map['price']?.toString() ?? '0') ?? 0),
      salonId: map['salonId'] ?? defaultSalonId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'catagory': catagory.toLowerCase(),
      'duration': duration,
      'price': price,
      'salonId': salonId,
      'serviceName': serviceName,
    };
  }
}

class ServicesController extends GetxController {
  // Reactive list of salon services (loaded dynamically from Firestore)
  final RxList<ServiceModel> services = <ServiceModel>[].obs;

  // Add Service Form Controllers
  final serviceNameController = TextEditingController();
  final durationController = TextEditingController(text: '30 min');
  final priceController = TextEditingController();

  final List<String> availableCategories = ['Hair', 'Nails', 'Spa', 'Facial', 'Massage'];
  late final RxString selectedCategory = availableCategories.first.obs;

  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchServicesFromFirestore();
  }

  @override
  void onClose() {
    serviceNameController.dispose();
    durationController.dispose();
    priceController.dispose();
    super.onClose();
  }

  /// Fetches existing services from Cloud Firestore for the logged in salon
  Future<void> fetchServicesFromFirestore() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('salons')
            .doc(currentUser.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['services'] != null && data['services'] is List) {
            final List rawServices = data['services'] as List;
            if (rawServices.isNotEmpty) {
              services.value = rawServices
                  .map((item) => ServiceModel.fromMap(
                        Map<String, dynamic>.from(item),
                        currentUser.uid,
                      ))
                  .toList();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching services: $e');
    }
  }

  /// Opens the Add Service Form Bottom Sheet Modal
  void showAddServiceModal(BuildContext context) {
    serviceNameController.clear();
    durationController.text = '30 min';
    priceController.clear();
    selectedCategory.value = availableCategories.first;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Drag Handle Indicator
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                'Add New Service',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF041C16),
                ),
              ),
              const SizedBox(height: 16),

              // Service Name Field
              Text(
                'Service Name *',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: serviceNameController,
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1F2937)),
                decoration: InputDecoration(
                  hintText: 'e.g. Gel Manicure',
                  hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF9CA3AF)),
                  prefixIcon: const Icon(Icons.content_cut_outlined, size: 20, color: Color(0xFF6B7280)),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF041C16), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category Selection Chips
              Text(
                'Category *',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: availableCategories.map((cat) {
                    final isSelected = selectedCategory.value == cat;
                    return ChoiceChip(
                      label: Text(
                        cat,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF374151),
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) selectedCategory.value = cat;
                      },
                      selectedColor: const Color(0xFF041C16),
                      backgroundColor: const Color(0xFFF9FAFB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF041C16) : const Color(0xFFD1D5DB),
                        ),
                      ),
                      showCheckmark: false,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Duration & Price Row
              Row(
                children: [
                  // Duration Field
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Duration *',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: durationController,
                          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1F2937)),
                          decoration: InputDecoration(
                            hintText: 'e.g. 60 min',
                            hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF9CA3AF)),
                            prefixIcon: const Icon(Icons.access_time_rounded, size: 20, color: Color(0xFF6B7280)),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF041C16), width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Price Field
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Price (₹) *',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1F2937)),
                          decoration: InputDecoration(
                            hintText: 'e.g. 250',
                            hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF9CA3AF)),
                            prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18, color: Color(0xFF6B7280)),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF041C16), width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit Button
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isSaving.value ? null : saveNewService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF041C16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: isSaving.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'SAVE SERVICE',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  /// Validates inputs and saves new service to Firestore & local list
  Future<void> saveNewService() async {
    final String name = serviceNameController.text.trim();
    final String duration = durationController.text.trim();
    final String priceText = priceController.text.trim();

    if (name.isEmpty) {
      _showError('Please enter a service name.');
      return;
    }
    if (duration.isEmpty) {
      _showError('Please enter the service duration.');
      return;
    }
    if (priceText.isEmpty) {
      _showError('Please enter the service price.');
      return;
    }

    final int? priceInt = int.tryParse(priceText);
    if (priceInt == null || priceInt < 0) {
      _showError('Please enter a valid price amount.');
      return;
    }

    isSaving.value = true;
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      final String salonId = currentUser?.uid ?? 'salon_demo_id';

      final ServiceModel newService = ServiceModel(
        serviceName: name,
        catagory: selectedCategory.value.toLowerCase(),
        duration: duration,
        price: priceInt,
        salonId: salonId,
      );

      // Store in Cloud Firestore if user is authenticated
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('salons')
            .doc(currentUser.uid)
            .set({
          'services': FieldValue.arrayUnion([newService.toMap()]),
        }, SetOptions(merge: true));
      }

      // Append to local reactive services list
      services.add(newService);

      Get.back(); // Close bottom sheet

      Get.snackbar(
        'Service Added',
        '${newService.serviceName} has been added to your menu!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF041C16),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      _showError('Failed to save service: $e');
    } finally {
      isSaving.value = false;
    }
  }

  void editService(ServiceModel service) {
    Get.snackbar(
      'Edit Service',
      'Editing details for ${service.serviceName}...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF041C16),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  /// Prompts a confirmation dialog before removing a service
  void confirmAndRemoveService(ServiceModel service) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon Badge
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 32,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Remove Service?',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF041C16),
                ),
              ),
              const SizedBox(height: 10),

              // Confirmation Message
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF4B5563),
                    height: 1.45,
                  ),
                  children: [
                    const TextSpan(text: 'Are you sure you really want to remove '),
                    TextSpan(
                      text: '"${service.serviceName}"',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const TextSpan(text: ' from your service menu? This action cannot be undone.'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons Row (NO, CANCEL | YES, REMOVE)
              Row(
                children: [
                  // Cancel / No Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        'NO, CANCEL',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Confirm / Yes Remove Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back(); // Close confirmation dialog
                        await removeService(service);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.red.shade700,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        'YES, REMOVE',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> removeService(ServiceModel service) async {
    services.removeWhere((item) =>
        item.serviceName == service.serviceName && item.price == service.price);

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('salons')
            .doc(currentUser.uid)
            .set({
          'services': FieldValue.arrayRemove([service.toMap()]),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error removing service from Firestore: $e');
    }

    Get.snackbar(
      'Service Removed',
      '${service.serviceName} removed from menu.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF041C16),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _showError(String message) {
    Get.snackbar(
      'Validation Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade700,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }
}
