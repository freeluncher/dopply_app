// =============================================================================
// Simplified Doctor Dashboard - Only Backend Supported Features
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dopply_app/core/theme.dart';
import 'package:dopply_app/services/auth_service.dart';

class DoctorDashboard extends ConsumerWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Dashboard Dokter'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'logout') {
                final authService = ref.read(authServiceProvider);
                await authService.logout();
                if (context.mounted) {
                  context.go('/');
                }
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 'logout', child: Text('Logout')),
                ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Selamat Datang, Dokter', style: AppTheme.heading2),
              const SizedBox(height: 16),
              Text(
                'Pilih fitur yang ingin digunakan:',
                style: AppTheme.bodyText,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildFeatureCard(
                      icon: Icons.monitor_heart,
                      title: 'Monitoring',
                      subtitle: 'Pantau kondisi pasien\nsecara real-time',
                      color: Colors.green,
                      isAvailable: true,
                      onTap: () => context.go('/monitoring'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildFeatureCard(
                      icon: Icons.history,
                      title: 'Riwayat Monitoring',
                      subtitle: 'Lihat data monitoring\nsebelumnya',
                      color: Colors.blue,
                      isAvailable: true,
                      onTap: () => context.go('/history'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildFeatureCard(
                      icon: Icons.notifications,
                      title: 'Notifikasi',
                      subtitle: 'Pemberitahuan penting\nuntuk dokter',
                      color: Colors.orange,
                      isAvailable: false,
                      onTap: () => context.go('/notifications'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildFeatureCard(
                      icon: Icons.settings,
                      title: 'Pengaturan',
                      subtitle: 'Atur profil dan preferensi\ndokter',
                      color: Colors.purple,
                      isAvailable: true,
                      onTap: () => context.go('/settings'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Fitur Akan Segera Hadir',
                style: AppTheme.heading3.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Fitur lanjutan yang sedang dalam pengembangan:',
                style: AppTheme.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Coming Soon Features List
              _buildComingSoonItem(
                title: 'Telemedicine',
                subtitle: 'Konsultasi jarak jauh dengan pasien',
                isAvailable: false,
              ),
              _buildComingSoonItem(
                title: 'Integrasi Lab',
                subtitle: 'Hasil lab otomatis masuk ke sistem',
                isAvailable: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isAvailable,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isAvailable ? null : Colors.grey.withOpacity(0.1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isAvailable
                          ? color.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isAvailable ? color : Colors.grey,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTheme.heading3.copyWith(
                  color: isAvailable ? null : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTheme.caption.copyWith(
                  color: isAvailable ? null : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              if (!isAvailable) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Segera Hadir',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonItem({
    required String title,
    required String subtitle,
    required bool isAvailable,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTheme.heading3.copyWith(
                color: isAvailable ? null : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTheme.caption.copyWith(color: Colors.grey[500]),
            ),
            if (!isAvailable) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Segera',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
