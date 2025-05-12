import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import halaman-halaman utama
import '../features/auth/presentation/pages/login_page.dart';
import '../features/admin/presentation/pages/admin_dashboard.dart';
import '../features/auth/presentation/pages/register_page.dart';
// import '../features/doctor/presentation/pages/doctor_dashboard.dart';
// import '../features/patient/presentation/pages/patient_dashboard.dart';
// import fitur lain sesuai kebutuhan...
import '../features/auth/presentation/viewmodels/user_provider.dart';
import '../core/services/auth_guard_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => LoginPage(),
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
      // GoRoute(
      //   path: '/doctorDashboard',
      //   name: 'doctorDashboard',
      //   builder: (context, state) => const DoctorDashboard(),
      // ),
      // GoRoute(
      //   path: '/patientDashboard',
      //   name: 'patientDashboard',
      //   builder: (context, state) => const PatientDashboard(),
      // ),
      // Tambahkan rute lain sesuai kebutuhan...
      GoRoute(
        path: '/admin/users',
        name: 'adminUsers',
        builder:
            (context, state) =>
                Scaffold(body: Center(child: Text('Manajemen User'))),
      ),
      GoRoute(
        path: '/admin/reports',
        name: 'adminReports',
        builder:
            (context, state) =>
                Scaffold(body: Center(child: Text('Laporan Admin'))),
      ),
      GoRoute(
        path: '/admin/settings',
        name: 'adminSettings',
        builder:
            (context, state) =>
                Scaffold(body: Center(child: Text('Pengaturan Admin'))),
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
