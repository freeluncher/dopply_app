// =============================================================================
// Pending Validations Card Widget - New Architecture
//
// Card displaying pending doctor validations and approval requests.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_dashboard_providers.dart';

class PendingValidationsCard extends ConsumerWidget {
  const PendingValidationsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userManagementState = ref.watch(userManagementProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFED7D7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.pending_actions,
                    color: Color(0xFFE53E3E),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending Validations',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        'Doctor approvals needed',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Content based on state
            if (userManagementState.isLoading)
              _buildLoadingContent()
            else if (userManagementState.error != null)
              _buildErrorContent(context, userManagementState.error)
            else
              _buildValidationsContent(context, userManagementState),

            const SizedBox(height: 16),

            // View All Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push('/admin/doctor-validation'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE53E3E),
                  side: const BorderSide(color: Color(0xFFE53E3E)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('View All Validations'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53E3E)),
        ),
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context, String? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: const Color(0xFFE53E3E), size: 32),
            const SizedBox(height: 8),
            Text(
              'Failed to load validations',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF718096)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationsContent(
    BuildContext context,
    UserManagementState state,
  ) {
    final pendingDoctors = state.pendingDoctors;

    if (pendingDoctors.isEmpty) {
      return _buildEmptyContent(context);
    }

    return Column(
      children: [
        // Stats Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem(
              context,
              'Pending',
              pendingDoctors.length.toString(),
              const Color(0xFFE53E3E),
            ),
            _buildStatItem(
              context,
              'This Week',
              _getThisWeekCount(pendingDoctors).toString(),
              const Color(0xFFD69E2E),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Recent Pending Items
        ...pendingDoctors
            .take(3)
            .map((doctor) => _buildValidationItem(context, doctor)),
      ],
    );
  }

  Widget _buildEmptyContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: const Color(0xFF38A169),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'No pending validations',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF718096)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF718096)),
        ),
      ],
    );
  }

  Widget _buildValidationItem(
    BuildContext context,
    Map<String, dynamic> doctor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFE53E3E).withOpacity(0.1),
            child: Text(
              doctor['name']?.substring(0, 1).toUpperCase() ?? 'D',
              style: const TextStyle(
                color: Color(0xFFE53E3E),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor['name'] ?? 'Unknown Doctor',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  doctor['specialty'] ?? 'General Practice',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF718096),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE53E3E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getTimeAgo(doctor['submittedAt']),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFFE53E3E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getThisWeekCount(List<Map<String, dynamic>> doctors) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    return doctors.where((doctor) {
      final submittedAt = DateTime.tryParse(doctor['submittedAt'] ?? '');
      return submittedAt != null && submittedAt.isAfter(weekStart);
    }).length;
  }

  String _getTimeAgo(String? dateTimeString) {
    if (dateTimeString == null) return 'Unknown';

    final submittedAt = DateTime.tryParse(dateTimeString);
    if (submittedAt == null) return 'Unknown';

    final difference = DateTime.now().difference(submittedAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
