import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import your dashboard pages
import '../dashboard/admin_dashboard.dart';
import '../dashboard/staff_dashboard.dart';
import '../auth/login_page.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ------------------ LOGIN ------------------
  static Future<void> login(
    BuildContext context,
    String email,
    String password,
    String selectedRole, {
    required bool isDarkMode,
    required VoidCallback onThemeToggle,
  }) async {
    OverlayEntry? overlay;

    // Show loading overlay
    overlay = OverlayEntry(
      builder: (_) => Container(
        color: Colors.black.withOpacity(0.5),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 4),
        ),
      ),
    );
    Overlay.of(context)?.insert(overlay);

    try {
      // Firebase authentication
      final userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCred.user?.uid;
      if (uid == null) {
        _removeOverlaySafe(overlay);
        _showSnackBar(context, "User UID not found", Colors.redAccent);
        return;
      }

      // Fetch user role from Firestore
      final doc = await _firestore.collection('users').doc(uid).get();
      _removeOverlaySafe(overlay);

      if (!doc.exists) {
        _showSnackBar(context, "User role not found in database!", Colors.red);
        return;
      }

      // ✅ Safe casting Firestore data
      final data = doc.data() != null
          ? Map<String, dynamic>.from(doc.data()!)
          : <String, dynamic>{};

      final role = data['role'] as String?;

      if (role == null || (role != 'admin' && role != 'staff')) {
        _showSnackBar(context, "Invalid role assigned to user!", Colors.orange);
        return;
      }

      if (role != selectedRole) {
        _showSnackBar(
            context, "Role mismatch! Select correct role.", Colors.deepOrange);
        return;
      }

      // Navigate based on role with dark mode support
      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDashboardPro(
              isDarkMode: isDarkMode,
              onThemeToggle: onThemeToggle,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StaffDashboardPro(
              isDarkMode: isDarkMode,
              onThemeToggle: onThemeToggle,
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      _removeOverlaySafe(overlay);
      _showSnackBar(
        context,
        "Login failed: ${e.message ?? e.code}",
        Colors.redAccent,
      );
    } catch (e) {
      _removeOverlaySafe(overlay);
      _showSnackBar(context, "Unexpected error: $e", Colors.redAccent);
    }
  }

  /// ------------------ LOGOUT ------------------
  static Future<void> logout(
    BuildContext context, {
    required bool isDarkMode,
    required VoidCallback onThemeToggle,
  }) async {
    try {
      await _auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPage(
            isDarkMode: isDarkMode,
            onThemeToggle: onThemeToggle,
          ),
        ),
      );
      _showSnackBar(context, "Logged out successfully", Colors.green);
    } catch (e) {
      _showSnackBar(context, "Logout failed: $e", Colors.redAccent);
    }
  }

  /// ------------------ Helper: Safe Overlay Removal ------------------
  static void _removeOverlaySafe(OverlayEntry? overlay) {
    try {
      overlay?.remove();
    } catch (_) {}
  }

  /// ------------------ Helper: SnackBar ------------------
  static void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
