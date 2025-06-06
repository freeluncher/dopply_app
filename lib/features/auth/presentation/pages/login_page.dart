import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dopply_app/features/auth/presentation/viewmodels/login_view_model.dart';
import '../viewmodels/user_provider.dart';
import '../../domain/entities/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final info = await PackageInfo.fromPlatform();
      _checkForUpdate(context, info.version);
    });
  }

  Future<void> _checkForUpdate(
    BuildContext context,
    String currentVersion,
  ) async {
    const String updateInfoUrl =
        'https://drive.google.com/uc?export=download&id=1PNmL0Dg6TDOp6l-igmFqw9eP_COLTlqTc'; // Ganti dengan file JSON Google Drive Anda
    try {
      final response = await http.get(Uri.parse(updateInfoUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['version'] as String?;
        final apkUrl = data['apk_url'] as String?;
        final changelog = data['changelog'] as String?;
        if (latestVersion != null &&
            apkUrl != null &&
            latestVersion != currentVersion) {
          if (!mounted) return;
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: const Text('Update Tersedia'),
                  content: Text(
                    'Versi baru: $latestVersion\n\nChangelog:\n${changelog ?? "-"}\n\nDownload dan install update?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Nanti'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final uri = Uri.parse(apkUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      child: const Text('Update'),
                    ),
                  ],
                ),
          );
        }
      }
    } catch (e) {
      // Bisa log error jika perlu
    }
  }

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
            TextButton(
              onPressed: () {
                context.go('/register');
              },
              child: const Text('Belum punya akun? Daftar'),
            ),
          ],
        ),
      ),
    );
  }
}
