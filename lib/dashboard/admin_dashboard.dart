import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_ui.dart';
import '../core/theme.dart';
import '../pages/add_patient_page.dart';
import '../pages/update_patient_page.dart';
import '../pages/delete_patient_page.dart';
import '../pages/search_patient_page.dart';
import '../pages/staff_management_page.dart';
import '../pages/view_all_patients_page.dart';
class AdminDashboardPro extends StatelessWidget {
  final bool? isDarkMode;
  final VoidCallback? onThemeToggle;
  const AdminDashboardPro({
    super.key,
    this.isDarkMode,
    this.onThemeToggle,
  });
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_hospital_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: 10),
            Text('Smart Clinic'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: onThemeToggle,
            icon: const Icon(Icons.light_mode_outlined),
          ),
          PopupMenuButton<int>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(.14),
              child: Text(
                (user?.email ?? 'A')[0].toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 1,
                enabled: false,
                child: Text(user?.email ?? 'No email'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 2,
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: AppTheme.danger,
                    ),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 2) {
                await FirebaseAuth.instance.signOut();

                if (context.mounted) {
                  Navigator.popUntil(
                    context,
                    (route) => route.isFirst,
                  );
                }
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('patients').snapshots(),
        builder: (context, snapshot) {
          final count = snapshot.data?.docs.length ?? 0;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              32,
            ),
            children: [
              const PageIntro(
                title: 'Clinic overview',
                subtitle: 'Manage patient records from one secure workspace.',
              ),
              const SizedBox(height: 20),
              _StatCard(count: count),
              const SizedBox(height: 28),
              Text(
                'Patient management',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final actions = [
                    _ActionCard(
                      'Add patient',
                      'Register a new patient record',
                      Icons.person_add_alt_1_outlined,
                      () => _go(
                        context,
                        const AddPatientPage(),
                      ),
                    ),
                    _ActionCard(
                      'View patients',
                      'Browse all clinic records',
                      Icons.groups_2_outlined,
                      () => _go(
                        context,
                        const ViewAllPatientsPage(),
                      ),
                    ),
                    _ActionCard(
                      'Find patient',
                      'Search by name, ID or phone',
                      Icons.manage_search_outlined,
                      () => _go(
                        context,
                        const SearchPatientPage(),
                      ),
                    ),
                    _ActionCard(
                      'Update patient',
                      'Edit a selected patient record',
                      Icons.edit_note_outlined,
                      () => _go(
                        context,
                        const UpdatePatientPage(),
                      ),
                    ),
                    _ActionCard(
                      'Staff Management',
                      'Hire and manage clinic staff',
                      Icons.manage_accounts_outlined,
                      () => _go(
                        context,
                        const StaffManagementPage(),
                      ),
                    ),
                    _ActionCard(
                      'Delete patient',
                      'Remove a patient record',
                      Icons.delete_outline,
                      () => _go(
                        context,
                        const DeletePatientPage(),
                      ),
                      danger: true,
                    ),
                  ];

                  return GridView.count(
                    crossAxisCount: constraints.maxWidth >= 640 ? 2 : 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: constraints.maxWidth >= 640 ? 2.75 : 3.4,
                    children: actions,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _go(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }
}

// ============================================================
// STAT CARD
// ============================================================

class _StatCard extends StatelessWidget {
  final int count;

  const _StatCard({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.people_alt_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total patients',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$count',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          Text(
            'Live',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.success
                  : const Color(0xFF277A52),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ACTION CARD
// ============================================================

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  const _ActionCard(
    this.title,
    this.subtitle,
    this.icon,
    this.onTap, {
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = danger ? colors.error : colors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AppSurface(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward,
                size: 18,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
