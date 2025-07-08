// =============================================================================
// Doctor Welcome Card Widget
//
// Modern welcome card for doctor dashboard with personalized greeting
// and quick status overview.
// =============================================================================

import 'package:flutter/material.dart';
import '../../../../../shared/models/user.dart';

class DoctorWelcomeCard extends StatelessWidget {
  final User? user;

  const DoctorWelcomeCard({super.key, this.user});

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
            const Color(0xFF2E8B57).withOpacity(0.1),
            const Color(0xFF3CB371).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E8B57).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Doctor Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF2E8B57),
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
                      '$greeting, Dr. ${_getFirstName(user?.name)}!',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E8B57),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _getWelcomeMessage(user?.name),
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),

                    const SizedBox(height: 8),

                    // Status indicator
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                user?.isValid == true
                                    ? Colors.green
                                    : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user?.isValid == true
                              ? 'Verified Account'
                              : 'Pending Verification',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                user?.isValid == true
                                    ? Colors.green
                                    : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Quick Actions Menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Color(0xFF2E8B57)),
                onSelected: (value) => _handleQuickAction(context, value),
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person, size: 20),
                            SizedBox(width: 8),
                            Text('View Profile'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings, size: 20),
                            SizedBox(width: 8),
                            Text('Settings'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'help',
                        child: Row(
                          children: [
                            Icon(Icons.help, size: 20),
                            SizedBox(width: 8),
                            Text('Help'),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Today's summary
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
                _buildQuickStat(
                  'Today',
                  '${DateTime.now().day}',
                  Icons.calendar_today,
                ),
                _buildQuickStat('Time', _getCurrentTime(), Icons.access_time),
                _buildQuickStat(
                  'Status',
                  user?.isValid == true ? 'Active' : 'Pending',
                  Icons.verified_user,
                ),
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
        Icon(icon, size: 20, color: const Color(0xFF2E8B57)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E8B57),
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'DR';
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].length >= 2) {
      return parts[0].substring(0, 2).toUpperCase();
    }
    return parts.isNotEmpty ? parts[0].toUpperCase() : 'DR';
  }

  String _getFirstName(String? name) {
    if (name == null || name.trim().isEmpty) return 'Doctor';

    // Clean the name and split into parts
    String cleanName = name.trim().replaceAll(
      RegExp(r'[^\w\s]'),
      ' ',
    ); // Replace punctuation with spaces
    List<String> parts =
        cleanName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();

    if (parts.isEmpty) return 'Doctor';

    // Skip common titles and get the actual first name
    final titlesToSkip = {'dr', 'prof', 'professor', 'mr', 'ms', 'mrs', 'miss'};

    for (final part in parts) {
      if (!titlesToSkip.contains(part.toLowerCase())) {
        // Return the first non-title word, properly capitalized
        return part[0].toUpperCase() + part.substring(1).toLowerCase();
      }
    }

    // If all parts are titles, return fallback
    return 'Doctor';
  }

  String _getWelcomeMessage(String? userName) {
    final day = DateTime.now().weekday;
    final firstName = _getFirstName(userName);

    final messages = [
      'Ready to help patients today, Dr. $firstName?',
      'Hope you have a productive Monday, Dr. $firstName!',
      'Another day to make a difference, Dr. $firstName!',
      'Midweek motivation for great care, Dr. $firstName!',
      'Almost there - keep up the excellent work, Dr. $firstName!',
      'Friday energy for patient care, Dr. $firstName!',
      'Weekend dedication is admirable, Dr. $firstName!',
    ];

    return messages[day % messages.length];
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _handleQuickAction(BuildContext context, String action) {
    switch (action) {
      case 'profile':
        // Navigate to profile
        break;
      case 'settings':
        // Navigate to settings
        break;
      case 'help':
        // Show help dialog
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Help & Support'),
                content: const Text(
                  'Need assistance? Contact support at support@dopply.com',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
        );
        break;
    }
  }
}
