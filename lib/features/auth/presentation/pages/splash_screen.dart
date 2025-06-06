import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/auth_startup_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(authStartupProvider);
    final tokenVerify = ref.watch(tokenVerifyProvider);
    return tokenVerify.when(
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (isValid) {
        if (!isValid) {
          // Token tidak valid, langsung ke login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
          });
          return const Scaffold(body: SizedBox.shrink());
        }
        // Token valid, lanjutkan ke logic user
        return startup.when(
          loading:
              () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
          error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
          data: (user) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (user == null) {
                context.go('/login');
              } else if (user.role == 'admin') {
                context.go('/adminDashboard');
              } else if (user.role == 'doctor') {
                context.go('/doctorDashboard');
              } else if (user.role == 'patient') {
                context.go('/patientDashboard');
              } else {
                context.go('/login');
              }
            });
            return const Scaffold(body: SizedBox.shrink());
          },
        );
      },
    );
  }
}
