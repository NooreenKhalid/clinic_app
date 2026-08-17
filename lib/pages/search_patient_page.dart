import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_ui.dart';

class SearchPatientPage extends StatefulWidget {
  final bool? isDarkMode;

  const SearchPatientPage({super.key, this.isDarkMode});

  @override
  State<SearchPatientPage> createState() => _SearchPatientPageState();
}

class _SearchPatientPageState extends State<SearchPatientPage> {
  final _firestore = FirebaseFirestore.instance;
  final searchC = TextEditingController();

  bool loading = false;
  List<Map<String, dynamic>> patients = [];

  Future<void> searchPatient() async {
    final query = searchC.text.trim();
    if (query.isEmpty) {
      _showMsg("Please enter Name, ID, or Phone", false);
      return;
    }

    setState(() {
      loading = true;
      patients.clear();
    });

    try {
      QuerySnapshot<Map<String, dynamic>> snap;

      if (query.toUpperCase().startsWith('P')) {
        snap = await _firestore
            .collection('patients')
            .where('patientId', isEqualTo: query.toUpperCase())
            .get();
      } else if (RegExp(r'^[0-9]+$').hasMatch(query)) {
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
        _showMsg("No patient found", false);
      } else {
        patients = snap.docs.map((d) {
          final data = d.data();
          data['docId'] = d.id;
          return data;
        }).toList();
        setState(() {});
      }
    } catch (e) {
      _showMsg("Error: $e", false);
    } finally {
      setState(() => loading = false);
    }
  }

  void _showMsg(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: success ? Colors.green : Colors.redAccent,
    ));
  }

  Widget _patientCard(Map<String, dynamic> data) {
    final List<String> images = List<String>.from(data['image_urls'] ?? []);
    final imageUrl = images.isNotEmpty ? images.first : '';
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PatientDetailPage(patientData: data, isDarkMode: isDark),
            ),
          );
        },
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: colors.primary,
          backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
          child: imageUrl.isEmpty
              ? Text(
                  (data['name'] ?? 'P')[0],
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Text(
          data['name'] ?? 'No Name',
          style:
              TextStyle(fontWeight: FontWeight.bold, color: colors.onSurface),
        ),
        subtitle: Text(
          "ID: ${data['patientId']} | Age: ${data['age']} | Disease: ${data['disease']}",
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
        ),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 16, color: colors.onSurfaceVariant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Patient"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          children: [
            const PageIntro(
                title: 'Find a patient',
                subtitle:
                    'Search records by name, patient ID, or phone number.'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchC,
                        style: TextStyle(color: colors.onSurface),
                        decoration: InputDecoration(
                          hintText: "Search by Name, Patient ID or Phone",
                          hintStyle: TextStyle(color: colors.onSurfaceVariant),
                          prefixIcon: Icon(Icons.search, color: colors.primary),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                          filled: true,
                          fillColor: theme.inputDecorationTheme.fillColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: loading ? null : searchPatient,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: loading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: colors.onPrimary))
                            : const Text(
                                "Search",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: patients.isEmpty
                  ? Center(
                      child: Text(
                        "No data",
                        style: TextStyle(
                            color: colors.onSurfaceVariant, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: patients.length,
                      itemBuilder: (_, i) => _patientCard(patients[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// --- Patient Detail Page ---
class PatientDetailPage extends StatelessWidget {
  final Map<String, dynamic> patientData;
  final bool isDarkMode;

  const PatientDetailPage(
      {super.key, required this.patientData, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final List<String> images =
        List<String>.from(patientData['image_urls'] ?? []);
    return Scaffold(
      appBar: AppBar(
        title: Text(patientData['name'] ?? "Patient Detail"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            images.isNotEmpty
                ? SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(images[i],
                            width: 150, fit: BoxFit.cover),
                      ),
                    ),
                  )
                : const Text("No Images Available"),
            const SizedBox(height: 16),
            Text("Patient ID: ${patientData['patientId'] ?? ''}",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text("Age: ${patientData['age'] ?? ''}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("Gender: ${patientData['gender'] ?? ''}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("Disease: ${patientData['disease'] ?? ''}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("History: ${patientData['history'] ?? ''}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("Surgery: ${patientData['surgery'] ?? ''}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("Address: ${patientData['address'] ?? ''}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("Email: ${patientData['email'] ?? ''}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("Phone: ${patientData['phone'] ?? ''}",
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
