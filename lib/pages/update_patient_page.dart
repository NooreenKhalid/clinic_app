import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/imagebb_service.dart';

class UpdatePatientPage extends StatefulWidget {
  const UpdatePatientPage({super.key});

  @override
  State<UpdatePatientPage> createState() => _UpdatePatientPageState();
}

class _UpdatePatientPageState extends State<UpdatePatientPage> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController diseaseController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  bool loading = false;
  String? selectedPatientId;

  List<Uint8List> _newImageBytes = [];
  List<String> _existingImages = [];
  List<Map<String, dynamic>> searchResults = [];

  // --- Search Patients ---
  Future<void> searchPatient() async {
    final query = searchController.text.trim();
    final phone = phoneController.text.trim();

    if (query.isEmpty && phone.isEmpty) {
      _showMsg("Enter Patient ID or Name (with Phone)", false);
      return;
    }

    setState(() {
      loading = true;
      searchResults.clear();
      selectedPatientId = null;
      _newImageBytes.clear();
      _existingImages.clear();
    });

    try {
      List<Map<String, dynamic>> results = [];

      // Search by ID
      if (query.isNotEmpty && query.toUpperCase().startsWith('P')) {
        final doc = await _firestore.collection('patients').doc(query).get();
        if (doc.exists) {
          final data = doc.data()!;
          data['docId'] = doc.id;
          results.add(data);
        }
      }

      // Search by Name + optional phone
      if (results.isEmpty && query.isNotEmpty) {
        Query<Map<String, dynamic>> queryRef =
            _firestore.collection('patients').where('name', isEqualTo: query);
        if (phone.isNotEmpty)
          queryRef = queryRef.where('phone', isEqualTo: phone);
        final snap = await queryRef.get();
        if (snap.docs.isNotEmpty) {
          results = snap.docs.map((d) {
            final data = d.data();
            data['docId'] = d.id;
            return data;
          }).toList();
        }
      }

      if (results.isEmpty) {
        _showMsg("No patients found", false);
      } else {
        setState(() => searchResults = results);
      }
    } catch (e) {
      _showMsg("Error: $e", false);
    } finally {
      setState(() => loading = false);
    }
  }

  // --- Select Patient ---
  void selectPatient(Map<String, dynamic> patient) {
    selectedPatientId = patient['docId'];
    nameController.text = patient['name'] ?? '';
    ageController.text = (patient['age'] ?? '').toString();
    diseaseController.text = patient['disease'] ?? '';
    _existingImages = patient['image_urls'] != null
        ? List<String>.from(patient['image_urls'])
        : [];
    _newImageBytes.clear();
    setState(() {});
  }

  // --- Pick Image ---
  Future<void> _pick(ImageSource source) async {
    if (source == ImageSource.gallery) {
      final pickedFiles = await _picker.pickMultiImage(imageQuality: 80);
      if (pickedFiles != null) {
        for (var file in pickedFiles) {
          final bytes = await file.readAsBytes();
          setState(() => _newImageBytes.add(bytes));
        }
      }
    } else {
      final file = await _picker.pickImage(source: source, imageQuality: 80);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() => _newImageBytes.add(bytes));
      }
    }
  }

  // --- Upload Images ---
  Future<List<String>> _uploadNewImages() async {
    List<String> urls = [];
    for (Uint8List bytes in _newImageBytes) {
      final url = await ImageBBService.uploadImageBytes(bytes);
      if (url != null) urls.add(url);
    }
    return urls;
  }

  // --- Update Patient ---
  Future<void> updatePatient() async {
    if (selectedPatientId == null) return;

    final name = nameController.text.trim();
    final age = int.tryParse(ageController.text.trim());
    final disease = diseaseController.text.trim();

    if (name.isEmpty || age == null || disease.isEmpty) {
      _showMsg("All fields are required and age must be number", false);
      return;
    }

    setState(() => loading = true);

    try {
      final newUrls = await _uploadNewImages();
      final allImages = [..._existingImages, ...newUrls];

      await _firestore.collection('patients').doc(selectedPatientId).update({
        'name': name,
        'age': age,
        'disease': disease,
        'image_urls': allImages,
      });

      _showMsg("Patient updated successfully!", true);

      setState(() {
        selectedPatientId = null;
        searchResults.clear();
        _existingImages.clear();
        _newImageBytes.clear();
        searchController.clear();
        phoneController.clear();
        nameController.clear();
        ageController.clear();
        diseaseController.clear();
      });
    } catch (e) {
      _showMsg("Error: $e", false);
    } finally {
      setState(() => loading = false);
    }
  }

  void _showMsg(String text, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: success ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          hintText: "Enter $label",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  Widget _imageGrid() {
    final List<Widget> allImages = [
      ..._existingImages.map((url) => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(url, fit: BoxFit.cover),
          )),
      ..._newImageBytes.map((bytes) => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(bytes, fit: BoxFit.cover),
          )),
    ];
    if (allImages.isEmpty) return const Text("No images selected");
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allImages.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemBuilder: (_, i) => allImages[i],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Update Patient"), backgroundColor: Colors.orange),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _field(searchController, "Patient ID or Name"),
            _field(phoneController, "Phone Number (if Name used)"),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: loading ? null : searchPatient,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Search Patients"),
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: searchResults
                  .map((p) => ListTile(
                        title: Text(p['name'] ?? ''),
                        subtitle:
                            Text("ID: ${p['patientId']} | Age: ${p['age']}"),
                        trailing: ElevatedButton(
                          onPressed: () => selectPatient(p),
                          child: const Text("Select"),
                        ),
                      ))
                  .toList(),
            ),
            if (selectedPatientId != null) ...[
              _field(nameController, "Patient Name"),
              _field(ageController, "Age", number: true),
              _field(diseaseController, "Disease"),
              const SizedBox(height: 12),
              _imageGrid(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Gallery"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Camera"),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: loading ? null : updatePatient,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Update Patient"),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
