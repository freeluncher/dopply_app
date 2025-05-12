import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/viewmodel/login_view_model.dart';

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
  void initState() {
    super.initState();
    // Listen to login status changes for navigation
    ref.listen<String?>(loginStatusProvider, (previous, next) {
      if (next == 'admin') {
        Navigator.pushReplacementNamed(context, '/adminDashboard');
      } else if (next == 'doctor') {
        Navigator.pushReplacementNamed(context, '/doctorDashboard');
      } else if (next == 'patient') {
        Navigator.pushReplacementNamed(context, '/patientDashboard');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
            if (vm.error != null) Text(vm.error!, style: TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: vm.isLoading
                  ? null
                  : () async {
                      final role = await ref
                          .read(loginViewModelProvider.notifier)
                          .login(
                            emailController.text,
                            passwordController.text,
                          );
                      if (role != null) {
                        ref.read(loginStatusProvider.notifier).state = role;
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
