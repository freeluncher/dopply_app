import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/features/auth/presentation/viewmodels/user_provider.dart';

/// Dashboard utama untuk dokter, menampilkan menu navigasi dan status verifikasi akun
class DoctorDashboard extends ConsumerWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider); // Ambil data user dari provider
    final isValid = user?.isValid ?? false; // Cek status verifikasi akun
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isValid) const VerificationWarningCard(),
            const SizedBox(height: 16),
            const DoctorMenu(),
          ],
        ),
      ),
    );
  }
}

/// Widget untuk warning verifikasi akun dokter
class VerificationWarningCard extends StatelessWidget {
  const VerificationWarningCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Card(
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
    );
  }
}

/// Widget menu utama dokter (tombol navigasi)
class DoctorMenu extends ConsumerWidget {
  const DoctorMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final isValid = user?.isValid ?? false;
    return Column(
      children: [
        DoctorMenuButton(
          icon: Icons.monitor_heart,
          label: 'Monitoring Detak Jantung Janin',
          route: '/doctor/monitoring',
          enabled: isValid,
        ),
        const SizedBox(height: 16),
        DoctorMenuButton(
          icon: Icons.history,
          label: 'Riwayat Pasien',
          route: '/doctor/patient-history',
          enabled: isValid,
        ),
        const SizedBox(height: 16),
        DoctorMenuButton(
          icon: Icons.people,
          label: 'Daftar Pasien',
          route: '/doctor/patients',
          enabled: isValid,
        ),
        const SizedBox(height: 16),
        DoctorMenuButton(
          icon: Icons.settings,
          label: 'Account Settings',
          route: '/account-settings',
          enabled: true,
        ),
      ],
    );
  }
}

/// Widget tombol menu dokter
class DoctorMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool enabled;
  const DoctorMenuButton({
    super.key,
    required this.icon,
    required this.label,
    required this.route,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: enabled ? () => context.push(route) : null,
    );
  }
}
