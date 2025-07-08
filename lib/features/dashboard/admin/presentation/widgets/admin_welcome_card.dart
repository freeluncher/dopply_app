// =============================================================================
// Admin Welcome Card Widget
//
// Modern welcome card for admin dashboard with personalized greeting
// and system status overview.
// =============================================================================

import 'package:flutter/material.dart';
import '../../../../../shared/models/user.dart';

class AdminWelcomeCard extends StatelessWidget {
  final User? user;

  const AdminWelcomeCard({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final currentHour = DateTime.now().hour;
    String greeting;

    if (currentHour < 12) {
      greeting = 'Good Morning';
    } else if (currentHour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1565C0).withOpacity(0.1),
            const Color(0xFF1976D2).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Admin Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF1565C0),
                child: Text(
                  _getInitials(user?.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Greeting and Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, Administrator',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _getWelcomeMessage(),
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),

                    const SizedBox(height: 8),

                    // System status indicator
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'All Systems Operational',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // System Health Menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Color(0xFF1565C0)),
                onSelected: (value) => _handleQuickAction(context, value),
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'system_status',
                        child: Row(
                          children: [
                            Icon(Icons.health_and_safety, size: 20),
                            SizedBox(width: 8),
                            Text('System Health'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'maintenance',
                        child: Row(
                          children: [
                            Icon(Icons.build, size: 20),
                            SizedBox(width: 8),
                            Text('Maintenance'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'backup',
                        child: Row(
                          children: [
                            Icon(Icons.backup, size: 20),
                            SizedBox(width: 8),
                            Text('System Backup'),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // System summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickStat('Uptime', '99.9%', Icons.trending_up),
                _buildQuickStat('Users', '142', Icons.people),
                _buildQuickStat('Load', 'Normal', Icons.speed),
                _buildQuickStat('Storage', '75%', Icons.storage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1565C0)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'AD';

    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
  }

  String _getWelcomeMessage() {
    final day = DateTime.now().weekday;
    final messages = [
      'System monitoring and management ready',
      'Start the week with system excellence!',
      'Keep the platform running smoothly',
      'Midweek system checks and optimization',
      'Almost weekend - maintain system stability',
      'Friday system reviews and updates',
      'Weekend vigilance for system health',
    ];

    return messages[day % messages.length];
  }

  void _handleQuickAction(BuildContext context, String action) {
    switch (action) {
      case 'system_status':
        _showSystemStatusDialog(context);
        break;
      case 'maintenance':
        _showMaintenanceDialog(context);
        break;
      case 'backup':
        _showBackupDialog(context);
        break;
    }
  }

  void _showSystemStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.health_and_safety, color: Colors.green),
                SizedBox(width: 8),
                Text('System Health Status'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Database'),
                  subtitle: Text('Online - Response time: 45ms'),
                  contentPadding: EdgeInsets.zero,
                ),
                ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('API Services'),
                  subtitle: Text('All endpoints operational'),
                  contentPadding: EdgeInsets.zero,
                ),
                ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Security'),
                  subtitle: Text('No threats detected'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showMaintenanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.build, color: Colors.orange),
                SizedBox(width: 8),
                Text('Maintenance Mode'),
              ],
            ),
            content: const Text(
              'Enable maintenance mode to perform system updates. This will temporarily restrict user access.',
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
                      content: Text('Maintenance mode scheduled'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Schedule'),
              ),
            ],
          ),
    );
  }

  void _showBackupDialog(BuildContext context) {
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
              'Create a full system backup including database, user data, and configurations.',
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
                      content: Text('Backup initiated successfully'),
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
