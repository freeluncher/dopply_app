import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/features/auth/presentation/viewmodels/user_provider.dart';
import 'package:dopply_app/app/theme.dart';
import 'package:dopply_app/features/doctor/presentation/viewmodels/doctor_quick_stats_notifier.dart';
import 'package:dopply_app/features/doctor/presentation/viewmodels/doctor_patients_notifier.dart';

/// Dashboard utama untuk dokter, menampilkan menu navigasi dan status verifikasi akun
class DoctorDashboard extends ConsumerWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider); // Ambil data user dari provider
    final isValid = user?.isValid ?? false; // Cek status verifikasi akun

    // Load quick stats saat build pertama kali
    ref.listen(userProvider, (previous, next) {
      if (next?.doctorId != null && next?.doctorId != previous?.doctorId) {
        ref.read(doctorQuickStatsProvider.notifier).loadStats(next!.doctorId);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar dengan gradient
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: FlexibleSpaceBar(
                  title: Text(
                    'Dashboard Dokter',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.medicalWhite,
                    ),
                  ),
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                ),
              ),
              actions: [
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

                  const SizedBox(height: 20),

                  // Verification Warning (if needed)
                  if (!isValid) ...[
                    const VerificationWarningCard(),
                    const SizedBox(height: 20),
                  ],

                  // Quick Stats Section
                  _buildQuickStats(context, ref),

                  const SizedBox(height: 24),

                  // Main Menu Section
                  MedicalSectionHeader(
                    title: 'Menu Utama',
                    subtitle: 'Akses fitur monitoring dan manajemen pasien',
                  ),

                  const SizedBox(height: 16),

                  DoctorMenu(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, user) {
    final timeOfDay = _getTimeOfDay();

    return MedicalCard(
      backgroundColor: AppColors.medicalWhite,
      isElevated: true,
      child: Row(
        children: [
          // Medical icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.medical_services,
              color: AppColors.medicalWhite,
              size: 30,
            ),
          ),

          const SizedBox(width: 16),

          // Welcome text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$timeOfDay, Dokter!',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Siap untuk memantau kesehatan janin hari ini?',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color:
                          user?.isValid == true
                              ? AppColors.medicalGreen
                              : AppColors.medicalOrange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      user?.isValid == true
                          ? 'Akun Terverifikasi'
                          : 'Menunggu Verifikasi',
                      style: AppTextStyles.labelMedium.copyWith(
                        color:
                            user?.isValid == true
                                ? AppColors.medicalGreen
                                : AppColors.medicalOrange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, WidgetRef ref) {
    final quickStatsState = ref.watch(doctorQuickStatsProvider);
    final doctorPatientsState = ref.watch(doctorPatientsProvider);

    // Kombinasi data dari quick stats dan doctor patients
    final totalPatients =
        quickStatsState.isLoading
            ? '-'
            : doctorPatientsState.patients.length.toString();

    final activeMonitoring =
        quickStatsState.isLoading
            ? '-'
            : quickStatsState.stats.activeMonitoring.toString();

    final totalHistory =
        quickStatsState.isLoading
            ? '-'
            : quickStatsState.stats.totalHistory.toString();

    return RefreshIndicator(
      onRefresh: () async {
        final user = ref.read(userProvider);
        if (user?.doctorId != null) {
          await ref
              .read(doctorQuickStatsProvider.notifier)
              .refreshStats(user!.doctorId);
          await ref.read(doctorPatientsProvider.notifier).fetchPatients();
        }
      },
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.people,
              title: 'Pasien',
              value: totalPatients,
              subtitle: 'Total pasien',
              color: AppColors.primaryBlue,
              isLoading:
                  quickStatsState.isLoading || doctorPatientsState.isLoading,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.monitor_heart,
              title: 'Monitoring',
              subtitle: 'Aktif hari ini',
              value: activeMonitoring,
              color: AppColors.medicalGreen,
              isLoading: quickStatsState.isLoading,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.history,
              title: 'Riwayat',
              subtitle: 'Total rekam',
              value: totalHistory,
              color: AppColors.medicalPurple,
              isLoading: quickStatsState.isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    String? subtitle,
    bool isLoading = false,
  }) {
    return MedicalCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child:
                isLoading
                    ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    )
                    : Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            isLoading ? '-' : value,
            style: AppTextStyles.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            title,
            style: AppTextStyles.labelSmall,
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiary,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }
}

/// Widget untuk warning verifikasi akun dokter
class VerificationWarningCard extends StatelessWidget {
  const VerificationWarningCard({super.key});

  @override
  Widget build(BuildContext context) {
    return MedicalCard(
      backgroundColor: AppColors.medicalOrangeLight,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.medicalOrange,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: AppColors.medicalWhite,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Akun Belum Diverifikasi',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.medicalOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tunggu verifikasi admin maksimal 24 jam untuk mengakses semua fitur.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
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

    final menuItems = [
      DoctorMenuItem(
        icon: Icons.monitor_heart,
        title: 'Monitoring Detak Jantung',
        subtitle: 'Pantau detak jantung janin secara real-time',
        route: '/doctor/monitoring',
        enabled: isValid,
        color: AppColors.medicalRed,
      ),
      DoctorMenuItem(
        icon: Icons.people,
        title: 'Daftar Pasien',
        subtitle: 'Kelola data dan informasi pasien',
        route: '/doctor/patients',
        enabled: isValid,
        color: AppColors.primaryBlue,
      ),
      DoctorMenuItem(
        icon: Icons.history,
        title: 'Riwayat Pasien',
        subtitle: 'Lihat riwayat monitoring dan diagnosis',
        route: '/doctor/patient-history',
        enabled: isValid,
        color: AppColors.medicalPurple,
      ),
      DoctorMenuItem(
        icon: Icons.settings,
        title: 'Pengaturan Akun',
        subtitle: 'Kelola profil dan preferensi',
        route: '/account-settings',
        enabled: true,
        color: AppColors.textSecondary,
      ),
    ];

    return Column(
      children: [
        ...menuItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DoctorMenuCard(item: item),
          ),
        ),
      ],
    );
  }
}

/// Model untuk menu item dokter
class DoctorMenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final bool enabled;
  final Color color;

  DoctorMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.enabled,
    required this.color,
  });
}

/// Widget card untuk menu dokter
class DoctorMenuCard extends StatelessWidget {
  final DoctorMenuItem item;

  const DoctorMenuCard({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    return MedicalCard(
      backgroundColor: item.enabled ? AppColors.surface : AppColors.medicalGray,
      child: InkWell(
        onTap: item.enabled ? () => context.push(item.route) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color:
                      item.enabled
                          ? item.color.withOpacity(0.1)
                          : AppColors.textTertiary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  item.icon,
                  color: item.enabled ? item.color : AppColors.textTertiary,
                  size: 28,
                ),
              ),

              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color:
                            item.enabled
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color:
                            item.enabled
                                ? AppColors.textSecondary
                                : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                color:
                    item.enabled
                        ? AppColors.textSecondary
                        : AppColors.textTertiary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
