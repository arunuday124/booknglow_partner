import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controller/registration_controller.dart';
import 'login.dart';

/// Salon Registration View built using GetView (StatelessWidget) and GetX
class RegistrationView extends GetView<RegistrationController> {
  const RegistrationView({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject RegistrationController
    Get.put(RegistrationController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF041C16),
            size: 20,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Get.back();
            } else {
              Get.offAll(() => const SalonOwnerLoginView());
            }
          },
        ),
        title: Text(
          "Book'N'Glow",
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF041C16),
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _HeaderSection(),
                  SizedBox(height: 24),
                  _RegistrationCardForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Registration Header Text Section
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Salon Registration',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF041C16),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Please complete your business details to set up your account.',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF4B5563),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// Registration Form Card (Stateless)
class _RegistrationCardForm extends GetView<RegistrationController> {
  const _RegistrationCardForm();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Salon Name Field (Required)
          _CustomInputField(
            label: 'Salon / Business Name',
            hintText: 'e.g. Zen Salon & Spa',
            controller: controller.salonNameController,
            icon: Icons.storefront_outlined,
            isRequired: true,
          ),
          const SizedBox(height: 18),

          // Owner Name Field (Required)
          _CustomInputField(
            label: 'Owner Full Name',
            hintText: 'e.g. Rahul Verma',
            controller: controller.ownerNameController,
            icon: Icons.person_outline_rounded,
            isRequired: true,
          ),
          const SizedBox(height: 18),

          // Phone Number Field (Required)
          _CustomInputField(
            label: 'Contact Phone Number',
            hintText: 'Enter 10-digit phone number',
            controller: controller.phoneController,
            keyboardType: TextInputType.phone,
            icon: Icons.phone_outlined,
            isRequired: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
          const SizedBox(height: 18),

          // Salon Type Field (Required: Male, Female, Unisex)
          Row(
            children: [
              Text(
                'Salon Type',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              Text(
                ' *',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Obx(
            () => Row(
              children: controller.salonTypes.map((type) {
                final isSelected =
                    controller.selectedSalonType.value.toLowerCase() ==
                        type.toLowerCase();
                IconData icon;
                if (type == 'Male') {
                  icon = Icons.male_rounded;
                } else if (type == 'Female') {
                  icon = Icons.female_rounded;
                } else {
                  icon = Icons.wc_rounded;
                }
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: _TypeChip(
                      label: type,
                      icon: icon,
                      isSelected: isSelected,
                      onTap: () => controller.selectSalonType(type),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),

          // Business Categories Multi-Select Chips (Required)
          Row(
            children: [
              Text(
                'Categories',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              Text(
                ' *',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Obx(
            () => Wrap(
              spacing: 8.0,
              runSpacing: 10.0,
              children: controller.categories.map((category) {
                final isSelected = controller.selectedCategories.contains(
                  category.toLowerCase(),
                );
                return _CategoryChip(
                  label: category,
                  isSelected: isSelected,
                  onTap: () => controller.toggleCategory(category),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),

          // Operating Hours (Opening Time & Closing Time - Required)
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => _TimePickerField(
                    label: 'Opening Time',
                    timeText: controller.formatTime(
                      controller.openingTime.value,
                    ),
                    onTap: () => controller.selectOpeningTime(context),
                    isRequired: true,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Obx(
                  () => _TimePickerField(
                    label: 'Closing Time',
                    timeText: controller.formatTime(
                      controller.closingTime.value,
                    ),
                    onTap: () => controller.selectClosingTime(context),
                    isRequired: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Address Field (Required)
          _CustomInputField(
            label: 'Salon Address',
            hintText: 'Full street address, city & pincode',
            controller: controller.addressController,
            maxLines: 2,
            icon: Icons.location_on_outlined,
            isRequired: true,
          ),
          const SizedBox(height: 8),

          // Fetch Location Button
          Obx(
            () => Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: controller.isFetchingLocation.value
                    ? null
                    : controller.fetchCurrentLocation,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  side: const BorderSide(color: Color(0xFF041C16), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: const Color(0xFFF9FAFB),
                ),
                icon: controller.isFetchingLocation.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF041C16),
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.my_location_rounded,
                        size: 16,
                        color: Color(0xFF041C16),
                      ),
                label: Text(
                  controller.isFetchingLocation.value
                      ? 'FETCHING LOCATION...'
                      : (controller.currentPosition.value != null
                          ? 'LOCATION SET (${controller.currentPosition.value!.latitude.toStringAsFixed(3)}, ${controller.currentPosition.value!.longitude.toStringAsFixed(3)})'
                          : 'FETCH CURRENT LOCATION'),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: const Color(0xFF041C16),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Shop / Salon Photo Picker Field (OPTIONAL)
          Row(
            children: [
              Text(
                'Shop / Salon Photo',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(Optional)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Obx(
            () => _ShopImagePickerWidget(
              imageFile: controller.selectedShopImage.value,
              onTap: controller.pickAndCropShopImage,
              onRemove: controller.removeShopImage,
            ),
          ),
          const SizedBox(height: 28),

          // Submit Button
          Obx(
            () => SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : controller.submitRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF041C16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'COMPLETE REGISTRATION',
                        style: GoogleFonts.inter(
                          fontSize: 14,
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
    );
  }
}

/// Shop Image Picker & Preview Widget (Stateless)
class _ShopImagePickerWidget extends StatelessWidget {
  final File? imageFile;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ShopImagePickerWidget({
    required this.imageFile,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (imageFile != null) {
      return Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.file(
                imageFile!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
            // Actions Overlay
            Positioned(
              right: 10,
              top: 10,
              child: Row(
                children: [
                  InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(166),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.crop_rotate_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Crop / Change',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onRemove,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD1D5DB), width: 1.2),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFEFE0D3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                size: 24,
                color: Color(0xFF041C16),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Upload Shop Photo (Optional)',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to select & crop image',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Category Multi-Select Chip Widget (Stateless)
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF041C16) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF041C16)
                : const Color(0xFFD1D5DB),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_rounded : Icons.add_rounded,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Time Picker Field Widget (Stateless)
class _TimePickerField extends StatelessWidget {
  final String label;
  final String timeText;
  final VoidCallback onTap;
  final bool isRequired;

  const _TimePickerField({
    required this.label,
    required this.timeText,
    required this.onTap,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 20,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    timeText,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom Input Field Widget (Stateless)
class _CustomInputField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final IconData icon;
  final int maxLines;
  final bool isRequired;
  final List<TextInputFormatter>? inputFormatters;

  const _CustomInputField({
    required this.label,
    required this.hintText,
    required this.controller,
    this.keyboardType = TextInputType.text,
    required this.icon,
    this.maxLines = 1,
    this.isRequired = false,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF1F2937),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF9CA3AF),
            ),
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF6B7280)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF041C16),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom Salon Type Selection Chip Widget (Stateless)
class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF041C16) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF041C16) : const Color(0xFFD1D5DB),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF041C16).withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? const Color(0xFFC5A880) : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
