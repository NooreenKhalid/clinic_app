import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/imagebb_service.dart'; // ✅ ImageBB service

class PatientPhotoPage extends StatefulWidget {
  final String patientId; // Firestore document ID
  const PatientPhotoPage({super.key, required this.patientId});

  @override
  State<PatientPhotoPage> createState() => _PatientPhotoPageState();
}

class _PatientPhotoPageState extends State<PatientPhotoPage> {
  Uint8List? _imageBytes; // Changed from File to Uint8List
  String? _imageName; // Store image name
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  Future<void> _pickFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = pickedFile.name;
        });
      }
    } catch (e) {
      debugPrint("Gallery pick failed: $e");
      _showSnackBar("Failed to pick image from gallery");
    }
  }

  // Pick image from camera
  Future<void> _pickFromCamera() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = pickedFile.name;
        });
      }
    } catch (e) {
      debugPrint("Camera pick failed: $e");
      _showSnackBar("Failed to take photo");
    }
  }

  // Upload image to ImageBB and save URL in Firestore
  Future<void> _uploadImage() async {
    if (_imageBytes == null) {
      _showSnackBar("No image selected");
      return;
    }

    setState(() => _isUploading = true);

    try {
      final imageUrl = await ImageBBService.uploadImageBytes(
        _imageBytes!,
        name: _imageName,
      );

      if (imageUrl == null) {
        _showSnackBar("Image upload failed");
        return;
      }

      // Save URL to Firestore
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .update({'imageUrl': imageUrl});

      _showSnackBar("Image uploaded successfully", success: true);
      setState(() {
        _imageBytes = null;
        _imageName = null;
      });
    } catch (e) {
      debugPrint("Upload error: $e");
      _showSnackBar("Upload failed: $e");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: success ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Patient Photo'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Display selected image or placeholder
              _imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _imageBytes!,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.person, size: 100, color: Colors.grey),
              const SizedBox(height: 20),

              // Upload indicator
              if (_isUploading) const CircularProgressIndicator(),

              if (!_isUploading)
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text("Pick from Gallery"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _pickFromCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Take a Photo"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_imageBytes != null)
                      ElevatedButton.icon(
                        onPressed: _uploadImage,
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text("Upload to ImageBB"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
