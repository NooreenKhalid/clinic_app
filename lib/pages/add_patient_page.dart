import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/imagebb_service.dart';
import 'view_all_patients_page.dart';
import '../core/app_ui.dart';

class AddPatientPage extends StatefulWidget {
  const AddPatientPage({super.key});

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController nameC = TextEditingController();
  final TextEditingController ageC = TextEditingController();
  final TextEditingController addressC = TextEditingController();
  final TextEditingController surgeryC = TextEditingController();
  final TextEditingController diseaseC = TextEditingController();
  final TextEditingController historyC = TextEditingController();
  final TextEditingController emailC = TextEditingController();
  final TextEditingController phoneC = TextEditingController();

  String selectedGender = "Male";
  XFile? _image;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  bool adding = false;

  // --- Generate Patient ID ---
  Future<String> generatePatientId() async {
    final snap = await _firestore
        .collection('patients')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return 'P001';

    final last = snap.docs.first.data()['patientId'] ?? 'P000';
    final num = int.tryParse(last.substring(1)) ?? 0;

    return 'P${(num + 1).toString().padLeft(3, '0')}';
  }

  // --- Pick Image ---
  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (picked != null) {
      final bytes = await picked.readAsBytes();

      setState(() {
        _image = picked;
        _imageBytes = bytes;
      });
    }
  }

  // --- Upload Image ---
  Future<String?> _uploadImage() async {
    if (_imageBytes != null) {
      return await ImageBBService.uploadImageBytes(
        _imageBytes!,
        name: nameC.text.isNotEmpty ? nameC.text : null,
      );
    }

    return null;
  }

  // --- Add Patient ---
  Future<void> addPatient() async {
    if (nameC.text.isEmpty ||
        ageC.text.isEmpty ||
        diseaseC.text.isEmpty ||
        phoneC.text.isEmpty) {
      _showMsg("Name, Age, Disease & Phone are required", false);
      return;
    }

    setState(() => adding = true);

    try {
      final patientId = await generatePatientId();
      final imageUrl = await _uploadImage();

      await _firestore.collection('patients').doc(patientId).set({
        'patientId': patientId,
        'name': nameC.text.trim(),
        'age': int.tryParse(ageC.text) ?? 0,
        'gender': selectedGender,
        'address': addressC.text.trim(),
        'disease': diseaseC.text.trim(),
        'history': historyC.text.trim(),
        'surgery': surgeryC.text.trim(),
        'email': emailC.text.trim(),
        'phone': phoneC.text.trim(),
        'image_urls': imageUrl != null ? [imageUrl] : [],
        'createdBy': _auth.currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showMsg("Patient Added Successfully ($patientId)", true);

      // Clear fields
      nameC.clear();
      ageC.clear();
      addressC.clear();
      surgeryC.clear();
      diseaseC.clear();
      historyC.clear();
      emailC.clear();
      phoneC.clear();

      setState(() {
        _image = null;
        _imageBytes = null;
      });

      // Navigate to ViewAllPatientsPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ViewAllPatientsPage(),
        ),
      );
    } catch (e) {
      debugPrint('Add patient failed: $e');
      _showMsg("Something went wrong. Please try again.", false);
    } finally {
      setState(() => adding = false);
    }
  }

  // --- Show SnackBar ---
  void _showMsg(String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: ok ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // --- Theme-aware input decoration ---
  InputDecoration _dec(String label) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: "Enter $label",
      labelStyle: TextStyle(
        color: colors.onSurfaceVariant,
      ),
      hintStyle: GoogleFonts.poppins(
        color: colors.onSurfaceVariant,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colors.outline,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colors.outline,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colors.primary,
          width: 1.4,
        ),
      ),
      filled: true,
      fillColor: theme.inputDecorationTheme.fillColor,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 20,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add Patient",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageIntro(
              title: 'New patient',
              subtitle: 'Create a complete and secure patient record.',
            ),
            TextField(
              controller: nameC,
              style: TextStyle(
                color: colors.onSurface,
              ),
              decoration: _dec("Patient Name"),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Flexible(
                  flex: 2,
                  child: TextField(
                    controller: ageC,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: colors.onSurface,
                    ),
                    decoration: _dec("Age"),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  flex: 3,
                  child: TextField(
                    controller: addressC,
                    style: TextStyle(
                      color: colors.onSurface,
                    ),
                    decoration: _dec("Address"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: selectedGender,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 16,
              ),
              decoration: _dec("Gender"),
              items: ["Male", "Female", "Other"]
                  .map(
                    (g) => DropdownMenuItem(
                      value: g,
                      child: Text(
                        g,
                        style: TextStyle(
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => selectedGender = val!),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: diseaseC,
              maxLines: 3,
              style: TextStyle(
                color: colors.onSurface,
              ),
              decoration: _dec("Disease / Condition"),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: historyC,
              maxLines: 3,
              style: TextStyle(
                color: colors.onSurface,
              ),
              decoration: _dec("Patient History"),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: surgeryC,
              maxLines: 2,
              style: TextStyle(
                color: colors.onSurface,
              ),
              decoration: _dec("Surgery / Procedure"),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailC,
              style: TextStyle(
                color: colors.onSurface,
              ),
              decoration: _dec("Email"),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: phoneC,
              style: TextStyle(
                color: colors.onSurface,
              ),
              decoration: _dec("Phone"),
            ),
            const SizedBox(height: 16),
            _imageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _imageBytes!,
                      height: 140,
                    ),
                  )
                : const Text("No image selected"),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pick(
                    ImageSource.gallery,
                  ),
                  icon: const Icon(Icons.photo),
                  label: const Text("Gallery"),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _pick(
                    ImageSource.camera,
                  ),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Camera"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: adding ? null : addPatient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: adding
                    ? CircularProgressIndicator(
                        color: colors.onPrimary,
                      )
                    : Text(
                        "Add Patient",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
