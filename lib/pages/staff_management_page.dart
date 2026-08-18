import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_ui.dart';
import '../services/imagebb_service.dart';
import '../services/staff_service.dart';
class StaffManagementPage extends StatelessWidget {
const StaffManagementPage({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const _StaffManagementDenied();
    }
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: StaffService.firestore.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final isAdmin = snapshot.data?.data()?['role'] == 'admin';
        if (!isAdmin) return const _StaffManagementDenied();
        return const _StaffManagementContent();
      },
    );
  }
}

class _StaffManagementDenied extends StatelessWidget {
  const _StaffManagementDenied();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Management')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Staff Management is available to administrators only.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}

class _StaffManagementContent extends StatelessWidget {
  const _StaffManagementContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddStaffPage()),
        ),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Hire staff'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: StaffService.activeStaff(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load staff members.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final staff = snapshot.data!.docs;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
            children: [
              const PageIntro(
                title: 'Clinic staff',
                subtitle:
                    'Hire staff and manage access to the clinic workspace.',
              ),
              if (staff.isEmpty)
                const AppSurface(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.groups_outlined, size: 42),
                      SizedBox(height: 12),
                      Text('No active staff members'),
                      SizedBox(height: 4),
                      Text('Hire a staff member to grant clinic access.'),
                    ],
                  ),
                )
              else
                ...staff.map(
                  (document) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _StaffCard(
                      uid: document.id,
                      data: document.data(),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> data;

  const _StaffCard({required this.uid, required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = data['name'] as String? ?? 'Staff member';
    final email = data['email'] as String? ?? '';
    final occupation = data['occupation'] as String? ?? '-';
    final age = data['age']?.toString() ?? '-';
    final imageUrl = data['profileImageUrl'] as String? ?? '';

    return AppSurface(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: colors.primary.withValues(alpha: .14),
            backgroundImage: imageUrl.isEmpty ? null : NetworkImage(imageUrl),
            child: imageUrl.isEmpty
                ? Text(
                    name.isEmpty ? 'S' : name[0].toUpperCase(),
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(email, style: TextStyle(color: colors.onSurfaceVariant)),
                const SizedBox(height: 8),
                Text('Age: $age  •  $occupation'),
                const SizedBox(height: 8),
                Text(
                  'Active',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove staff member',
            icon: Icon(Icons.delete_outline, color: colors.error),
            onPressed: () =>
                _confirmRemoval(context, name, email, occupation, imageUrl),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoval(
    BuildContext context,
    String name,
    String email,
    String occupation,
    String imageUrl,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Staff Member?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 34,
                backgroundImage:
                    imageUrl.isEmpty ? null : NetworkImage(imageUrl),
                child:
                    imageUrl.isEmpty ? const Icon(Icons.person_outline) : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(email),
            Text(occupation),
            const SizedBox(height: 12),
            const Text(
              'Are you sure you want to remove this staff member? They will no longer be able to access the clinic app.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    try {
      await StaffService.deactivateStaff(uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff member removed.')),
        );
      }
    } catch (_) {
      if (context.mounted) _showError(context, null);
    }
  }

  void _showError(BuildContext context, String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Unable to remove staff member.')),
    );
  }
}

class AddStaffPage extends StatefulWidget {
  const AddStaffPage({super.key});

  @override
  State<AddStaffPage> createState() => _AddStaffPageState();
}

class _AddStaffPageState extends State<AddStaffPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _occupation = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _picker = ImagePicker();
  Uint8List? _imageBytes;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _occupation.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (mounted) {
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_imageBytes == null) {
      _showMessage('Select a profile picture before hiring staff.',
          error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final imageUrl = await ImageBBService.uploadImageBytes(
        _imageBytes!,
        name: _name.text.trim(),
      );
      if (imageUrl == null || imageUrl.isEmpty) {
        throw StateError('Profile image upload failed.');
      }
      await StaffService.createStaff(
        name: _name.text.trim(),
        age: int.parse(_age.text.trim()),
        occupation: _occupation.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        profileImageUrl: imageUrl,
      );
      if (mounted) {
        _showMessage('Staff record created. The staff member can now log in.');
        Navigator.pop(context);
      }
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Bad state: ', ''),
          error: true);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showMessage(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Hire Staff')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageIntro(
                title: 'Add new staff',
                subtitle: 'Create an approved staff account for clinic access.',
              ),
              Center(
                child: InkWell(
                  onTap: _saving ? null : _pickImage,
                  borderRadius: BorderRadius.circular(48),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: colors.primary.withValues(alpha: .14),
                    backgroundImage:
                        _imageBytes == null ? null : MemoryImage(_imageBytes!),
                    child: _imageBytes == null
                        ? Icon(Icons.add_a_photo_outlined,
                            color: colors.primary)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _saving ? null : _pickImage,
                  child: const Text('Select profile picture'),
                ),
              ),
              const SizedBox(height: 12),
              _field(_name, 'Full Name',
                  requiredMessage: 'Enter the staff member\'s name.'),
              _field(
                _age,
                'Age',
                keyboardType: TextInputType.number,
                validator: (value) {
                  final age = int.tryParse(value?.trim() ?? '');
                  if (age == null || age <= 0 || age > 130)
                    return 'Enter a valid age.';
                  return null;
                },
              ),
              _field(_occupation, 'Occupation',
                  requiredMessage: 'Enter an occupation.'),
              _field(
                _email,
                'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),
              _field(
                _password,
                'Temporary password',
                obscureText: true,
                validator: (value) {
                  if ((value ?? '').length < 6) {
                    return 'Use at least 6 characters.';
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  'The account is created securely by Firebase Cloud Functions. This password is never stored in Firestore.',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.onPrimary,
                          ),
                        )
                      : const Icon(Icons.person_add_alt_1_outlined),
                  label: Text(_saving ? 'Hiring staff...' : 'Hire Staff'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? requiredMessage,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(labelText: label, suffixIcon: suffix),
        validator: validator ??
            (value) => (value?.trim().isEmpty ?? true) ? requiredMessage : null,
      ),
    );
  }
}
