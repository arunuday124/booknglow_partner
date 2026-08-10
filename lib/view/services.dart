import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controller/services_controller.dart';

/// Service Menu View built using GetView (StatelessWidget) and GetX
class ServicesView extends GetView<ServicesController> {
  const ServicesView({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject ServicesController safely
    if (!Get.isRegistered<ServicesController>()) {
      Get.put(ServicesController());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Text(
          "Book'N'Glow",
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF041C16),
          ),
        ),
        centerTitle: false,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(height: 1.0, thickness: 1.0, color: Color(0xFFE5E7EB)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8.0, right: 4.0),
        child: _AddServiceFabWidget(
          onTap: () => controller.showAddServiceModal(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _ServiceMenuHeaderSection(),
                  SizedBox(height: 24),
                  _ServiceListSection(),
                  SizedBox(height: 80), // Extra space for FAB
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Service Menu Header Text Section (Stateless)
class _ServiceMenuHeaderSection extends StatelessWidget {
  const _ServiceMenuHeaderSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Menu',
          style: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF041C16),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Curate your salon\'s professional offerings. Each treatment is designed to provide an unparalleled experience for your clientele.',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF4B5563),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

/// Service Card List Section (Stateless)
class _ServiceListSection extends GetView<ServicesController> {
  const _ServiceListSection();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.services.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6F5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFE0D3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.content_cut_rounded,
                  size: 28,
                  color: Color(0xFF041C16),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'No Services Added Yet',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF041C16),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap "+ ADD SERVICE" below to add your first treatment to your menu.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.services.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final service = controller.services[index];
          return _ServiceCardTile(
            service: service,
            onEdit: () => controller.showEditServiceModal(context, service),
            onRemove: () => controller.confirmAndRemoveService(service),
          );
        },
      );
    });
  }
}

/// Single Service Card Item Widget (Stateless)
class _ServiceCardTile extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _ServiceCardTile({
    required this.service,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Price Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service.serviceName,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF041C16),
                ),
              ),
              Text(
                '₹${service.price}',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF041C16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Duration & Category Tag Row
          Row(
            children: [
              // Duration Tag
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    service.duration,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),

              // Category Tag
              Row(
                children: [
                  const Icon(
                    Icons.label_outline_rounded,
                    size: 16,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    service.catagory.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Divider Line
          const Divider(height: 1.0, thickness: 1.0, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 14),

          // Action Buttons Row (EDIT DETAILS | REMOVE)
          Row(
            children: [
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    'EDIT DETAILS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    'REMOVE',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: const Color(0xFFE57373),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Floating "+ ADD SERVICE" Button Widget (Stateless)
class _AddServiceFabWidget extends StatelessWidget {
  final VoidCallback onTap;

  const _AddServiceFabWidget({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF041C16),
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'ADD SERVICE',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
