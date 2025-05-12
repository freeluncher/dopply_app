import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Implementasikan logout sesuai provider Anda
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
              icon: const Icon(Icons.monitor_heart),
              label: const Text('Monitoring Detak Jantung Janin'),
              onPressed: () {
                context.push('/doctor/monitoring');
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Tambah Pasien'),
              onPressed: () {
                context.push('/doctor/add-patient');
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('Riwayat Pasien'),
              onPressed: () {
                context.push('/doctor/patient-history');
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.new_releases),
              label: const Text('Pasien Terbaru'),
              onPressed: () {
                context.push('/doctor/new-patients');
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('Account Settings'),
              onPressed: () {
                context.push('/doctor/account-settings');
              },
            ),
            // Tambahkan menu lain sesuai kebutuhan
          ],
        ),
      ),
    );
  }
}
