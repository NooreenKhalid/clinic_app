import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/add_patient_page.dart';
import '../pages/view_all_patients_page.dart';

class StaffDashboardPro extends StatelessWidget {
  final bool? isDarkMode;
  final VoidCallback? onThemeToggle;

  const StaffDashboardPro({super.key, this.isDarkMode, this.onThemeToggle});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Theme-aware colors
    final backgroundColor =
        isDarkMode == true ? const Color(0xFF121212) : const Color(0xFFF4F6FA);
    final appBarColor = isDarkMode == true ? Colors.teal.shade700 : Colors.teal;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Staff Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: appBarColor,
        centerTitle: true,
        actions: [
          // Dark/Light toggle
          IconButton(
            icon: Icon(
              isDarkMode == true ? Icons.wb_sunny : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: onThemeToggle,
          ),

          // User Email + Logout Dropdown
          if (user != null)
            PopupMenuButton<int>(
              icon: const Icon(Icons.account_circle,
                  size: 28, color: Colors.white),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 1,
                  child: Text(
                    user.email ?? "No Email",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            isDarkMode == true ? Colors.white : Colors.black87),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 2,
                  child: Row(
                    children: const [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Logout", style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 2) {
                  try {
                    await FirebaseAuth.instance.signOut();
                    Navigator.popUntil(context, (route) => route.isFirst);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Logout failed: $e"),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _dashboardCard(context, "Add Patient", Icons.person_add, Colors.green,
              () => _navigate(context, const AddPatientPage())),
          _dashboardCard(context, "View Patients", Icons.list, Colors.blue,
              () => _navigate(context, const ViewAllPatientsPage())),
        ],
      ),
    );
  }

  /// ---------------- Card Widget ----------------
  Widget _dashboardCard(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return Card(
      color: isDarkMode == true ? Colors.grey[850] : Colors.white,
      elevation: 6,
      shadowColor: Colors.black26,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color,
          radius: 26,
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        title: Text(
          title,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: isDarkMode == true ? Colors.white : Colors.black),
        ),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 16,
            color: isDarkMode == true ? Colors.white70 : Colors.black54),
      ),
    );
  }

  /// ---------------- Navigation Helper ----------------
  void _navigate(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}
