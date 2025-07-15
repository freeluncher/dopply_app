// =============================================================================
// Simplified Login Screen
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dopply_app/core/theme.dart';
import 'package:dopply_app/services/auth_service.dart';
import 'package:dopply_app/widgets/common/button.dart';
import 'package:dopply_app/widgets/common/input_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result.isSuccess && result.user != null) {
        // Set user ke provider agar state global update
        ref.read(currentUserProvider.notifier).setUser(result.user!);
        final user = result.user!;
        // Navigate based on role
        switch (user.role) {
          case 'patient':
            context.go('/patient');
            break;
          case 'doctor':
            context.go('/doctor');
            break;
          case 'admin':
            context.go('/admin');
            break;
          default:
            context.go('/patient');
        }
      } else {
        _showErrorMessage(result.errorMessage ?? 'Login gagal');
      }
    } catch (e) {
      _showErrorMessage('Terjadi kesalahan: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),

                // Logo and title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryDark,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.monitor_heart,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Dopply',
                        style: AppTheme.heading1.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fetal Heart Rate Monitoring',
                        style: AppTheme.bodyText.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Login form
                Text('Masuk ke Akun Anda', style: AppTheme.heading2),
                const SizedBox(height: 24),

                // Email field
                AppInputField(
                  controller: _emailController,
                  label: 'Email',
                  hintText: 'Masukkan email Anda',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                AppInputField(
                  controller: _passwordController,
                  label: 'Password',
                  hintText: 'Masukkan password Anda',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    if (value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Login button
                AppButton(
                  text: 'Masuk',
                  onPressed: _isLoading ? null : _handleLogin,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Belum punya akun? ',
                      style: AppTheme.bodyText.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: Text(
                        'Daftar',
                        style: AppTheme.bodyText.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
