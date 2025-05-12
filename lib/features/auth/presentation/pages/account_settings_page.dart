import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import '../viewmodels/user_provider.dart';

class AccountSettingsPage extends ConsumerWidget {
  const AccountSettingsPage({Key? key}) : super(key: key);

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
              onPressed: () {
                // TODO: Implementasi ganti email
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Ganti Password'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: Implementasi ganti password
              },
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
        ],
      ),
    );
  }
}
