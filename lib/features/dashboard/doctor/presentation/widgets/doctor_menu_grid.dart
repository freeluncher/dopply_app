// =============================================================================
// Doctor Menu Grid Widget
//
// Grid of main navigation options for doctor dashboard
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DoctorMenuGrid extends StatelessWidget {
  final bool isEnabled;

  const DoctorMenuGrid({super.key, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
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
        child: GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildMenuCard(
              context,
              'Patient Monitoring',
              'Start real-time monitoring',
              Icons.monitor_heart,
              const Color(0xFF2E8B57),
              () => context.push('/doctor/monitoring'),
            ),
            _buildMenuCard(
              context,
              'Patient Management',
              'View and manage patients',
              Icons.people_alt,
              Colors.blue,
              () => context.push('/doctor/patients'),
            ),
            _buildMenuCard(
              context,
              'Medical Records',
              'Demo: Sample data only',
              Icons.medical_information,
              Colors.purple,
              () => _showDemoModeDialog(context, 'Medical Records'),
            ),
            _buildMenuCard(
              context,
              'Patient History',
              'View patient history',
              Icons.history,
              Colors.orange,
              () => context.push('/doctor/patient-history'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : () => _showVerificationDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isEnabled
                    ? color.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isEnabled
                      ? color.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with optional disabled overlay
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 40,
                      color: isEnabled ? color : Colors.grey,
                    ),
                    if (!isEnabled)
                      Icon(Icons.lock, size: 20, color: Colors.grey.shade600),
                  ],
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isEnabled ? color : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 4),

                // Subtitle
                Text(
                  isEnabled ? subtitle : 'Verification required',
                  style: TextStyle(
                    fontSize: 11,
                    color: isEnabled ? Colors.grey.shade600 : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('Verification Required'),
              ],
            ),
            content: const Text(
              'Your doctor account is pending verification. Once verified by an administrator, you will have access to all medical tools and patient management features.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to contact support or verification status
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contact admin for verification status'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                child: const Text('Contact Support'),
              ),
            ],
          ),
    );
  }

  void _showDemoModeDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.science, color: Colors.purple),
                SizedBox(width: 8),
                Text('$feature - Demo Mode'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The $feature feature is currently under development. You can still explore it with sample data.',
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '• Sample medical records\n• Demo patient data\n• UI/UX testing',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/doctor/medical-records');
                },
                child: const Text('Try Demo'),
              ),
            ],
          ),
    );
  }
}
