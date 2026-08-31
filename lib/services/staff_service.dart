import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class StaffService {
  StaffService._();

  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  static const String _workerUrl =
      'https://cloudflare-worker.smart-clinic.workers.dev';

  static Stream<QuerySnapshot<Map<String, dynamic>>> activeStaff() {
    return firestore
        .collection('staff')
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  /// Existing Firebase users that can be approved as staff.
  /// Admin users are excluded in the UI.
  static Stream<QuerySnapshot<Map<String, dynamic>>> registeredUsers() {
    return firestore.collection('users').snapshots();
  }

  static Future<String> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in as an administrator.',
      );
    }

    final token = await user.getIdToken(true);

    if (token == null || token.isEmpty) {
      throw Exception(
        'Unable to get Firebase authentication token.',
      );
    }

    return token;
  }

  static Future<void> createStaff({
    required String name,
    required int age,
    required String occupation,
    required String email,
    required String password,
    required String profileImageUrl,
  }) async {
    final idToken = await _getIdToken();

    final response = await http.post(
      Uri.parse('$_workerUrl/createStaffMember'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'name': name.trim(),
        'age': age,
        'occupation': occupation.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'profileImageUrl': profileImageUrl.trim(),
      }),
    );

    _checkResponse(response, 'Unable to create staff account.');
  }

  /// Approves an account that already exists in Firebase Authentication.
  /// No new Auth account is created and no password is required.
  static Future<void> approveExistingStaff({
    required String uid,
    required String name,
    required int age,
    required String occupation,
    required String profileImageUrl,
  }) async {
    final idToken = await _getIdToken();

    final response = await http.post(
      Uri.parse('$_workerUrl/approveExistingStaff'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'uid': uid,
        'name': name.trim(),
        'age': age,
        'occupation': occupation.trim(),
        'profileImageUrl': profileImageUrl.trim(),
      }),
    );

    _checkResponse(response, 'Unable to approve existing staff account.');
  }

  static Future<void> deactivateStaff(String uid) async {
    final idToken = await _getIdToken();

    final response = await http.post(
      Uri.parse('$_workerUrl/deactivateStaffMember'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'uid': uid,
      }),
    );

    _checkResponse(response, 'Unable to remove staff member.');
  }

  static void _checkResponse(http.Response response, String fallback) {
    Map<String, dynamic>? data;

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    } catch (_) {}

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data?['error']?.toString() ??
          (response.body.trim().isNotEmpty ? response.body.trim() : fallback);
      throw Exception(message);
    }

    if (data?['success'] != true) {
      throw Exception(data?['error']?.toString() ?? fallback);
    }
  }
}
