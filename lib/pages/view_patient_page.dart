import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/imagebb_service.dart'; // make sure this file exists

class ViewAllPatientsPage extends StatefulWidget {
  final bool? isDarkMode;
  final VoidCallback? onThemeToggle;

  const ViewAllPatientsPage({super.key, this.isDarkMode, this.onThemeToggle});

  @override
  State<ViewAllPatientsPage> createState() => _ViewAllPatientsPageState();
}

class _ViewAllPatientsPageState extends State<ViewAllPatientsPage> {
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Patients"),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        actions: [
          IconButton(
            icon: Icon(darkMode ? Icons.wb_sunny : Icons.dark_mode),
            onPressed: widget.onThemeToggle,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('patients')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return const Center(child: Text("No patient records found"));

          final patients = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final data = patients[index].data();
              final patientId = data['patientId'] ?? patients[index].id;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: colors.primary,
                    child: Text(
                      (data['name'] ?? 'P')[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    data['name'] ?? "No Name",
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: colors.onSurface),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      "ID: $patientId\nAge: ${data['age'] ?? '-'}\nPhone: ${data['phone'] ?? 'NA'}",
                      style: TextStyle(
                          fontSize: 13, color: colors.onSurfaceVariant),
                    ),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PatientDetailsPage(
                            patientId: patientId,
                            isDarkMode: darkMode,
                            onThemeToggle: widget.onThemeToggle,
                          ),
                        ),
                      );
                    },
                    child: const Text("View"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PatientDetailsPage extends StatefulWidget {
  final String patientId;
  final bool? isDarkMode;
  final VoidCallback? onThemeToggle;

  const PatientDetailsPage(
      {super.key,
      required this.patientId,
      this.isDarkMode,
      this.onThemeToggle});

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  final _firestore = FirebaseFirestore.instance;
  final _picker = ImagePicker();
  List<XFile> newImages = [];
  List<Uint8List> newImageBytes = [];
  bool uploading = false;

  Future<void> pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final files = await _picker.pickMultiImage(imageQuality: 80);
        if (files != null) {
          for (var f in files) {
            final bytes = await f.readAsBytes();
            newImages.add(f);
            newImageBytes.add(bytes);
          }
        }
      } else {
        final file = await _picker.pickImage(source: source, imageQuality: 80);
        if (file != null) {
          final bytes = await file.readAsBytes();
          newImages.add(file);
          newImageBytes.add(bytes);
        }
      }
      setState(() {});
    } catch (_) {
      debugPrint("Patient image selection failed.");
    }
  }

  Future<void> uploadImages() async {
    if (newImageBytes.isEmpty) return;

    setState(() => uploading = true);

    try {
      final docRef = _firestore.collection('patients').doc(widget.patientId);
      final doc = await docRef.get();
      List<String> urls = [];

      if (doc.exists && doc.data()!.containsKey('image_urls')) {
        urls = List<String>.from(doc['image_urls']);
      }

      for (Uint8List bytes in newImageBytes) {
        final url = await ImageBBService.uploadImageBytes(bytes);
        if (url != null) urls.add(url);
      }

      await docRef.update({'image_urls': urls});

      newImages.clear();
      newImageBytes.clear();
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Images uploaded successfully")),
      );
    } catch (_) {
      debugPrint("Patient image upload failed.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload failed")),
      );
    } finally {
      setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Details"),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        actions: [
          IconButton(
            icon: Icon(darkMode ? Icons.wb_sunny : Icons.dark_mode),
            onPressed: widget.onThemeToggle,
          )
        ],
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _firestore.collection('patients').doc(widget.patientId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          if (!snapshot.hasData ||
              snapshot.data == null ||
              !snapshot.data!.exists)
            return const Center(child: Text("Patient data not found"));

          final data = snapshot.data!.data()!;
          final images = List<String>.from(data['image_urls'] ?? []);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoTile("Name", data['name']),
                _infoTile("Age", data['age']),
                _infoTile("Disease", data['disease']),
                _infoTile("Phone", data['phone']),
                const SizedBox(height: 16),
                const Text("Patient Photos",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (images.isNotEmpty)
                  _imageList(images
                      .map((e) => Image.network(e, fit: BoxFit.cover))
                      .toList()),
                if (newImages.isNotEmpty)
                  _imageList(newImages
                      .map((e) => Image.memory(
                          newImageBytes[newImages.indexOf(e)],
                          fit: BoxFit.cover))
                      .toList()),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _actionButton(Icons.photo, "Gallery",
                        () => pickImage(ImageSource.gallery)),
                    const SizedBox(width: 12),
                    _actionButton(Icons.camera_alt, "Camera",
                        () => pickImage(ImageSource.camera)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: uploading ? null : uploadImages,
                    child: uploading
                        ? CircularProgressIndicator(color: colors.onPrimary)
                        : const Text("Upload Images",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoTile(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text("$label: ${value ?? '-'}",
          style: TextStyle(
              fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
    );
  }

  Widget _imageList(List<Widget> images) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(width: 160, child: images[i]),
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String text, VoidCallback onTap) {
    return Expanded(
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
      ),
    );
  }
}
