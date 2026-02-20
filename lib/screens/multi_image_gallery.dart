import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'full_screen_image_page.dart';

class MultiImageGalleryWeb extends StatefulWidget {
  const MultiImageGalleryWeb({super.key});

  @override
  _MultiImageGalleryWebState createState() => _MultiImageGalleryWebState();
}

class _MultiImageGalleryWebState extends State<MultiImageGalleryWeb> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> images = [];

  /// Pick multiple images
  Future<void> pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        images.addAll(pickedFiles);
      });
    }
  }

  /// Delete image
  void deleteImage(int index) {
    setState(() {
      images.removeAt(index);
    });
  }

  /// Open fullscreen
  void openFullscreen(int index) {
    final file = images[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImagePage(
          imageUrl: file.path,
          patientName: "Patient_${index + 1}",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Clinic Images (Web)"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: pickImages,
          ),
        ],
      ),
      body: images.isEmpty
          ? const Center(child: Text("No images uploaded"))
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: images.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final file = images[index];
                return Stack(
                  children: [
                    GestureDetector(
                      onTap: () => openFullscreen(index),
                      child: Image.network(file.path, fit: BoxFit.cover),
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteImage(index),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
