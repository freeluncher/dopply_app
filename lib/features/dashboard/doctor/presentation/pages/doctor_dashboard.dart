// =============================================================================
// Doctor Dashboard - New Architecture
//
// Modern doctor dashboard with integrated patient management, monitoring
// capabilities, and real-time medical data overview.
//
// Features:
// - Real-time patient monitoring overview
// - Quick access to monitoring tools
// - Patient management interface
// - Medical record integration
// - Multi-patient session management
// - Enhanced UI/UX with modern design patterns
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/doctor_welcome_card.dart';
import '../widgets/doctor_quick_stats.dart';
import '../widgets/doctor_menu_grid.dart';
import '../widgets/recent_patients_list.dart';
import '../providers/doctor_dashboard_providers.dart';
import '../../../../../shared/models/user.dart';
import '../../../../../app/theme.dart';
import 'dart:convert';
import '../../../../../services/api/api_client.dart';

// For now, create a simple user provider for the dashboard
final dashboardUserProvider = StateProvider<User?>((ref) => null);

class DoctorDashboard extends ConsumerStatefulWidget {
  const DoctorDashboard({super.key});

  @override
  ConsumerState<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends ConsumerState<DoctorDashboard> {
  final ScrollController _scrollController = ScrollController();

  /// Fetch latest user info from /token/verify and update provider
  Future<void> _refreshUserFromApi() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.get('/token/verify');
      final data = json.decode(response.body);
      debugPrint('[DASHBOARD] /token/verify response: ' + data.toString());
      final newUser = User(
        id: data['user_id'] ?? data['id'] ?? 0,
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        role: data['role'] ?? 'doctor',
        isValid: data['is_valid'] ?? false,
      );
      ref.read(dashboardUserProvider.notifier).state = newUser;
      debugPrint('[DASHBOARD] Updated user: ' + newUser.toString());
    } catch (e, st) {
      debugPrint('[DASHBOARD] Error refreshing user: $e\n$st');
    }
  }

  Future<void> _loadDashboardData() async {
    await _refreshUserFromApi();
    final user = ref.read(dashboardUserProvider);
    if (user != null && user.role == 'doctor') {
      ref.read(doctorStatsProvider.notifier).loadStats(user.id.toString());
      ref
          .read(doctorPatientsProvider.notifier)
          .loadPatients(user.id.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(dashboardUserProvider);
    final isValid = user?.isValid ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadDashboardData();
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Modern App Bar
              _buildSliverAppBar(context, user),

              // Dashboard Content
              SliverPadding(
                padding: const EdgeInsets.all(20.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Welcome Section
                    DoctorWelcomeCard(user: user),

                    const SizedBox(height: 24),

                    // Verification Status (if not verified)
                    if (!isValid) ...[
                      _buildVerificationWarning(),
                      const SizedBox(height: 24),
                    ],

                    // Quick Stats Section
                    DoctorQuickStats(isEnabled: isValid),

                    const SizedBox(height: 32),

                    // Main Menu Section
                    _buildSectionHeader(
                      'Medical Tools',
                      'Access fetal monitoring and patient management tools',
                    ),
                    const SizedBox(height: 20),
                    DoctorMenuGrid(isEnabled: isValid),

                    const SizedBox(height: 32),

                    // Recent Patients
                    if (isValid) ...[
                      _buildSectionHeader(
                        'Recent Patients',
                        'Recently monitored or updated patients',
                      ),
                      const SizedBox(height: 20),
                      RecentPatientsList(),
                      const SizedBox(height: 32),
                    ],

                    // Quick Access Section
                    if (isValid) ...[
                      _buildQuickAccessSection(),
                      const SizedBox(height: 32),
                    ],

                    // Bottom padding for FAB
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      // Floating Action Button for Quick Fetal Monitoring
      floatingActionButton: isValid ? _buildQuickMonitoringFAB() : null,
    );
  }

  Widget _buildSliverAppBar(BuildContext context, User? user) {
    String title = 'Doctor Dashboard';
    if (user?.name != null && user!.name.isNotEmpty) {
      final firstName = user.name.split(' ').first;
      title = 'Welcome, Dr. $firstName';
    }

    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: FlexibleSpaceBar(
          title: Text(
            title,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.medicalWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: false,
          titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
          background: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Stack(
              children: [
                // Background pattern
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    Icons.medical_services_outlined,
                    size: 100,
                    color: AppColors.medicalWhite.withOpacity(0.1),
                  ),
                ),
                Positioned(
                  right: 60,
                  bottom: -10,
                  child: Icon(
                    Icons.monitor_heart_outlined,
                    size: 80,
                    color: AppColors.medicalWhite.withOpacity(0.08),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        // Notifications with modern design
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.medicalWhite.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.medicalWhite,
                    size: 20,
                  ),
                ),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.medicalRed,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.medicalWhite,
                        width: 1.5,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '3',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.medicalWhite,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () => _showNotifications(context),
          ),
        ),

        // Profile with modern design
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.medicalWhite.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_circle_outlined,
                color: AppColors.medicalWhite,
                size: 20,
              ),
            ),
            onPressed: () => context.push('/account-settings'),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationWarning() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.medicalOrangeLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.medicalOrange.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: const [AppColors.softShadow],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.medicalOrange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.warning_rounded,
              color: AppColors.medicalOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Verification Pending',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.medicalOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your account is pending admin verification. Some features may be limited until verification is complete.',
                  style: AppTextStyles.bodyMedium.copyWith(
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

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          AppColors.mediumShadow.copyWith(
            color: AppColors.primaryBlue.withOpacity(0.25),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.medicalWhite.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.monitor_heart_rounded,
                  color: AppColors.medicalWhite,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fetal Heart Monitoring',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.medicalWhite,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Advanced doppler monitoring system',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.medicalWhite.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/doctor/monitoring'),
                  icon: const Icon(Icons.favorite_rounded, size: 20),
                  label: Text(
                    'Start Monitoring',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.medicalWhite,
                    foregroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/doctor/patients'),
                  icon: const Icon(Icons.people_rounded, size: 20),
                  label: Text(
                    'Manage Patients',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.medicalWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlueDark,
                    foregroundColor: AppColors.medicalWhite,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMonitoringFAB() {
    return FloatingActionButton.extended(
      onPressed: () => context.push('/doctor/monitoring'),
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: AppColors.medicalWhite,
      icon: Icon(Icons.monitor_heart_rounded, size: 24),
      label: Text(
        'Fetal Monitoring',
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.medicalWhite,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.medicalWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [AppColors.strongShadow],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.notifications_rounded,
                          color: AppColors.primaryBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Notifications',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildNotificationItem(
                    icon: Icons.monitor_heart_rounded,
                    iconColor: AppColors.medicalGreen,
                    title: 'Monitoring Session',
                    subtitle: 'New fetal monitoring session started',
                    time: '2 min ago',
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationItem(
                    icon: Icons.schedule_rounded,
                    iconColor: AppColors.primaryBlue,
                    title: 'Appointment Reminder',
                    subtitle: 'Patient consultation at 2:00 PM',
                    time: '15 min ago',
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationItem(
                    icon: Icons.check_circle_rounded,
                    iconColor: AppColors.medicalGreen,
                    title: 'Session Complete',
                    subtitle: 'Fetal monitoring completed successfully',
                    time: '1 hour ago',
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Close',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.push('/doctor/notifications');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: AppColors.medicalWhite,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'View All',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.medicalWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.medicalGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
