import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dopply_app/features/auth/presentation/pages/login_page.dart'; // Import loginStatusProvider

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              ref.read(loginStatusProvider.notifier).state = null;
              context.go('/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.people),
              label: Text('Manajemen User'),
              onPressed: () {
                context.push('/admin/users');
              },
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.bar_chart),
              label: Text('Laporan'),
              onPressed: () {
                context.push('/admin/reports');
              },
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.settings),
              label: Text('Pengaturan'),
              onPressed: () {
                context.push('/admin/settings');
              },
            ),
            // ...tambahkan menu lain sesuai kebutuhan...
          ],
        ),
      ),
    );
  }
}
