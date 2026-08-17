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

      // Staff access is an explicit approval, not simply a role selected in
      // the UI. Rejected staff sessions are signed out before the message is
      // shown so AuthWrapper cannot redirect them into the staff workspace.
      if (selectedRole == 'staff' && !doc.exists) {
        await _auth.signOut();
        _showSnackBar(
          context,
          'This staff account has been deactivated by the administrator.',
          Colors.redAccent,
        );
        return;
      }

      if (!doc.exists) {
        _showSnackBar(context, "User role not found in database!", Colors.red);
        return;
      }

      // ✅ Safe casting Firestore data
      final data = doc.data() != null
          ? Map<String, dynamic>.from(doc.data()!)
          : <String, dynamic>{};

      final role = data['role'] as String?;

      if (selectedRole == 'staff' && role != 'staff') {
        await _auth.signOut();
        _showSnackBar(
          context,
          'This staff account has been deactivated by the administrator.',
          Colors.redAccent,
        );
        return;
      }

      if (role == null || (role != 'admin' && role != 'staff')) {
        _showSnackBar(context, "Invalid role assigned to user!", Colors.orange);
        return;
      }

      if (role != selectedRole) {
        _showSnackBar(
            context, "Role mismatch! Select correct role.", Colors.deepOrange);
        return;
      }

      if (role == 'staff') {
        final staffDoc = await _firestore.collection('staff').doc(uid).get();
        // Accounts created before staff management did not have a staff
        // approval document. Keep those existing staff accounts working
        // unless an administrator has explicitly marked them inactive.
        final isActive = data['status'] != 'inactive' &&
            (!staffDoc.exists || staffDoc.data()?['status'] == 'active');
        if (!isActive) {
          await _auth.signOut();
          _showSnackBar(
            context,
            'This staff account has been deactivated by the administrator.',
            Colors.redAccent,
          );
          return;
        }
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
    } on FirebaseAuthException catch (error) {
      _removeOverlaySafe(overlay);
      _showSnackBar(
        context,
        selectedRole == 'staff' && error.code == 'user-disabled'
            ? 'This staff account has been deactivated by the administrator.'
            : "Unable to sign in. Check your details and try again.",
        Colors.redAccent,
      );
    } catch (_) {
      _removeOverlaySafe(overlay);
      _showSnackBar(
          context, "Something went wrong. Please try again.", Colors.redAccent);
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
    } catch (_) {
      _showSnackBar(
          context, "Logout failed. Please try again.", Colors.redAccent);
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
