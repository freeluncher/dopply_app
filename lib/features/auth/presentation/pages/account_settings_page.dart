import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dopply_app/features/patient/data/services/account_api_service_patient.dart';
import 'package:dopply_app/features/doctor/data/services/account_api_service_doctor.dart';
import 'package:dopply_app/features/admin/data/services/account_api_service_admin.dart';

import '../../domain/entities/user.dart';
import '../viewmodels/user_provider.dart';
import '../viewmodels/login_view_model.dart';

class AccountSettingsPage extends ConsumerWidget {
  const AccountSettingsPage({Key? key}) : super(key: key);

  void _showChangeEmailDialog(
    BuildContext context,
    WidgetRef ref,
    String? currentEmail,
    String? role,
  ) {
    final controller = TextEditingController(text: currentEmail ?? '');
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Ganti Email'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Email baru'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newEmail = controller.text.trim();
                  if (newEmail.isEmpty) return;
                  bool success = false;
                  if (role == 'patient') {
                    final api = AccountApiServicePatient();
                    success = await api.changeEmail(newEmail: newEmail);
                  } else if (role == 'doctor') {
                    final api = AccountApiServiceDoctor();
                    success = await api.changeEmail(newEmail: newEmail);
                  } else if (role == 'admin') {
                    final api = AccountApiServiceAdmin();
                    success = await api.changeEmail(newEmail: newEmail);
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Email berhasil diubah'
                            : 'Gagal mengubah email',
                      ),
                    ),
                  );
                  if (success) ref.read(userProvider.notifier).state = null;
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
    );
  }

  void _showChangePasswordDialog(
    BuildContext context,
    WidgetRef ref,
    String? role,
  ) {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Ganti Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPassController,
                  decoration: const InputDecoration(hintText: 'Password lama'),
                  obscureText: true,
                ),
                TextField(
                  controller: newPassController,
                  decoration: const InputDecoration(hintText: 'Password baru'),
                  obscureText: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final oldPass = oldPassController.text;
                  final newPass = newPassController.text;
                  if (oldPass.isEmpty || newPass.isEmpty) return;
                  bool success = false;
                  if (role == 'patient') {
                    final api = AccountApiServicePatient();
                    success = await api.changePassword(
                      oldPassword: oldPass,
                      newPassword: newPass,
                    );
                  } else if (role == 'doctor') {
                    final api = AccountApiServiceDoctor();
                    success = await api.changePassword(
                      oldPassword: oldPass,
                      newPassword: newPass,
                    );
                  } else if (role == 'admin') {
                    final api = AccountApiServiceAdmin();
                    success = await api.changePassword(
                      oldPassword: oldPass,
                      newPassword: newPass,
                    );
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Password berhasil diubah'
                            : 'Gagal mengubah password',
                      ),
                    ),
                  );
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Account Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundImage:
                      user?.email != null
                          ? NetworkImage(
                            'https://ui-avatars.com/api/?name=${user!.email}',
                          )
                          : null,
                  child:
                      user?.email == null
                          ? const Icon(Icons.person, size: 48)
                          : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () {
                      // TODO: Implementasi ganti foto profil
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.email),
            title: Text(user?.email ?? '-'),
            subtitle: const Text('Email'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed:
                  user == null
                      ? null
                      : () => _showChangeEmailDialog(
                        context,
                        ref,
                        user.email,
                        user.role,
                      ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Ganti Password'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed:
                  user == null
                      ? null
                      : () =>
                          _showChangePasswordDialog(context, ref, user.role),
            ),
          ),
          const Divider(),
          // Fitur khusus per role (jika ada)
          if (user?.role == 'doctor')
            const ListTile(
              leading: Icon(Icons.medical_services),
              title: Text('Fitur khusus dokter'),
            ),
          if (user?.role == 'admin')
            const ListTile(
              leading: Icon(Icons.admin_panel_settings),
              title: Text('Fitur khusus admin'),
            ),
          if (user?.role == 'patient')
            const ListTile(
              leading: Icon(Icons.favorite),
              title: Text('Fitur khusus pasien'),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await ref.read(authRepositoryProvider).logout();
              ref.read(userProvider.notifier).state = null;
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}
