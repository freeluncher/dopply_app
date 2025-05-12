import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dopply_app/features/auth/presentation/viewmodels/login_view_model.dart';
import '../viewmodels/user_provider.dart';
import '../../domain/entities/user.dart';

final loginStatusProvider = StateProvider<String?>((ref) => null);

class LoginPage extends ConsumerStatefulWidget {
  LoginPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    ref.listen<User?>(userProvider, (previous, next) {
      if (previous != next && next != null) {
        if (next.role == 'admin') {
          context.go('/adminDashboard');
        } else if (next.role == 'doctor') {
          context.go('/doctorDashboard');
        } else if (next.role == 'patient') {
          context.go('/patientDashboard');
        }
      }
    });

    final vm = ref.watch(loginViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 16),
            if (vm.isLoading) CircularProgressIndicator(),
            if (vm.error != null)
              Text(vm.error!, style: TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed:
                  vm.isLoading
                      ? null
                      : () async {
                        if (emailController.text.isEmpty ||
                            passwordController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Email and password required'),
                            ),
                          );
                          return;
                        }
                        final user = await ref
                            .read(loginViewModelProvider.notifier)
                            .login(
                              emailController.text,
                              passwordController.text,
                            );
                        if (user != null) {
                          ref.read(userProvider.notifier).state = user;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Login Success!')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(vm.error ?? 'Login failed')),
                          );
                        }
                      },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
