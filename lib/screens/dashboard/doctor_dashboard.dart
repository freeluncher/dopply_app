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
                  context.go('/login');
                }
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            _buildWelcomeCard(),
            const SizedBox(height: 24),

            // Available Features
            Text('Fitur Tersedia', style: AppTheme.heading2),
            const SizedBox(height: 16),

            _buildAvailableFeaturesGrid(context),

            const SizedBox(height: 24),

            // Coming Soon Features
            _buildComingSoonSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.local_hospital, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            const Text(
              'Selamat Datang, Dokter',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mulai monitoring fetal untuk pasien Anda',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableFeaturesGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildFeatureCard(
          icon: Icons.monitor_heart,
          title: 'Monitoring Fetal',
          subtitle: 'Mulai monitoring\nfetal real-time',
          color: Colors.red,
          isAvailable: true,
          onTap: () => context.go('/monitoring'),
        ),
        _buildFeatureCard(
          icon: Icons.history,
          title: 'Riwayat Monitoring',
          subtitle: 'Lihat data monitoring\nsebelumnya',
          color: Colors.blue,
          isAvailable: true,
          onTap: () => context.go('/history'),
        ),
      ],
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

  Widget _buildComingSoonSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
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
              icon: Icons.people,
              title: 'Manajemen Pasien',
              subtitle: 'Kelola data pasien dan assignment',
            ),
            _buildComingSoonItem(
              icon: Icons.person_add,
              title: 'Tambah Pasien',
              subtitle: 'Daftarkan pasien baru ke sistem',
            ),
            _buildComingSoonItem(
              icon: Icons.notifications,
              title: 'Notifikasi',
              subtitle: 'Terima alert dari pasien',
            ),
            _buildComingSoonItem(
              icon: Icons.analytics,
              title: 'Analytics Dashboard',
              subtitle: 'Analisis data monitoring pasien',
            ),

            const SizedBox(height: 16),
            Text(
              'Saat ini, silakan gunakan fitur monitoring fetal yang sudah tersedia untuk memulai diagnosis.',
              style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyText.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTheme.caption.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          ),
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
      ),
    );
  }
}
