import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controller/auth_controller.dart';

/// Main Salon Owner Login Page built using GetView (StatelessWidget)
class SalonOwnerLoginView extends GetView<AuthController> {
  const SalonOwnerLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject AuthController using Get.put if not already injected
    Get.put(AuthController());

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  _HeaderSection(),
                  SizedBox(height: 36),
                  _LoginCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Header Section containing Logo circle, App Title, and Subtitle
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top White Circle Logo Container
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // App Name Title
        Text(
          "Book'N'Glow",
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF041C16),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
        // App Tagline / Description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Sophisticated management for modern beauty professionals.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF4B5563),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// Login Card Widget containing login options and footer links
class _LoginCard extends GetView<AuthController> {
  const _LoginCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Card Title
          Text(
            'Salon Owner Login',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF041C16),
            ),
          ),
          const SizedBox(height: 8),
          // Card Subtitle
          Text(
            'Welcome back. Please select an option to continue.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF4B5563),
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 28),

          // Google Sign In Button
          Obx(() => _SocialLoginButton(
                text: 'Continue with Google',
                textColor: const Color(0xFF1F2937),
                backgroundColor: Colors.white,
                borderColor: const Color(0xFFD1D5DB),
                iconWidget: Image.asset(
                  'assets/images/google.png',
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                ),
                isLoading: controller.isLoadingGoogle.value,
                onPressed: controller.loginWithGoogle,
              )),
          const SizedBox(height: 14),

          // Apple Sign In Button
          Obx(() => _SocialLoginButton(
                text: 'Continue with Apple',
                textColor: Colors.white,
                backgroundColor: const Color(0xFF041C16),
                iconWidget: Image.asset(
                  'assets/images/icons8-apple-50.png',
                  width: 22,
                  height: 22,
                  color: Colors.white,
                  fit: BoxFit.contain,
                ),
                isLoading: controller.isLoadingApple.value,
                onPressed: controller.loginWithApple,
              )),
          const SizedBox(height: 28),

          // Authorized Access Note
          Text(
            'AUTHORIZED ACCESS ONLY',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),

          // Footer Action Links Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FooterLinkButton(
                title: 'Privacy Policy',
                onTap: controller.openPrivacyPolicy,
              ),
              const SizedBox(width: 28),
              _FooterLinkButton(
                title: 'Support',
                onTap: controller.openSupport,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom Reusable Social Login Button (Stateless)
class _SocialLoginButton extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color backgroundColor;
  final Color? borderColor;
  final Widget iconWidget;
  final bool isLoading;
  final VoidCallback onPressed;

  const _SocialLoginButton({
    required this.text,
    required this.textColor,
    required this.backgroundColor,
    this.borderColor,
    required this.iconWidget,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: borderColor != null
              ? BorderSide(color: borderColor!, width: 1.0)
              : BorderSide.none,
          shape: const StadiumBorder(),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconWidget,
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Footer Link Button Widget (Stateless)
class _FooterLinkButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _FooterLinkButton({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF5C5346),
        ),
      ),
    );
  }
}
