import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_ui.dart';
import '../pages/add_patient_page.dart';
import '../pages/view_all_patients_page.dart';

class StaffDashboardPro extends StatelessWidget {
  final bool? isDarkMode;
  final VoidCallback? onThemeToggle;

  const StaffDashboardPro({super.key, this.isDarkMode, this.onThemeToggle});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_hospital_outlined, color: colors.primary),
            const SizedBox(width: 10),
            const Text('Smart Clinic'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: onThemeToggle,
            icon: const Icon(Icons.light_mode_outlined),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('patients').snapshots(),
        builder: (context, snapshot) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            const PageIntro(
              title: 'Staff workspace',
              subtitle: 'Access the patient records you need today.',
            ),
            AppSurface(
              child: Row(
                children: [
                  Icon(Icons.people_alt_outlined, color: colors.primary),
                  const SizedBox(width: 12),
                  Text(
                    '${snapshot.data?.docs.length ?? 0}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'patient records',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _Action(
              'Register a patient',
              'Create a new patient record',
              Icons.person_add_alt_1_outlined,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddPatientPage()),
              ),
            ),
            const SizedBox(height: 12),
            _Action(
              'View patient records',
              'Browse and manage existing records',
              Icons.groups_2_outlined,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ViewAllPatientsPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback tap;

  const _Action(this.title, this.subtitle, this.icon, this.tap);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(16),
        child: AppSurface(
          child: Row(
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
