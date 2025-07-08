// =============================================================================
// System Stats Overview Widget
//
// Comprehensive system statistics overview for admin dashboard
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_dashboard_providers.dart';

class SystemStatsOverview extends ConsumerWidget {
  const SystemStatsOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsState = ref.watch(systemStatsProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.dashboard, color: Color(0xFF1565C0), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'System Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ],
                ),

                // Refresh button
                IconButton(
                  onPressed:
                      () =>
                          ref.read(systemStatsProvider.notifier).refreshStats(),
                  icon: const Icon(Icons.refresh, color: Color(0xFF1565C0)),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Stats Content
            if (statsState.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Color(0xFF1565C0)),
                ),
              )
            else if (statsState.error != null)
              _buildErrorState(statsState.error!)
            else
              _buildStatsGrid(statsState),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          Text(
            'Error loading statistics',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(SystemStats stats) {
    return Column(
      children: [
        // Top row - Main stats
        Row(
          children: [
            Expanded(
              child: _buildMainStatCard(
                'Total Users',
                stats.totalUsers.toString(),
                Icons.people,
                const Color(0xFF1565C0),
                '+12 this week',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMainStatCard(
                'Active Sessions',
                stats.todaySessions.toString(),
                Icons.monitor_heart,
                Colors.green,
                'Today',
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Bottom row - Secondary stats
        GridView.count(
          crossAxisCount: 3,
          childAspectRatio: 1.2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard(
              'Doctors',
              stats.totalDoctors.toString(),
              Icons.medical_services,
              Colors.blue,
            ),
            _buildStatCard(
              'Patients',
              stats.totalPatients.toString(),
              Icons.personal_injury,
              Colors.purple,
            ),
            _buildStatCard(
              'Pending',
              stats.pendingValidations.toString(),
              Icons.pending_actions,
              Colors.orange,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // System alerts summary
        if (stats.systemAlerts > 0)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${stats.systemAlerts} system alert${stats.systemAlerts > 1 ? 's' : ''} require attention',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to alerts page
                  },
                  child: const Text('View', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMainStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: color),

          const SizedBox(height: 8),

          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
