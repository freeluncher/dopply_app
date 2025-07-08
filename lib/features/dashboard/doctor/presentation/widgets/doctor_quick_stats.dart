// =============================================================================
// Doctor Quick Stats Widget
//
// Quick overview of key statistics for the doctor dashboard
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/doctor_dashboard_providers.dart';

class DoctorQuickStats extends ConsumerWidget {
  final bool isEnabled;

  const DoctorQuickStats({super.key, required this.isEnabled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsState = ref.watch(doctorStatsProvider);

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
            const Row(
              children: [
                Icon(Icons.analytics, color: Color(0xFF2E8B57), size: 24),
                SizedBox(width: 8),
                Text(
                  'Quick Stats',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E8B57),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Stats Grid
            if (statsState.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Color(0xFF2E8B57)),
                ),
              )
            else if (statsState.error != null)
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Error loading stats',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statsState.error!,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              _buildStatsGrid(statsState),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(DoctorStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          'Total Patients',
          stats.totalPatients.toString(),
          Icons.people,
          const Color(0xFF2E8B57),
          isEnabled,
        ),
        _buildStatCard(
          'Active Monitoring',
          stats.activeMonitoring.toString(),
          Icons.monitor_heart,
          Colors.orange,
          isEnabled,
        ),
        _buildStatCard(
          'Today\'s Sessions',
          stats.todaysSessions.toString(),
          Icons.schedule,
          Colors.blue,
          isEnabled,
        ),
        _buildStatCard(
          'Pending Reviews',
          stats.pendingReviews.toString(),
          Icons.pending_actions,
          Colors.purple,
          isEnabled,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool enabled,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            enabled ? color.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              enabled ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: enabled ? color : Colors.grey),

          const SizedBox(height: 4),

          Flexible(
            child: Text(
              enabled ? value : '—',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: enabled ? color : Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 2),

          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: enabled ? Colors.grey.shade700 : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Disabled overlay
          if (!enabled) ...[
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Disabled',
                style: TextStyle(fontSize: 9, color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
