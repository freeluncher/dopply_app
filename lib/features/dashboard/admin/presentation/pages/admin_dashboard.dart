// =============================================================================
// Admin Dashboard - New Architecture
//
// Modern admin dashboard with comprehensive system management, user oversight,
// and analytics capabilities.
//
// Features:
// - System overview with real-time statistics
// - User management interface
// - Doctor validation system
// - System analytics and monitoring
// - Recent activities tracking
// - Emergency system controls
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin_welcome_card.dart';
import '../widgets/system_stats_overview.dart';
import '../widgets/admin_menu_grid.dart';
import '../widgets/pending_validations_card.dart';
import '../widgets/recent_activities_list.dart';
import '../widgets/system_alerts_card.dart';
import '../providers/admin_dashboard_providers.dart';
import '../../../../../shared/models/user.dart';

// For now, create a simple user provider for the admin dashboard
final adminDashboardUserProvider = StateProvider<User?>((ref) => null);

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Load initial data when dashboard opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadDashboardData() {
    final user = ref.read(adminDashboardUserProvider);
    if (user != null && user.role == 'admin') {
      // Load dashboard data using the new providers
      ref.read(systemStatsProvider.notifier).loadStats();
      ref.read(userManagementProvider.notifier).loadUsers();
      ref.read(systemAnalyticsProvider.notifier).loadAnalytics();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(adminDashboardUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _loadDashboardData();
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Modern App Bar
              _buildSliverAppBar(context, user),

              // Dashboard Content
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Welcome Section
                    AdminWelcomeCard(user: user),

                    const SizedBox(height: 20),

                    // System Stats Overview
                    SystemStatsOverview(),

                    const SizedBox(height: 24),

                    // Pending Validations and System Alerts
                    Row(
                      children: [
                        Expanded(child: PendingValidationsCard()),
                        const SizedBox(width: 16),
                        Expanded(child: SystemAlertsCard()),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Main Menu Section
                    _buildSectionHeader(
                      'System Management',
                      'Administrative tools and system controls',
                    ),
                    const SizedBox(height: 16),
                    AdminMenuGrid(),

                    const SizedBox(height: 24),

                    // Recent Activities
                    _buildSectionHeader(
                      'Recent System Activities',
                      'Latest system events and user activities',
                    ),
                    const SizedBox(height: 16),
                    RecentActivitiesList(),

                    const SizedBox(height: 24),

                    // Emergency System Controls
                    _buildEmergencySystemControls(),

                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      // Floating Action Button for Quick Actions
      floatingActionButton: _buildQuickActionsFAB(),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, User? user) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          ),
        ),
        child: FlexibleSpaceBar(
          title: const Text(
            'Admin Dashboard',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: false,
          titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        ),
      ),
      actions: [
        // System Status
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.admin_panel_settings, color: Colors.white),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: const Text(
                    '●',
                    style: TextStyle(color: Colors.white, fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          onPressed: () => _showSystemStatus(context),
        ),

        // Notifications
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined, color: Colors.white),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: const Text(
                    '5',
                    style: TextStyle(color: Colors.white, fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          onPressed: () => _showNotifications(context),
        ),

        // Profile
        IconButton(
          icon: const Icon(Icons.account_circle, color: Colors.white, size: 28),
          onPressed: () => context.push('/account-settings'),
        ),

        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildEmergencySystemControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red.shade600, Colors.red.shade800],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.security, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Emergency System Controls',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Critical system functions for emergency situations',
            style: TextStyle(
              color: Color.fromRGBO(255, 255, 255, 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showMaintenanceMode(),
                  icon: const Icon(Icons.build),
                  label: const Text('Maintenance Mode'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showSystemBackup(),
                  icon: const Icon(Icons.backup),
                  label: const Text('System Backup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _showQuickActions(context),
      backgroundColor: const Color(0xFF1565C0),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.admin_panel_settings),
      label: const Text('Quick Actions'),
      elevation: 4,
    );
  }

  void _showSystemStatus(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.green),
                SizedBox(width: 8),
                Text('System Status'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Database'),
                  subtitle: Text('Online - 99.9% uptime'),
                  contentPadding: EdgeInsets.zero,
                ),
                ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('API Services'),
                  subtitle: Text('All services operational'),
                  contentPadding: EdgeInsets.zero,
                ),
                ListTile(
                  leading: Icon(Icons.warning, color: Colors.orange),
                  title: Text('Storage'),
                  subtitle: Text('85% capacity - Consider cleanup'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/admin/system-status');
                },
                child: const Text('View Details'),
              ),
            ],
          ),
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('System Notifications'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: Icon(Icons.person_add, color: Colors.blue),
                  title: Text('New Doctor Registration'),
                  subtitle: Text('Dr. Jennifer Liu requires validation'),
                  contentPadding: EdgeInsets.zero,
                ),
                ListTile(
                  leading: Icon(Icons.warning, color: Colors.orange),
                  title: Text('System Alert'),
                  subtitle: Text('High server load detected'),
                  contentPadding: EdgeInsets.zero,
                ),
                ListTile(
                  leading: Icon(Icons.security, color: Colors.red),
                  title: Text('Security Notice'),
                  subtitle: Text('Multiple failed login attempts'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/admin/notifications');
                },
                child: const Text('View All'),
              ),
            ],
          ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                ListTile(
                  leading: const Icon(Icons.person_add),
                  title: const Text('Add New User'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/admin/users/new');
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.verified_user),
                  title: const Text('Validate Doctors'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/admin/validations');
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.analytics),
                  title: const Text('System Analytics'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/admin/analytics');
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('System Settings'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/admin/settings');
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showMaintenanceMode() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('Enable Maintenance Mode'),
              ],
            ),
            content: const Text(
              'This will temporarily disable the system for all users except administrators. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Maintenance mode enabled'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Enable'),
              ),
            ],
          ),
    );
  }

  void _showSystemBackup() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.backup, color: Colors.blue),
                SizedBox(width: 8),
                Text('System Backup'),
              ],
            ),
            content: const Text(
              'Start a full system backup? This may affect system performance temporarily.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('System backup started'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Start Backup'),
              ),
            ],
          ),
    );
  }
}
