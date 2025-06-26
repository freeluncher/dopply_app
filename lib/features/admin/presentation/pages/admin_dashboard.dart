import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'doctor_validation_provider.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final validationCountAsync = ref.watch(doctorValidationCountProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        // Hapus actions logout
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            validationCountAsync.when(
              data:
                  (count) => Card(
                    color: count > 0 ? Colors.red[100] : Colors.green[100],
                    child: ListTile(
                      leading: Stack(
                        children: [
                          const Icon(
                            Icons.medical_services,
                            size: 32,
                            color: Colors.blue,
                          ),
                          if (count > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        count > 0
                            ? 'Ada $count permintaan verifikasi dokter!'
                            : 'Tidak ada permintaan verifikasi dokter.',
                        style: TextStyle(
                          color:
                              count > 0 ? Colors.red[900] : Colors.green[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle:
                          count > 0
                              ? const Text(
                                'Segera lakukan verifikasi pada menu Manajemen User.',
                              )
                              : null,
                    ),
                  ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (e, _) => Center(
                    child: Text(
                      'Gagal memuat data verifikasi dokter: $e',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
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
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: Icon(Icons.settings),
                    label: Text('Account Settings'),
                    onPressed: () {
                      context.push('/account-settings');
                    },
                  ),
                  // ...tambahkan menu lain sesuai kebutuhan...
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
