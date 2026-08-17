import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/imagebb_service.dart';

class PatientPhotoPage extends StatefulWidget {
  final String patientId;

  const PatientPhotoPage({
    super.key,
    required this.patientId,
  });

  @override
  State<PatientPhotoPage> createState() => _PatientPhotoPageState();
}

class _PatientPhotoPageState extends State<PatientPhotoPage> {
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  String? _imageName;

  bool _isUploading = false;

  // ------------------------------------------------------------
  // PICK IMAGE FROM GALLERY
  // ------------------------------------------------------------
  Future<void> _pickFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();

      if (!mounted) return;

      setState(() {
        _imageBytes = bytes;
        _imageName = pickedFile.name;
      });

      _showSnackBar(
        'Image selected successfully',
        success: true,
      );
    } catch (e) {
      debugPrint('Gallery image selection failed: $e');

      if (!mounted) return;

      _showSnackBar(
        'Failed to select image',
      );
    }
  }

  // ------------------------------------------------------------
  // PICK IMAGE FROM CAMERA
  // ------------------------------------------------------------
  Future<void> _pickFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();

      if (!mounted) return;

      setState(() {
        _imageBytes = bytes;
        _imageName = pickedFile.name;
      });

      _showSnackBar(
        'Photo captured successfully',
        success: true,
      );
    } catch (e) {
      debugPrint('Camera image selection failed: $e');

      if (!mounted) return;

      _showSnackBar(
        'Camera is not available on this device',
      );
    }
  }

  // ------------------------------------------------------------
  // UPLOAD IMAGE TO IMAGEBB
  // ------------------------------------------------------------
  Future<void> _uploadImage() async {
    if (_imageBytes == null) {
      _showSnackBar('Please select a photo first');
      return;
    }

    if (_isUploading) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final String? imageUrl = await ImageBBService.uploadImageBytes(
        _imageBytes!,
        name: _imageName,
      );

      if (!mounted) return;

      if (imageUrl == null || imageUrl.isEmpty) {
        _showSnackBar(
          'Image upload failed. Please try again.',
        );
        return;
      }

      // --------------------------------------------------------
      // SAVE IMAGE URL TO FIRESTORE
      // --------------------------------------------------------
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .update({
        'imageUrl': imageUrl,
      });

      if (!mounted) return;

      setState(() {
        _imageBytes = null;
        _imageName = null;
      });

      _showSnackBar(
        'Patient photo uploaded successfully',
        success: true,
      );

      // Tell the details page to reload its existing Firestore document.
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Patient image upload failed: $e');

      if (!mounted) return;

      _showSnackBar(
        'Image upload failed. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // REMOVE SELECTED IMAGE
  // ------------------------------------------------------------
  void _removeSelectedImage() {
    setState(() {
      _imageBytes = null;
      _imageName = null;
    });
  }

  // ------------------------------------------------------------
  // SNACKBAR
  // ------------------------------------------------------------
  void _showSnackBar(
    String message, {
    bool success = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle_outline : Icons.error_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: success ? Colors.green : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ------------------------------------------------------------
  // IMAGE PREVIEW
  // ------------------------------------------------------------
  Widget _buildImagePreview() {
    if (_imageBytes == null) {
      return Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Icon(
          Icons.person_outline,
          size: 100,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.memory(
            _imageBytes!,
            width: 220,
            height: 220,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _isUploading ? null : _removeSelectedImage,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Patient Photo',
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // TITLE
                  const Text(
                    'Upload Patient Photo',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Select a photo from your device or take a new photo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // IMAGE PREVIEW
                  _buildImagePreview(),

                  if (_imageName != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _imageName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),

                  // UPLOAD PROGRESS
                  if (_isUploading) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text(
                      'Uploading photo...',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  // BUTTONS
                  if (!_isUploading) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(
                          Icons.photo_library_outlined,
                        ),
                        label: const Text(
                          'Pick from Gallery',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _pickFromCamera,
                        icon: const Icon(
                          Icons.camera_alt_outlined,
                        ),
                        label: const Text(
                          'Take a Photo',
                        ),
                      ),
                    ),
                    if (_imageBytes != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _uploadImage,
                          icon: const Icon(
                            Icons.cloud_upload_outlined,
                          ),
                          label: const Text(
                            'Upload Photo',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 20),

                  Text(
                    'Patient ID is securely linked to this photo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
