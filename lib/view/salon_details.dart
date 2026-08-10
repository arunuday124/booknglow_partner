import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controller/profile_controller.dart';

/// Salon Details Edit View built using GetView (StatelessWidget) and GetX
class SalonDetailsView extends GetView<ProfileController> {
  const SalonDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF041C16), size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Salon Details',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF041C16),
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(
            height: 1.0,
            thickness: 1.0,
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _ShopImageEditHeader(),
                  SizedBox(height: 24),
                  _SalonFormFields(),
                  SizedBox(height: 24),
                  _OperatingHoursSection(),
                  SizedBox(height: 24),
                  _CategoriesSelectionSection(),
                  SizedBox(height: 32),
                  _SaveSalonDetailsButton(),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shop Image Edit Header Card (Stateless)
class _ShopImageEditHeader extends GetView<ProfileController> {
  const _ShopImageEditHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shop Image',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () {
            final File? pickedFile = controller.selectedShopImage.value;
            final String existingUrl = controller.shopImage.value;

            return Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 170,
                  decoration: BoxDecoration(
                    color: const Color(0xFF041C16),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _buildImageWidget(pickedFile, existingUrl),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: controller.pickAndCropShopImage,
                        icon: const Icon(Icons.camera_alt_outlined, size: 16, color: Colors.white),
                        label: Text(
                          'Change Image',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF041C16).withValues(alpha: 0.85),
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      if (pickedFile != null || existingUrl.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: controller.removeShopImage,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildImageWidget(File? pickedFile, String existingUrl) {
    if (pickedFile != null) {
      return Image.file(pickedFile, fit: BoxFit.cover, width: double.infinity, height: 170);
    }
    if (existingUrl.isNotEmpty) {
      if (existingUrl.startsWith('http://') || existingUrl.startsWith('https://')) {
        return Image.network(
          existingUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 170,
          errorBuilder: (context, error, stackTrace) => const _DefaultShopPlaceholder(),
        );
      } else {
        final localFile = File(existingUrl);
        if (localFile.existsSync()) {
          return Image.file(localFile, fit: BoxFit.cover, width: double.infinity, height: 170);
        }
      }
    }
    return const _DefaultShopPlaceholder();
  }
}

/// Default Shop Image Placeholder Widget (Stateless)
class _DefaultShopPlaceholder extends StatelessWidget {
  const _DefaultShopPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF041C16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront_rounded, size: 36, color: Color(0xFFEFE0D3)),
            const SizedBox(height: 6),
            Text(
              "Book'N'Glow",
              style: GoogleFonts.playfairDisplay(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFEFE0D3),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Tap 'Change Image' to add photo",
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Salon Information Input Fields Section (Stateless)
class _SalonFormFields extends GetView<ProfileController> {
  const _SalonFormFields();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shop Name Field
        _CustomTextField(
          controller: controller.salonNameController,
          label: 'Shop Name',
          hintText: 'Enter your business or salon name',
          icon: Icons.storefront_outlined,
        ),
        const SizedBox(height: 16),

        // Owner Name Field
        _CustomTextField(
          controller: controller.ownerNameController,
          label: 'Owner Name',
          hintText: 'Enter salon owner full name',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 16),

        // Phone Number Field
        _CustomTextField(
          controller: controller.phoneController,
          label: 'Contact Phone Number',
          hintText: 'Enter 10-digit phone number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
        ),
        const SizedBox(height: 16),

        // Address Field
        _CustomTextField(
          controller: controller.addressController,
          label: 'Address',
          hintText: 'Enter salon street address & city',
          icon: Icons.location_on_outlined,
          maxLines: 3,
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
                backgroundColor: Colors.white,
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
      ],
    );
  }
}

/// Operating Hours Picker Section (Stateless)
class _OperatingHoursSection extends GetView<ProfileController> {
  const _OperatingHoursSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF041C16)),
            const SizedBox(width: 6),
            Text(
              'Operating Hours',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Opening Hours Button
            Expanded(
              child: Obx(
                () => _TimeSelectorTile(
                  title: 'Opening Time',
                  timeText: controller.formatTime(controller.openingTime.value),
                  onTap: () => controller.selectOpeningTime(context),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Closing Hours Button
            Expanded(
              child: Obx(
                () => _TimeSelectorTile(
                  title: 'Closing Time',
                  timeText: controller.formatTime(controller.closingTime.value),
                  onTap: () => controller.selectClosingTime(context),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Individual Time Selector Tile Widget (Stateless)
class _TimeSelectorTile extends StatelessWidget {
  final String title;
  final String timeText;
  final VoidCallback onTap;

  const _TimeSelectorTile({
    required this.title,
    required this.timeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  timeText,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF041C16),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF6B7280)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Categories Selection Section Widget (Stateless)
class _CategoriesSelectionSection extends GetView<ProfileController> {
  const _CategoriesSelectionSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.grid_view_rounded, size: 18, color: Color(0xFF041C16)),
            const SizedBox(width: 6),
            Text(
              'Categories',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Select categories your salon provides:',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Wrap(
            spacing: 8.0,
            runSpacing: 10.0,
            children: controller.availableCategories.map((category) {
              final isSelected = controller.selectedCategories.contains(category.toLowerCase());
              return FilterChip(
                label: Text(
                  category,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF374151),
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => controller.toggleCategory(category),
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFF041C16),
                checkmarkColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF041C16) : const Color(0xFFD1D5DB),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Save Salon Details Action Button Widget (Stateless)
class _SaveSalonDetailsButton extends GetView<ProfileController> {
  const _SaveSalonDetailsButton();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: controller.isSaving.value ? null : controller.saveSalonDetails,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF041C16),
            disabledBackgroundColor: const Color(0xFF041C16).withValues(alpha: 0.6),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: controller.isSaving.value
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'SAVE CHANGES',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Reusable Custom Form TextField Widget (Stateless)
class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final TextInputType keyboardType;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  const _CustomTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1F2937),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF9CA3AF),
            ),
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF6B7280)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF041C16), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
