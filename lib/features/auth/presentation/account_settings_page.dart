import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// New structure imports
import '../../../services/api/user_api_service.dart';
import 'providers/user_provider.dart';
import 'providers/auth_repository_provider.dart';

/// **Account Settings Page**
///
/// Provides user account management functionality including:
/// - Profile photo management
/// - Email change
/// - Password change
/// - Role-specific features
/// - Logout functionality
///
/// Uses new API structure via UserApiService for consistency
class AccountSettingsPage extends ConsumerWidget {
  const AccountSettingsPage({Key? key}) : super(key: key);

  /// Shows dialog for changing user email
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
              decoration: const InputDecoration(
                hintText: 'Email baru',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newEmail = controller.text.trim();
                  if (newEmail.isEmpty || !newEmail.contains('@')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email tidak valid')),
                    );
                    return;
                  }

                  try {
                    // Using new API structure
                    final userApiService = UserApiService();
                    await userApiService.updateAccountEmail(
                      newEmail: newEmail,
                      password: '', // TODO: Ask for password confirmation
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Email berhasil diubah')),
                      );

                      // Refresh user data
                      ref.read(userProvider.notifier).state = null;
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
    );
  }

  /// Shows dialog for changing user password
  void _showChangePasswordDialog(
    BuildContext context,
    WidgetRef ref,
    String? role,
  ) {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

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
                  decoration: const InputDecoration(
                    hintText: 'Password lama',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPassController,
                  decoration: const InputDecoration(
                    hintText: 'Password baru',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPassController,
                  decoration: const InputDecoration(
                    hintText: 'Konfirmasi password baru',
                    prefixIcon: Icon(Icons.lock),
                  ),
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
                  final confirmPass = confirmPassController.text;

                  if (oldPass.isEmpty ||
                      newPass.isEmpty ||
                      confirmPass.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Semua field harus diisi')),
                    );
                    return;
                  }

                  if (newPass != confirmPass) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password baru tidak cocok'),
                      ),
                    );
                    return;
                  }

                  if (newPass.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password minimal 6 karakter'),
                      ),
                    );
                    return;
                  }

                  try {
                    // Using new API structure
                    final userApiService = UserApiService();
                    await userApiService.updateAccountPassword(
                      currentPassword: oldPass,
                      newPassword: newPass,
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password berhasil diubah'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
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
      appBar: AppBar(
        title: const Text('Pengaturan Akun'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Profile Section
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundImage:
                      user?.email != null
                          ? NetworkImage(
                            'https://ui-avatars.com/api/?name=${user!.email}&background=0D8ABC&color=fff',
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: () {
                        // TODO: Implement photo change functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fitur ganti foto akan segera hadir'),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // User Info Section
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.blue),
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
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.green),
                  title: Text(
                    user?.email ?? '-',
                  ), // Using email as display name for now
                  subtitle: const Text('Nama'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.badge, color: Colors.orange),
                  title: Text(user?.role.toUpperCase() ?? '-'),
                  subtitle: const Text('Role'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Security Section
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock, color: Colors.red),
                  title: const Text('Ganti Password'),
                  subtitle: const Text('Ubah password akun Anda'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap:
                      user == null
                          ? null
                          : () => _showChangePasswordDialog(
                            context,
                            ref,
                            user.role,
                          ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Role-specific features
          if (user?.role != null) ...[
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      user!.role == 'doctor'
                          ? Icons.medical_services
                          : user.role == 'admin'
                          ? Icons.admin_panel_settings
                          : Icons.favorite,
                      color:
                          user.role == 'doctor'
                              ? Colors.blue
                              : user.role == 'admin'
                              ? Colors.purple
                              : Colors.pink,
                    ),
                    title: Text('Fitur khusus ${user.role}'),
                    subtitle: Text('Pengaturan untuk ${user.role}'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Logout Section
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: const Text('Keluar dari akun'),
              onTap: () async {
                // Show confirmation dialog
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Konfirmasi Logout'),
                        content: const Text('Apakah Anda yakin ingin keluar?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                );

                if (shouldLogout == true && context.mounted) {
                  try {
                    await ref.read(authRepositoryProvider).logout();
                    ref.read(userProvider.notifier).state = null;
                    if (context.mounted) {
                      context.go('/login');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error logout: $e')),
                      );
                    }
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
