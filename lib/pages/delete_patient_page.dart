import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_ui.dart';

class DeletePatientPage extends StatefulWidget {
  const DeletePatientPage({super.key});

  @override
  State<DeletePatientPage> createState() => _DeletePatientPageState();
}

class _DeletePatientPageState extends State<DeletePatientPage> {
  final TextEditingController searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool loading = false;
  String searchBy = 'id'; // id | name | phone
  List<QueryDocumentSnapshot<Map<String, dynamic>>> results = [];
  String? selectedPatientId;

  /// 🔍 Search Patients
  Future<void> searchPatients() async {
    final query = searchController.text.trim();
    if (query.isEmpty) {
      _showSnackBar("Please enter ID, Name, or Phone", Colors.orange);
      return;
    }

    setState(() {
      loading = true;
      results.clear();
      selectedPatientId = null;
    });

    try {
      QuerySnapshot<Map<String, dynamic>> snap;

      if (searchBy == 'id') {
        snap = await _firestore
            .collection('patients')
            .where('patientId', isEqualTo: query.toUpperCase())
            .get();
      } else if (searchBy == 'phone') {
        snap = await _firestore
            .collection('patients')
            .where('phone', isEqualTo: query)
            .get();
      } else {
        snap = await _firestore
            .collection('patients')
            .where('name', isEqualTo: query)
            .get();
      }

      if (snap.docs.isEmpty) {
        _showSnackBar("No patient found", Colors.redAccent);
      } else {
        setState(() => results = snap.docs);
      }
    } catch (e) {
      _showSnackBar("Error: $e", Colors.redAccent);
    } finally {
      setState(() => loading = false);
    }
  }

  /// 🗑️ Delete Patient
  Future<void> deletePatient() async {
    if (selectedPatientId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          "Confirm Delete",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to permanently delete this patient?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => loading = true);

    try {
      await _firestore.collection('patients').doc(selectedPatientId).delete();
      _showSnackBar("Patient deleted successfully", Colors.green);
      results.clear();
      selectedPatientId = null;
      searchController.clear();

      // Navigate back or refresh page after deletion
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pop(context); // Go back to previous page
      });
    } catch (e) {
      _showSnackBar("Delete failed: $e", Colors.redAccent);
    } finally {
      setState(() => loading = false);
    }
  }

  void _showSnackBar(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _patientTile(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final isSelected = selectedPatientId == doc.id;

    Widget row(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(
                "$label:",
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            Expanded(
              child: Text(value, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
      );
    }

    Widget avatarImage() {
      final List<String> images = List<String>.from(data['image_urls'] ?? []);
      if (images.isNotEmpty) {
        return CircleAvatar(
            radius: 28,
            backgroundColor: Colors.transparent,
            backgroundImage: NetworkImage(images.first));
      }
      return CircleAvatar(
        radius: 28,
        backgroundColor: isSelected ? Colors.red : Colors.teal,
        child: Text(
          (data['name'] ?? 'P')[0].toUpperCase(),
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Card(
      elevation: isSelected ? 6 : 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => selectedPatientId = doc.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatarImage(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['name'] ?? '',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    row("ID", data['patientId'] ?? 'NA'),
                    row("Phone", data['phone'] ?? 'NA'),
                    row("Age", data['age']?.toString() ?? 'NA'),
                    row("Disease", data['disease'] ?? 'NA'),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle,
                    color: Colors.redAccent, size: 26),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchFilters(String label, String value) {
    final colors = Theme.of(context).colorScheme;
    final selected = searchBy == value;
    return ChoiceChip(
      label: Text(label,
          style:
              TextStyle(color: selected ? colors.onError : colors.onSurface)),
      selected: selected,
      selectedColor: colors.error,
      backgroundColor: colors.surface,
      onSelected: (_) => setState(() => searchBy = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Delete Patient"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          children: [
            const PageIntro(
                title: 'Delete patient',
                subtitle:
                    'Search, review, then permanently remove a selected record.'),
            // 🔍 Search Section
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: "Search Patient",
                        hintText: "Enter ID / Name / Phone",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      children: [
                        _searchFilters("ID", 'id'),
                        _searchFilters("Name", 'name'),
                        _searchFilters("Phone", 'phone'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: loading ? null : searchPatients,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor:
                              Theme.of(context).colorScheme.onError,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: loading
                            ? CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.onError,
                              )
                            : const Text(
                                "Search",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🧾 Search Results
            if (results.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (_, i) => _patientTile(results[i]),
                ),
              ),

            // 🗑️ Delete Button
            if (selectedPatientId != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text("Delete Selected Patient",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: loading ? null : deletePatient,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
