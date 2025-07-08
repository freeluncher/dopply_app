// =============================================================================
// Recent Patients List Widget
//
// Displays recently monitored or updated patients
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/doctor_dashboard_providers.dart';

class RecentPatientsList extends ConsumerWidget {
  const RecentPatientsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsState = ref.watch(doctorPatientsProvider);

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
                    Icon(Icons.people, color: Color(0xFF2E8B57), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Recent Patients',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E8B57),
                      ),
                    ),
                  ],
                ),

                TextButton(
                  onPressed: () => context.push('/doctor/patients'),
                  child: const Text('View All'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Content
            if (patientsState.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Color(0xFF2E8B57)),
                ),
              )
            else if (patientsState.error != null)
              _buildErrorState(patientsState.error!)
            else if (patientsState.patients.isEmpty)
              _buildEmptyState(context)
            else
              _buildPatientsList(context, patientsState.patients),
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
            'Error loading patients',
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No Patients Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start monitoring patients to see them here',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push('/doctor/patients/new'),
            icon: const Icon(Icons.add),
            label: const Text('Add Patient'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E8B57),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsList(
    BuildContext context,
    List<Map<String, dynamic>> patients,
  ) {
    // Show all patients if <= 5, otherwise show first 5 with "view more" option
    final displayPatients =
        patients.length <= 5 ? patients : patients.take(5).toList();

    return Column(
      children: [
        ...displayPatients.map(
          (patient) => _buildPatientCard(context, patient),
        ),

        if (patients.length > 5) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2E8B57).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.more_horiz,
                  color: const Color(0xFF2E8B57),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${patients.length - 5} more patients',
                  style: const TextStyle(
                    color: Color(0xFF2E8B57),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPatientCard(BuildContext context, Map<String, dynamic> patient) {
    // Extract real patient data safely with null checks
    final name = patient['name'] as String? ?? 'Unknown Patient';
    final age = patient['age'] as int?; // This might be null in real data
    final status = patient['status'] as String? ?? 'unknown';
    final lastRecordDate = patient['last_record_date'] as String?;
    final assignmentDate = patient['assignment_date'] as String?;

    // Calculate time since last activity
    DateTime? lastActivity;
    if (lastRecordDate != null) {
      try {
        lastActivity = DateTime.parse(lastRecordDate);
      } catch (e) {
        lastActivity = null;
      }
    }

    // Fallback to assignment date if no records
    if (lastActivity == null && assignmentDate != null) {
      try {
        lastActivity = DateTime.parse(assignmentDate);
      } catch (e) {
        lastActivity = DateTime.now().subtract(const Duration(days: 1));
      }
    }
    lastActivity ??= DateTime.now().subtract(const Duration(days: 1));

    final timeSinceMonitored = DateTime.now().difference(lastActivity);
    final timeText = _formatTimeDifference(timeSinceMonitored);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/doctor/patients/${patient['id']}'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor(status).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                // Patient avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF2E8B57),
                  child: Text(
                    _getInitials(name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Patient details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildStatusChip(status),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          if (age != null)
                            Text(
                              'Age: $age',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            )
                          else
                            Text(
                              'Age: N/A',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Last monitored: $timeText',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action button
                IconButton(
                  onPressed: () => _showPatientMenu(context, patient),
                  icon: const Icon(Icons.more_vert),
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'monitoring':
        color = Colors.orange;
        label = 'Monitoring';
        icon = Icons.monitor_heart;
        break;
      case 'normal':
        color = Colors.green;
        label = 'Normal';
        icon = Icons.check_circle;
        break;
      case 'alert':
        color = Colors.red;
        label = 'Alert';
        icon = Icons.warning;
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'monitoring':
        return Colors.orange;
      case 'normal':
        return Colors.green;
      case 'alert':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTimeDifference(Duration difference) {
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showPatientMenu(BuildContext context, Map<String, dynamic> patient) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  patient['name'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                ListTile(
                  leading: const Icon(Icons.visibility),
                  title: const Text('View Profile'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/doctor/patients/${patient['id']}');
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.monitor_heart),
                  title: const Text('Start Monitoring'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/doctor/monitoring?patient=${patient['id']}');
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.medical_information),
                  title: const Text('Medical Records'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/doctor/patients/${patient['id']}/records');
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.message),
                  title: const Text('Send Message'),
                  onTap: () {
                    Navigator.of(context).pop();
                    // Implement messaging
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Messaging feature coming soon'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }
}
