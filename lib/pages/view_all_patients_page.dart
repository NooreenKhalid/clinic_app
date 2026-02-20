import 'dart:typed_data';
import 'dart:html' as html; // Web download
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/imagebb_service.dart';

class ViewAllPatientsPage extends StatefulWidget {
  const ViewAllPatientsPage({super.key});

  @override
  State<ViewAllPatientsPage> createState() => _ViewAllPatientsPageState();
}

class _ViewAllPatientsPageState extends State<ViewAllPatientsPage> {
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Patients"),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('patients')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No patient records found"));
          }

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
                  color: Colors.white,
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
                    backgroundColor: Colors.teal,
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
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      "ID: $patientId\nAge: ${data['age'] ?? '-'}\nPhone: ${data['phone'] ?? 'NA'}",
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PatientDetailsPage(patientId: patientId),
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

  const PatientDetailsPage({super.key, required this.patientId});

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  final _firestore = FirebaseFirestore.instance;
  final _picker = ImagePicker();
  List<XFile> newImages = [];
  List<Uint8List> newImageBytes = [];
  bool uploading = false;

  // Pick images from gallery or camera
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
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

  // Upload images to Firestore via ImageBB
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      setState(() => uploading = false);
    }
  }

  // Web download image
  void downloadImage(String url, String fileName) {
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
  }

  // Delete image
  Future<void> deleteImage(String url) async {
    final docRef = _firestore.collection('patients').doc(widget.patientId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final urls = List<String>.from(doc['image_urls'] ?? []);
    urls.remove(url);
    await docRef.update({'image_urls': urls});
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Details"),
        backgroundColor: Colors.teal,
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
                _infoTile("Gender", data['gender']),
                _infoTile("Disease", data['disease']),
                _infoTile("History", data['history']),
                _infoTile("Surgery", data['surgery']),
                _infoTile("Email", data['email']),
                _infoTile("Phone", data['phone']),
                const SizedBox(height: 16),
                const Text("Patient Photos",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                // Existing images from Firestore
                _imageGallery(images),
                // Newly picked images before upload
                if (newImages.isNotEmpty)
                  _imageGallery(newImages
                      .map((e) =>
                          Image.memory(newImageBytes[newImages.indexOf(e)]))
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
                    onPressed: uploading ? null : uploadImages,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: uploading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Upload Images",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
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
      child:
          Text("$label: ${value ?? '-'}", style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _imageGallery(List<dynamic> images) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final img = images[i];
          final url = img is String ? img : null;

          return Stack(
            children: [
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      child: InteractiveViewer(
                        child: url != null ? Image.network(url) : img,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                      width: 160,
                      child: img is String
                          ? Image.network(url!, fit: BoxFit.cover)
                          : img),
                ),
              ),
              // Top-right buttons
              Positioned(
                top: 6,
                right: 6,
                child: Row(
                  children: [
                    if (url != null)
                      IconButton(
                        icon: const Icon(Icons.download, color: Colors.white),
                        onPressed: () =>
                            downloadImage(url, "patient_image_${i + 1}.jpg"),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => url != null
                          ? deleteImage(url)
                          : setState(() {
                              newImages.removeAt(i);
                              newImageBytes.removeAt(i);
                            }),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _actionButton(IconData icon, String text, VoidCallback onTap) {
    return Expanded(
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(text,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
      ),
    );
  }
}
