import 'package:flutter/material.dart';

class AdminActionsPage extends StatelessWidget {
  const AdminActionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Actions"),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navigate to Add Patient Page
                Navigator.pushNamed(context, '/add_patient');
              },
              child: const Text("Add New Patient"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // Navigate to Update Patient Page
                Navigator.pushNamed(context, '/update_patient');
              },
              child: const Text("Update Existing Patient"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // Navigate to Delete Patient Page
                Navigator.pushNamed(context, '/delete_patient');
              },
              child: const Text("Delete Existing Patient"),
            ),
          ],
        ),
      ),
    );
  }
}
