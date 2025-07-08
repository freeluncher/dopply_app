// ============================================================================
// router.dart
//
// File ini berisi konfigurasi routing utama aplikasi Dopply App menggunakan
// package go_router dan Riverpod. Semua halaman utama (admin, dokter, pasien)
// serta halaman login, register, dan pengaturan akun diatur di sini.
//
// Fitur utama:
// - Routing berbasis path dan nama route
// - Guard/redirect otomatis berdasarkan status autentikasi dan role user
// - Modular: mudah menambah/mengedit rute baru
//
// Struktur route:
//   '/'                       : SplashScreen
//   '/login'                  : LoginPage
//   '/register'               : RegisterPage
//   '/adminDashboard'         : AdminDashboard
//   '/admin/users'            : ManageUsersPage (manajemen user admin)
//   '/doctorDashboard'        : DoctorDashboard
//   '/doctor/monitoring'      : ModernFetalMonitoringPage (dokter)
//   '/doctor/patient-history' : PatientHistoryPage (dokter)
//   '/doctor/patient-history/:id' : PatientHistoryDetailPage (dokter)
//   '/doctor/patients'        : DoctorPatientsPage
//   '/patientDashboard'       : PatientDashboard
//   '/patient/self-monitoring': ModernFetalMonitoringPagePatient
//   '/patient/history'        : MonitoringHistoryPagePatient
//   '/patient/account-settings': AccountSettingsPagePatient
//   '/account-settings'       : AccountSettingsPage (umum)
//
// Guard/redirect:
//   - Menggunakan AuthGuardService.canAccess untuk membatasi akses halaman
//     sesuai status login dan role user.
//
// Cara menambah route baru:
//   1. Import halaman baru di bagian atas file ini.
//   2. Tambahkan GoRoute baru ke dalam list routes.
//   3. (Opsional) Tambahkan nama route untuk navigasi lebih mudah.
//
// Contoh navigasi:
//   context.go('/adminDashboard'); // replace
//   context.push('/admin/users');  // push ke stack
//
// Untuk penggunaan di main.dart, gunakan routerProvider dari Riverpod.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import halaman-halaman utama - New Structure
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/account_settings_page.dart';

// Doctor feature imports
import '../features/doctor/presentation/pages/medical_records_page.dart';
import '../features/doctor/presentation/pages/patient_monitoring_history_page.dart';
import '../features/doctor/data/models/doctor_patient.dart';

// Old structure imports (to be migrated)
import '../features/dashboard/admin/presentation/pages/admin_dashboard.dart';
import '../features/dashboard/doctor/presentation/pages/doctor_dashboard.dart';
import '../features/patient/presentation/pages/patient_dashboard.dart';
import '../features/doctor/presentation/pages/patient_history_page.dart';
import '../features/doctor/presentation/pages/patient_history_detail_page.dart';
import '../features/admin/presentation/pages/manage_users_page.dart';
import '../features/doctor/presentation/pages/doctor_patients_page.dart';
import 'package:dopply_app/features/patient/presentation/pages/monitoring_history_page_patient.dart';
import 'package:dopply_app/features/patient/presentation/pages/account_settings_page_patient.dart';
import 'package:dopply_app/features/doctor/data/models/patient_history_record.dart';

// New modern monitoring pages
import '../features/doctor/presentation/pages/modern_fetal_monitoring_page.dart';
import '../features/patient/presentation/pages/modern_fetal_monitoring_page_patient.dart';

// Import services and providers
import '../features/auth/presentation/providers/user_provider.dart';
import '../shared/services/auth_guard_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => LoginPage(),
      ),
      GoRoute(
        path: '/adminDashboard',
        name: 'adminDashboard',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/doctorDashboard',
        name: 'doctorDashboard',
        builder: (context, state) => const DoctorDashboard(),
      ),
      GoRoute(
        path: '/doctor/monitoring',
        builder: (context, state) => const ModernFetalMonitoringPage(),
      ),
      GoRoute(
        path: '/doctor/add-patient',
        builder:
            (context, state) =>
                Scaffold(body: Center(child: Text('Tambah Pasien'))),
      ),
      GoRoute(
        path: '/doctor/patient-history',
        builder: (context, state) => const PatientHistoryPage(),
      ),
      GoRoute(
        path: '/doctor/patient-history/:id',
        builder: (context, state) {
          final map = state.extra as Map<String, dynamic>? ?? {};
          final record = PatientHistoryRecord.fromMap(map);
          return PatientHistoryDetailPage(record: record);
        },
      ),
      GoRoute(
        path: '/doctor/new-patients',
        builder:
            (context, state) =>
                Scaffold(body: Center(child: Text('Pasien Terbaru'))),
      ),
      GoRoute(
        path: '/doctor/account-settings',
        builder:
            (context, state) =>
                Scaffold(body: Center(child: Text('Account Settings'))),
      ),
      GoRoute(
        path: '/doctor/patients',
        builder: (context, state) => const DoctorPatientsPage(),
      ),
      GoRoute(
        path: '/doctor/medical-records',
        builder: (context, state) => const MedicalRecordsPage(),
      ),
      GoRoute(
        path: '/doctor/patient-monitoring-history',
        builder: (context, state) {
          final patient = state.extra as DoctorPatient;
          return PatientMonitoringHistoryPage(patient: patient);
        },
      ),
      GoRoute(
        path: '/patientDashboard',
        name: 'patientDashboard',
        builder: (context, state) => const PatientDashboard(),
      ),
      GoRoute(
        path: '/patient/self-monitoring',
        builder: (context, state) => const ModernFetalMonitoringPagePatient(),
      ),
      GoRoute(
        path: '/patient/history',
        builder: (context, state) => const MonitoringHistoryPagePatient(),
      ),
      GoRoute(
        path: '/patient/account-settings',
        builder: (context, state) => const AccountSettingsPagePatient(),
      ),
      GoRoute(
        path: '/account-settings',
        builder: (context, state) => const AccountSettingsPage(),
      ),
      // GoRoute(
      //   path: '/patientDashboard',
      //   name: 'patientDashboard',
      //   builder: (context, state) => const PatientDashboard(),
      // ),
      // Admin Routes
      GoRoute(
        path: '/admin/users',
        name: 'adminUsers',
        builder: (context, state) => const ManageUsersPage(),
      ),
      GoRoute(
        path: '/admin/doctor-validation',
        name: 'adminDoctorValidation',
        builder:
            (context, state) => Scaffold(
              appBar: AppBar(title: const Text('Doctor Validation')),
              body: const Center(child: Text('Doctor Validation Page')),
            ),
      ),
      GoRoute(
        path: '/admin/analytics',
        name: 'adminAnalytics',
        builder:
            (context, state) => Scaffold(
              appBar: AppBar(title: const Text('System Analytics')),
              body: const Center(child: Text('System Analytics Page')),
            ),
      ),
      GoRoute(
        path: '/admin/content',
        name: 'adminContent',
        builder:
            (context, state) => Scaffold(
              appBar: AppBar(title: const Text('Content Management')),
              body: const Center(child: Text('Content Management Page')),
            ),
      ),
      GoRoute(
        path: '/admin/settings',
        name: 'adminSettings',
        builder:
            (context, state) => Scaffold(
              appBar: AppBar(title: const Text('System Settings')),
              body: const Center(child: Text('System Settings Page')),
            ),
      ),
      GoRoute(
        path: '/admin/api',
        name: 'adminApi',
        builder:
            (context, state) => Scaffold(
              appBar: AppBar(title: const Text('API Management')),
              body: const Center(child: Text('API Management Page')),
            ),
      ),
      GoRoute(
        path: '/admin/security',
        name: 'adminSecurity',
        builder:
            (context, state) => Scaffold(
              appBar: AppBar(title: const Text('Security Center')),
              body: const Center(child: Text('Security Center Page')),
            ),
      ),
      GoRoute(
        path: '/admin/backup',
        name: 'adminBackup',
        builder:
            (context, state) => Scaffold(
              appBar: AppBar(title: const Text('Backup & Restore')),
              body: const Center(child: Text('Backup & Restore Page')),
            ),
      ),
      GoRoute(
        path: '/admin/alerts',
        name: 'adminAlerts',
        builder:
            (context, state) => Scaffold(
              appBar: AppBar(title: const Text('System Alerts')),
              body: const Center(child: Text('System Alerts Page')),
            ),
      ),
      GoRoute(
        path: '/admin/activities',
        name: 'adminActivities',
        builder:
            (context, state) => Scaffold(
              appBar: AppBar(title: const Text('System Activities')),
              body: const Center(child: Text('System Activities Page')),
            ),
      ),
      GoRoute(
        path: '/admin/reports',
        name: 'adminReports',
        builder:
            (context, state) => Scaffold(
              appBar: AppBar(title: const Text('Reports')),
              body: const Center(child: Text('Admin Reports Page')),
            ),
      ),
    ],
    redirect: (context, state) {
      final user = ref.read(userProvider);
      return AuthGuardService.canAccess(state, user);
    },
  );
});

// Contoh penggunaan di main.dart:
// Widget build(BuildContext context, WidgetRef ref) {
//   final router = ref.watch(routerProvider);
//   return MaterialApp.router(
//     routerConfig: router,
//     // ...existing code...
//   );
// }

// Navigasi modular:
// context.go('/adminDashboard'); // replace
// context.push('/admin/users');  // push ke stack
