import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/features/auth/presentation/viewmodels/user_provider.dart';

class DoctorDashboard extends ConsumerWidget {
  const DoctorDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final isValid = user?.isValid ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isValid) ...[
              Card(
                color: Colors.yellow[100],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Akun Anda belum diverifikasi Admin.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Silakan tunggu proses verifikasi maksimal 24 jam, atau hubungi admin untuk mempercepat proses.',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.monitor_heart),
                  label: const Text('Monitoring Detak Jantung Janin'),
                  onPressed:
                      isValid ? () => context.push('/doctor/monitoring') : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('Riwayat Pasien'),
                  onPressed:
                      isValid
                          ? () => context.push('/doctor/patient-history')
                          : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.new_releases),
                  label: const Text('Pasien Terbaru'),
                  onPressed:
                      isValid
                          ? () => context.push('/doctor/new-patients')
                          : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.settings),
                  label: const Text('Account Settings'),
                  onPressed: () => context.push('/account-settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
