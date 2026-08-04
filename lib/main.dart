import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'firebase_options.dart';
import 'view/dashboard.dart';
import 'view/login.dart';
import 'view/registration.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "Book'N'Glow Partner",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF041C16),
          primary: const Color(0xFF041C16),
        ),
      ),
      home: const _InitialAuthWrapper(),
    );
  }
}

/// Initial Auth & Registration Check Wrapper (StatelessWidget)
class _InitialAuthWrapper extends StatelessWidget {
  const _InitialAuthWrapper();

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    // If user is not logged in, go to Login Screen
    if (currentUser == null) {
      return const SalonOwnerLoginView();
    }

    // If user is logged in, check if salon registration document exists in Firestore
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('salons')
          .doc(currentUser.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8F9F8),
          );
        }

        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          // Salon document exists -> Directly show Dashboard
          return const DashboardView();
        }

        // First-time user without salon record -> Show Registration View
        return const RegistrationView();
      },
    );
  }
}
