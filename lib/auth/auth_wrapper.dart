import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import your dashboards and login page
import '../dashboard/admin_dashboard.dart';
import '../dashboard/staff_dashboard.dart';
import 'login_page.dart';

/// 🔹 AuthWrapper
/// Checks Firebase auth state and navigates users based on role.
class AuthWrapper extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const AuthWrapper({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 🔄 Loading auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        // ❌ User not logged in
        if (!snapshot.hasData || snapshot.data == null) {
          return LoginPage(
            isDarkMode: isDarkMode,
            onThemeToggle: onThemeToggle,
          );
        }

        // ✅ User logged in, check role
        return _RoleBasedRedirect(
          uid: snapshot.data!.uid,
          isDarkMode: isDarkMode,
          onThemeToggle: onThemeToggle,
        );
      },
    );
  }
}

/// 🔹 Role-based redirection
class _RoleBasedRedirect extends StatelessWidget {
  final String uid;
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const _RoleBasedRedirect({
    super.key,
    required this.uid,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const _ErrorScreen(
              message: "User data not found in Firestore");
        }

        // Safe type casting
        final data = snapshot.data!.data() ?? {};
        final role = data['role'] as String?;

        if (role == null) {
          return const _ErrorScreen(message: "User role not assigned");
        }

        // Navigate based on role
        switch (role) {
          case 'admin':
            return AdminDashboardPro(
              isDarkMode: isDarkMode,
              onThemeToggle: onThemeToggle,
            );
          case 'staff':
            return StaffDashboardPro(
              isDarkMode: isDarkMode,
              onThemeToggle: onThemeToggle,
            );
          default:
            return const _ErrorScreen(message: "Invalid user role");
        }
      },
    );
  }
}

/// 🔹 Loading screen
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// 🔹 Error screen
class _ErrorScreen extends StatelessWidget {
  final String message;

  const _ErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.red),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
