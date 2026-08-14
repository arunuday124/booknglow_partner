import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import 'dashboard.dart';
import 'login.dart';
import 'registration.dart';

class SplashScreenView extends StatefulWidget {
  const SplashScreenView({super.key});

  @override
  State<SplashScreenView> createState() => _SplashScreenViewState();
}

class _SplashScreenViewState extends State<SplashScreenView>
    with TickerProviderStateMixin {
  late final AnimationController _lottieController;
  late final AnimationController _revealController;
  late final Animation<double> _revealAnimation;

  LottieComposition? _composition;
  Widget _targetScreen = const SalonOwnerLoginView();
  bool _isAuthChecked = false;
  bool _isAnimationFinished = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _lottieController = AnimationController(vsync: this);

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOut,
    );

    // 1. Preload Lottie so Animation and Text render simultaneously at the exact same instant
    _preloadLottieAndPlay();

    // 2. Perform Auth & Firestore check concurrently in the background
    _checkAuthAndRoute();

    // 3. Failsafe timer (maximum 5 seconds)
    Timer(const Duration(milliseconds: 5000), () {
      _isAnimationFinished = true;
      _proceedToNextScreen();
    });
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  Future<void> _preloadLottieAndPlay() async {
    try {
      final composition = await AssetLottie(
        'assets/videos/BookNGlow_Salon_Animation.lottie.json',
      ).load();

      if (mounted) {
        setState(() {
          _composition = composition;
          _lottieController.duration = composition.duration;
        });

        // Reveal Animation, Title, Badge, and Loader together simultaneously
        _revealController.forward();

        // Play the Lottie animation through its duration
        _lottieController.forward().whenComplete(() {
          _isAnimationFinished = true;
          _proceedToNextScreen();
        });
      }
    } catch (e) {
      debugPrint('[SplashScreen] Lottie preload notice: $e');
      if (mounted) {
        _revealController.forward();
        Timer(const Duration(milliseconds: 2000), () {
          _isAnimationFinished = true;
          _proceedToNextScreen();
        });
      }
    }
  }

  Future<void> _checkAuthAndRoute() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        final DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('salons')
            .doc(currentUser.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          _targetScreen = const DashboardView();
        } else {
          _targetScreen = const RegistrationView();
        }
      } else {
        _targetScreen = const SalonOwnerLoginView();
      }
    } catch (e) {
      debugPrint('[SplashScreen] Auth check error: $e');
      _targetScreen = const SalonOwnerLoginView();
    } finally {
      _isAuthChecked = true;
      _proceedToNextScreen();
    }
  }

  void _proceedToNextScreen() {
    if (_isAuthChecked && _isAnimationFinished && !_hasNavigated && mounted) {
      _hasNavigated = true;
      Get.offAll(
        () => _targetScreen,
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 600),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final animSize = (screenWidth * 0.88).clamp(320.0, 390.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _revealAnimation,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Preloaded Lottie Animation
                  SizedBox(
                    width: animSize,
                    height: animSize,
                    child: _composition != null
                        ? Lottie(
                            composition: _composition,
                            controller: _lottieController,
                            fit: BoxFit.contain,
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),

                  // App Title
                  Text(
                    "Book'N'Glow",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF041C16),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Partner Portal Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF041C16).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF041C16).withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'PARTNER PORTAL',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        color: const Color(0xFF041C16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Subtle Loading Spinner
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF041C16).withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
