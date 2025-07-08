// =============================================================================
// Recent Activities List Widget - New Architecture
//
// Displays recent system activities and user actions for admin monitoring.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_dashboard_providers.dart';

class RecentActivitiesList extends ConsumerWidget {
  const RecentActivitiesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(systemAnalyticsProvider);

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Activities',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Latest system events and user activities',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.push('/admin/activities'),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: const Color(0xFF3182CE),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Content based on state
            if (analyticsState.isLoading)
              _buildLoadingContent()
            else if (analyticsState.error != null)
              _buildErrorContent(context, analyticsState.error)
            else
              _buildActivitiesContent(context, analyticsState),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3182CE)),
        ),
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context, String? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: const Color(0xFFE53E3E), size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load activities',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF2D3748),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again later',
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

  Widget _buildActivitiesContent(
    BuildContext context,
    SystemAnalyticsState state,
  ) {
    final activities = _getMockActivities();

    if (activities.isEmpty) {
      return _buildEmptyContent(context);
    }

    return Column(
      children: [
        // Activity Filter Tabs
        _buildFilterTabs(context),

        const SizedBox(height: 20),

        // Activities List
        ...activities.map((activity) => _buildActivityItem(context, activity)),

        if (activities.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Center(
              child: TextButton(
                onPressed: () => context.push('/admin/activities'),
                child: Text(
                  'Load More Activities',
                  style: TextStyle(
                    color: const Color(0xFF3182CE),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.history, color: const Color(0xFF718096), size: 48),
            const SizedBox(height: 16),
            Text(
              'No recent activities',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF2D3748),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'System activities will appear here',
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

  Widget _buildFilterTabs(BuildContext context) {
    final tabs = ['All', 'Users', 'System', 'Security'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            tabs
                .map((tab) => _buildFilterTab(context, tab, tab == 'All'))
                .toList(),
      ),
    );
  }

  Widget _buildFilterTab(BuildContext context, String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Handle tab selection
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3182CE) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isSelected
                        ? const Color(0xFF3182CE)
                        : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? Colors.white : const Color(0xFF718096),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    Map<String, dynamic> activity,
  ) {
    final type = activity['type'] as String;
    final color = _getActivityColor(type);
    final icon = _getActivityIcon(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Activity Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),

          const SizedBox(width: 16),

          // Activity Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        activity['title'] ?? 'Unknown Activity',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2D3748),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        type.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  activity['description'] ?? 'No description available',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF718096),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 14,
                      color: const Color(0xFF718096),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      activity['user'] ?? 'System',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF718096),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: const Color(0xFF718096),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getTimeAgo(activity['timestamp']),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF718096),
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

  List<Map<String, dynamic>> _getMockActivities() {
    return [
      {
        'id': '1',
        'type': 'user',
        'title': 'New Doctor Registration',
        'description':
            'Dr. Maria Garcia completed registration and submitted documents for validation',
        'user': 'Dr. Maria Garcia',
        'timestamp':
            DateTime.now()
                .subtract(const Duration(minutes: 5))
                .toIso8601String(),
      },
      {
        'id': '2',
        'type': 'system',
        'title': 'Database Backup Completed',
        'description':
            'Automated daily backup completed successfully at 2:00 AM',
        'user': 'System',
        'timestamp':
            DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      },
      {
        'id': '3',
        'type': 'security',
        'title': 'Failed Login Attempt',
        'description':
            'Multiple failed login attempts detected from IP 192.168.1.100',
        'user': 'Security Monitor',
        'timestamp':
            DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'id': '4',
        'type': 'user',
        'title': 'Patient Profile Updated',
        'description':
            'John Smith updated medical history and emergency contacts',
        'user': 'John Smith',
        'timestamp':
            DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      },
      {
        'id': '5',
        'type': 'system',
        'title': 'API Rate Limit Adjusted',
        'description':
            'Increased rate limit for premium tier users from 1000 to 2000 requests/hour',
        'user': 'Admin',
        'timestamp':
            DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
      },
    ];
  }

  Color _getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'user':
        return const Color(0xFF3182CE);
      case 'system':
        return const Color(0xFF38A169);
      case 'security':
        return const Color(0xFFE53E3E);
      case 'admin':
        return const Color(0xFF805AD5);
      default:
        return const Color(0xFF718096);
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'user':
        return Icons.person_add;
      case 'system':
        return Icons.settings;
      case 'security':
        return Icons.security;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.notifications;
    }
  }

  String _getTimeAgo(String? dateTimeString) {
    if (dateTimeString == null) return 'Unknown';

    final timestamp = DateTime.tryParse(dateTimeString);
    if (timestamp == null) return 'Unknown';

    final difference = DateTime.now().difference(timestamp);

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
