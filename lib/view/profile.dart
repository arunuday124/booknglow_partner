import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controller/profile_controller.dart';

/// Profile View built using GetView (StatelessWidget) and GetX
class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject ProfileController
    final ProfileController profileController = Get.put(ProfileController());
    profileController.fetchSalonProfile();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        leadingWidth: 54,
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 16.0,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _SalonHeaderCard(),
                  SizedBox(height: 24),
                  _ProfileOptionListSection(),
                  SizedBox(height: 24),
                  _LogoutButtonWidget(),
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

/// Main Salon Info Card Widget (Stateless)
class _SalonHeaderCard extends GetView<ProfileController> {
  const _SalonHeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFF3F4F6)],
        ),
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
        children: [
          // Rectangular Avatar Logo Container
          Obx(
            () => Container(
              width: 400,
              height: 150,
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
                child: controller.shopImage.value.isNotEmpty
                    ? Image.network(
                        controller.shopImage.value,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const _DefaultRectangularLogo(),
                      )
                    : const _DefaultRectangularLogo(),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Salon Title
          Obx(
            () => Text(
              controller.salonName.value.isNotEmpty
                  ? controller.salonName.value
                  : (controller.isLoading.value ? 'Loading...' : 'My Salon'),
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF041C16),
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Location & Address Row
          Obx(
            () => controller.address.value.isNotEmpty
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2.0),
                        child: Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          controller.address.value,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4B5563),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Menu Option Item List Section (Stateless)
class _ProfileOptionListSection extends GetView<ProfileController> {
  const _ProfileOptionListSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProfileOptionTile(
          icon: Icons.storefront_outlined,
          title: 'Salon Details',
          subtitle: 'Manage your branding and contact info',
          onTap: controller.onSalonDetailsTap,
        ),
        const SizedBox(height: 12),
        _ProfileOptionTile(
          icon: Icons.access_time_outlined,
          title: 'Transaction Details',
          subtitle: 'View and manage your recent bookings and payment history.',
          onTap: controller.onTransactionDetailsTap,
        ),
        const SizedBox(height: 12),
        _ProfileOptionTile(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Payout Settings',
          subtitle: 'Bank details and revenue reports',
          onTap: controller.onPayoutSettingsTap,
        ),
        const SizedBox(height: 12),
        _ProfileOptionTile(
          icon: Icons.headphones_outlined,
          title: 'Help & Support',
          subtitle: 'Get assistance and read FAQs',
          onTap: controller.onHelpAndSupportTap,
        ),
      ],
    );
  }
}

/// Single Menu Option Card Widget (Stateless)
class _ProfileOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x04000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Icon Box
            Icon(icon, size: 24, color: const Color(0xFF374151)),
            const SizedBox(width: 16),

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF4B5563),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Right Arrow Action
            const Icon(
              Icons.arrow_forward_rounded,
              size: 20,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}

/// Log Out Button Widget (Stateless)
class _LogoutButtonWidget extends GetView<ProfileController> {
  const _LogoutButtonWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 240,
        height: 48,
        child: OutlinedButton(
          onPressed: controller.logout,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout_rounded,
                size: 18,
                color: Color(0xFF374151),
              ),
              const SizedBox(width: 8),
              Text(
                'Log Out',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color.fromARGB(255, 230, 69, 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Default Rectangular Logo Widget (Stateless)
class _DefaultRectangularLogo extends StatelessWidget {
  const _DefaultRectangularLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF041C16),
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.spa_rounded, size: 28, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              "Book'N'Glow",
              style: GoogleFonts.playfairDisplay(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFEFE0D3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
