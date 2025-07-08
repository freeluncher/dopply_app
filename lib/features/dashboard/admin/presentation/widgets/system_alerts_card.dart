// =============================================================================
// System Alerts Card Widget - New Architecture
//
// Card displaying critical system alerts and notifications.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_dashboard_providers.dart';

class SystemAlertsCard extends ConsumerWidget {
  const SystemAlertsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemStats = ref.watch(systemStatsProvider);

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
                    color: _getAlertHeaderColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getAlertIcon(),
                    color: _getAlertHeaderColor(),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Alerts',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        '${systemStats.systemAlerts} active alerts',
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
            if (systemStats.isLoading)
              _buildLoadingContent()
            else if (systemStats.error != null)
              _buildErrorContent(context, systemStats.error)
            else
              _buildAlertsContent(context, systemStats),

            const SizedBox(height: 16),

            // View All Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push('/admin/alerts'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _getAlertHeaderColor(),
                  side: BorderSide(color: _getAlertHeaderColor()),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('View All Alerts'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAlertHeaderColor() {
    return const Color(0xFFD69E2E); // Warning yellow
  }

  IconData _getAlertIcon() {
    return Icons.warning_amber;
  }

  Widget _buildLoadingContent() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD69E2E)),
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
              'Failed to load alerts',
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

  Widget _buildAlertsContent(BuildContext context, SystemStats stats) {
    final alerts = _getMockAlerts();

    if (alerts.isEmpty) {
      return _buildNoAlertsContent(context);
    }

    return Column(
      children: [
        // Alert Summary
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildAlertStat(
              context,
              'Critical',
              _getCriticalCount(alerts).toString(),
              const Color(0xFFE53E3E),
            ),
            _buildAlertStat(
              context,
              'Warning',
              _getWarningCount(alerts).toString(),
              const Color(0xFFD69E2E),
            ),
            _buildAlertStat(
              context,
              'Info',
              _getInfoCount(alerts).toString(),
              const Color(0xFF3182CE),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Recent Alerts
        ...alerts.take(3).map((alert) => _buildAlertItem(context, alert)),
      ],
    );
  }

  Widget _buildNoAlertsContent(BuildContext context) {
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
              'No active alerts',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF718096)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'All systems running normally',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF718096)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertStat(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF718096)),
        ),
      ],
    );
  }

  Widget _buildAlertItem(BuildContext context, Map<String, dynamic> alert) {
    final severity = alert['severity'] as String;
    final color = _getSeverityColor(severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(_getSeverityIcon(severity), color: color, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['title'] ?? 'Unknown Alert',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  alert['description'] ?? 'No description available',
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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getTimeAgo(alert['timestamp']),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getMockAlerts() {
    return [
      {
        'id': '1',
        'title': 'High Server Load',
        'description': 'CPU usage above 85% for 10 minutes',
        'severity': 'critical',
        'timestamp':
            DateTime.now()
                .subtract(const Duration(minutes: 15))
                .toIso8601String(),
        'category': 'performance',
      },
      {
        'id': '2',
        'title': 'API Rate Limit Warning',
        'description': 'API calls approaching daily limit',
        'severity': 'warning',
        'timestamp':
            DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'category': 'api',
      },
      {
        'id': '3',
        'title': 'Database Backup Complete',
        'description': 'Daily backup completed successfully',
        'severity': 'info',
        'timestamp':
            DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
        'category': 'backup',
      },
    ];
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFE53E3E);
      case 'warning':
        return const Color(0xFFD69E2E);
      case 'info':
        return const Color(0xFF3182CE);
      default:
        return const Color(0xFF718096);
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      case 'info':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  int _getCriticalCount(List<Map<String, dynamic>> alerts) {
    return alerts.where((alert) => alert['severity'] == 'critical').length;
  }

  int _getWarningCount(List<Map<String, dynamic>> alerts) {
    return alerts.where((alert) => alert['severity'] == 'warning').length;
  }

  int _getInfoCount(List<Map<String, dynamic>> alerts) {
    return alerts.where((alert) => alert['severity'] == 'info').length;
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
