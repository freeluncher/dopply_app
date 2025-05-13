import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/register_view_model.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String selectedRole = 'patient';
  final List<String> roles = ['patient', 'doctor'];

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    // Reset pesan sukses/error setiap kali halaman register dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(registerViewModelProvider.notifier).resetMessage();
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(registerViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
          ),
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                items:
                    roles
                        .map(
                          (role) => DropdownMenuItem(
                            value: role,
                            child: Text(
                              role == 'patient' ? 'Pasien' : 'Dokter',
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedRole = val);
                },
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              const SizedBox(height: 16),
              if (vm.isLoading) const CircularProgressIndicator(),
              if (vm.error != null)
                Text(vm.error!, style: const TextStyle(color: Colors.red)),
              if (vm.success != null)
                Text(vm.success!, style: const TextStyle(color: Colors.green)),
              ElevatedButton(
                onPressed:
                    vm.isLoading
                        ? null
                        : () async {
                          if (nameController.text.isEmpty ||
                              emailController.text.isEmpty ||
                              passwordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('All fields are required'),
                              ),
                            );
                            return;
                          }
                          final result = await ref
                              .read(registerViewModelProvider.notifier)
                              .register(
                                nameController.text,
                                emailController.text,
                                passwordController.text,
                                selectedRole,
                              );
                          if (result != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Register Success! Silakan login.',
                                ),
                              ),
                            );
                            context.go('/login');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(vm.error ?? 'Register failed'),
                              ),
                            );
                          }
                        },
                child: const Text('Register'),
              ),
              TextButton(
                onPressed: () {
                  context.go('/login');
                },
                child: const Text('Sudah punya akun? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
