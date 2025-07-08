// =============================================================================
// Routing Integration Example
//
// Example of how to integrate new fetal monitoring pages into app routing
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import new pages
// Import the required dashboard pages
import 'package:dopply_app/features/dashboard/doctor/presentation/pages/doctor_dashboard.dart';
import 'package:dopply_app/features/patient/presentation/pages/patient_dashboard.dart';
import 'package:dopply_app/features/doctor/presentation/pages/modern_fetal_monitoring_page.dart';
import 'package:dopply_app/features/patient/presentation/pages/modern_fetal_monitoring_page_patient.dart';

// Example router configuration
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // ... existing routes ...

    // Doctor routes
    GoRoute(
      path: '/doctor',
      builder: (context, state) => const DoctorDashboard(),
      routes: [
        // Existing doctor routes...

        // NEW: Modern fetal monitoring page
        GoRoute(
          path: '/modern-monitoring',
          name: 'doctor-modern-monitoring',
          builder: (context, state) => const ModernFetalMonitoringPage(),
        ),

        // Optional: Redirect old monitoring route to new one
        GoRoute(
          path: '/monitoring',
          redirect: (context, state) => '/doctor/modern-monitoring',
        ),
      ],
    ),

    // Patient routes
    GoRoute(
      path: '/patient',
      builder: (context, state) => const PatientDashboard(),
      routes: [
        // Existing patient routes...

        // NEW: Modern fetal monitoring page for patients
        GoRoute(
          path: '/modern-monitoring',
          name: 'patient-modern-monitoring',
          builder: (context, state) => const ModernFetalMonitoringPagePatient(),
        ),

        // Optional: Redirect old monitoring route to new one
        GoRoute(
          path: '/monitoring',
          redirect: (context, state) => '/patient/modern-monitoring',
        ),
      ],
    ),

    // ... other existing routes ...
  ],
);

// Example usage in dashboard widgets

// Doctor Dashboard - Update monitoring button
class DoctorMenuItem extends StatelessWidget {
  const DoctorMenuItem({super.key});

  // ... existing code ...

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.monitor_heart),
        title: Text('Monitoring Detak Jantung Janin'),
        subtitle: Text('Pantau detak jantung janin secara real-time'),
        onTap: () {
          // NEW: Navigate to modern monitoring page
          context.go('/doctor/modern-monitoring');
        },
      ),
    );
  }
}

// Patient Dashboard - Update monitoring button
class PatientMenuItem extends StatelessWidget {
  const PatientMenuItem({super.key});

  // ... existing code ...

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.health_and_safety),
        title: Text('Monitoring Mandiri'),
        subtitle: Text('Pantau detak jantung janin dari rumah'),
        onTap: () {
          // NEW: Navigate to modern monitoring page for patients
          context.go('/patient/modern-monitoring');
        },
      ),
    );
  }
}

// Feature flag example for gradual rollout
class FeatureFlags {
  static const bool useModernMonitoring = true; // Set to false to rollback
  static const bool showLegacyOption =
      false; // Show old option during transition
}

// Example with feature flag
class ConditionalMonitoringButton extends StatelessWidget {
  final bool isDoctor;

  const ConditionalMonitoringButton({super.key, required this.isDoctor});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        if (FeatureFlags.useModernMonitoring) {
          // Use new modern monitoring
          if (isDoctor) {
            context.go('/doctor/modern-monitoring');
          } else {
            context.go('/patient/modern-monitoring');
          }
        } else {
          // Fallback to legacy monitoring
          if (isDoctor) {
            context.go('/doctor/monitoring');
          } else {
            context.go('/patient/monitoring');
          }
        }
      },
      child: Text('Mulai Monitoring'),
    );
  }
}

// Example navigation helper
class MonitoringNavigation {
  static void navigateToMonitoring(
    BuildContext context, {
    required bool isDoctor,
  }) {
    if (FeatureFlags.useModernMonitoring) {
      if (isDoctor) {
        context.go('/doctor/modern-monitoring');
      } else {
        context.go('/patient/modern-monitoring');
      }
    } else {
      if (isDoctor) {
        context.go('/doctor/monitoring');
      } else {
        context.go('/patient/monitoring');
      }
    }
  }
}
