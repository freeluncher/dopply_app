import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dopply_app/features/auth/presentation/providers/user_provider.dart';
import 'package:dopply_app/shared/models/user.dart';
import 'package:dopply_app/app/theme.dart';

/// Dashboard utama untuk pasien dengan UI modern dan user-friendly
class PatientDashboard extends ConsumerWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Modern App Bar dengan gradient
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: FlexibleSpaceBar(
                  title: Text(
                    'Dashboard Pasien',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.medicalWhite,
                    ),
                  ),
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                ),
              ),
              actions: [
                // Notifications button
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fitur notifikasi akan segera hadir'),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.medicalWhite,
                      size: 24,
                    ),
                  ),
                ),
                // Profile button
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: IconButton(
                    onPressed: () => context.push('/account-settings'),
                    icon: const Icon(
                      Icons.account_circle,
                      color: AppColors.medicalWhite,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Welcome Section
                  _buildWelcomeCard(context, user),

                  const SizedBox(height: 24),

                  // Quick Actions Section
                  _buildQuickActions(context),

                  const SizedBox(height: 24),

                  // Health Status Section
                  _buildHealthStatusSection(context),

                  const SizedBox(height: 24),

                  // Recent Activity Section
                  _buildRecentActivitySection(context),

                  const SizedBox(height: 24),

                  // Emergency Contact Section
                  _buildEmergencyContactSection(context),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Welcome card dengan informasi personal
  Widget _buildWelcomeCard(BuildContext context, User? user) {
    final currentHour = DateTime.now().hour;
    String greeting;

    if (currentHour < 12) {
      greeting = 'Selamat pagi,';
    } else if (currentHour < 15) {
      greeting = 'Selamat siang,';
    } else if (currentHour < 18) {
      greeting = 'Selamat sore,';
    } else {
      greeting = 'Selamat malam,';
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppColors.softShadow],
      ),
      child: Row(
        children: [
          // Profile Picture
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryBlueLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.primaryBlueLight, width: 2),
            ),
            child:
                user?.photoUrl != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.network(
                        user!.fullPhotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person,
                            color: AppColors.primaryBlue,
                            size: 32,
                          );
                        },
                      ),
                    )
                    : const Icon(
                      Icons.person,
                      color: AppColors.primaryBlue,
                      size: 32,
                    ),
          ),

          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.name ?? 'Pasien',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.medicalGreenLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ID: ${user?.id ?? '-'}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.medicalGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Quick actions untuk fitur utama
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aksi Cepat',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.monitor_heart,
                title: 'Monitoring\nMandiri',
                subtitle: 'Pantau detak jantung janin',
                color: AppColors.medicalGreen,
                onTap: () => context.push('/patient/self-monitoring'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.history,
                title: 'Riwayat\nPemeriksaan',
                subtitle: 'Lihat hasil monitoring',
                color: AppColors.primaryBlue,
                onTap: () => context.push('/patient/history'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.schedule,
                title: 'Jadwal\nKonsultasi',
                subtitle: 'Booking dengan dokter',
                color: AppColors.medicalPurple,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fitur akan segera hadir')),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.settings,
                title: 'Pengaturan\nAkun',
                subtitle: 'Kelola profil Anda',
                color: AppColors.textSecondary,
                onTap: () => context.push('/account-settings'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Action card individual
  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [AppColors.softShadow],
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Health status section
  Widget _buildHealthStatusSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status Kesehatan',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [AppColors.softShadow],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.medicalGreenLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: AppColors.medicalGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kondisi Umum',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Baik',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.medicalGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              const Divider(color: AppColors.border),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHealthMetric(
                    icon: Icons.monitor_heart_outlined,
                    label: 'Monitoring Terakhir',
                    value: 'Belum ada data',
                    color: AppColors.textSecondary,
                  ),
                  _buildHealthMetric(
                    icon: Icons.calendar_today,
                    label: 'Total Sesi',
                    value: '0',
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Health metric widget
  Widget _buildHealthMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Recent activity section
  Widget _buildRecentActivitySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Aktivitas Terkini',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/patient/history'),
              child: Text(
                'Lihat Semua',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [AppColors.softShadow],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.medicalGray,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Belum ada aktivitas monitoring',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Mulai monitoring mandiri untuk melihat riwayat aktivitas Anda',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Emergency contact section
  Widget _buildEmergencyContactSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.medicalRedLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.medicalRed.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.medicalRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.emergency,
              color: AppColors.medicalRed,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bantuan Darurat',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.medicalRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hubungi 119 atau dokter Anda jika mengalami kondisi darurat',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showEmergencyDialog(context),
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.medicalRed,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Show emergency contact dialog
  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.emergency,
                  color: AppColors.medicalRed,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Kontak Darurat',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.medicalRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jika Anda mengalami kondisi darurat, segera hubungi:',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildEmergencyContact(
                  icon: Icons.local_hospital,
                  title: 'Ambulans',
                  number: '119',
                ),
                const SizedBox(height: 12),
                _buildEmergencyContact(
                  icon: Icons.local_phone,
                  title: 'Rumah Sakit Terdekat',
                  number: '021-1234567',
                ),
                const SizedBox(height: 12),
                _buildEmergencyContact(
                  icon: Icons.person,
                  title: 'Dokter Anda',
                  number: 'Belum tersedia',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Tutup',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  /// Emergency contact item
  Widget _buildEmergencyContact({
    required IconData icon,
    required String title,
    required String number,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.medicalRedLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.medicalRed, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                number,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
