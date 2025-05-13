import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.monitor_heart),
              label: const Text('Monitoring Mandiri'),
              onPressed: () {
                context.push('/patient/self-monitoring');
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('Riwayat Pemeriksaan'),
              onPressed: () {
                context.push('/patient/history');
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('Account Settings'),
              onPressed: () {
                context.push('/account-settings');
              },
            ),
            // Tambahkan menu lain sesuai kebutuhan
          ],
        ),
      ),
    );
  }
}
