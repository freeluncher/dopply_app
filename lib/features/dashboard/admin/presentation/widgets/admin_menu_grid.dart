// =============================================================================
// Admin Menu Grid Widget - New Architecture
//
// Modern grid layout for admin management tools and system controls.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminMenuGrid extends ConsumerWidget {
  const AdminMenuGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuItems = _getMenuItems(context);

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
            Text(
              'System Management',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Administrative tools and controls',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF718096)),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return _buildMenuItem(context, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  List<AdminMenuItem> _getMenuItems(BuildContext context) {
    return [
      AdminMenuItem(
        title: 'User Management',
        subtitle: 'Manage users & roles',
        icon: Icons.people,
        color: const Color(0xFF3182CE),
        onTap: () => context.push('/admin/users'),
      ),
      AdminMenuItem(
        title: 'Doctor Validation',
        subtitle: 'Validate doctors',
        icon: Icons.verified_user,
        color: const Color(0xFF38A169),
        onTap: () => context.push('/admin/doctor-validation'),
      ),
      AdminMenuItem(
        title: 'System Analytics',
        subtitle: 'Usage & metrics',
        icon: Icons.analytics,
        color: const Color(0xFF805AD5),
        onTap: () => context.push('/admin/analytics'),
      ),
      AdminMenuItem(
        title: 'Content Management',
        subtitle: 'Manage app content',
        icon: Icons.article,
        color: const Color(0xFFD69E2E),
        onTap: () => context.push('/admin/content'),
      ),
      AdminMenuItem(
        title: 'System Settings',
        subtitle: 'Configure system',
        icon: Icons.settings,
        color: const Color(0xFF718096),
        onTap: () => context.push('/admin/settings'),
      ),
      AdminMenuItem(
        title: 'API Management',
        subtitle: 'API keys & limits',
        icon: Icons.api,
        color: const Color(0xFF319795),
        onTap: () => context.push('/admin/api'),
      ),
      AdminMenuItem(
        title: 'Security Center',
        subtitle: 'Security & audit',
        icon: Icons.security,
        color: const Color(0xFFE53E3E),
        onTap: () => context.push('/admin/security'),
      ),
      AdminMenuItem(
        title: 'Backup & Restore',
        subtitle: 'Data management',
        icon: Icons.backup,
        color: const Color(0xFF1A202C),
        onTap: () => context.push('/admin/backup'),
      ),
    ];
  }

  Widget _buildMenuItem(BuildContext context, AdminMenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: item.color.withOpacity(0.1), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3748),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF718096),
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
}

class AdminMenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  AdminMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
