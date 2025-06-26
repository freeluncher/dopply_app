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
import 'package:dopply_app/app/theme.dart';

final loginStatusProvider = StateProvider<String?>((ref) => null);

class LoginPage extends ConsumerStatefulWidget {
  LoginPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Form validation key
  bool _obscurePassword = true; // Password visibility toggle

  @override
  void dispose() {
    // Dispose controllers untuk mencegah memory leak
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

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
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWideScreen ? 40 : 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWideScreen ? 400 : double.infinity,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Section
                    _buildHeader(context),

                    const SizedBox(height: 48),

                    // Login Form
                    MedicalCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildEmailField(context),
                          const SizedBox(height: 20),
                          _buildPasswordField(context),
                          const SizedBox(height: 24),
                          _buildLoginButton(context, vm),
                          if (vm.error != null) ...[
                            const SizedBox(height: 16),
                            _buildErrorMessage(vm.error!),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Register Link
                    _buildRegisterLink(context),

                    const SizedBox(height: 24),

                    // Footer
                    _buildFooter(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // === WIDGET BUILDERS ===

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // Logo atau Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [AppColors.mediumShadow],
          ),
          child: const Icon(
            Icons.medical_services_rounded,
            size: 40,
            color: AppColors.medicalWhite,
          ),
        ),
        const SizedBox(height: 24),

        // App Title
        Text(
          'Dopply',
          style: AppTextStyles.displayLarge.copyWith(
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Medical Monitoring System',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Welcome message
        Text(
          'Masuk ke akun Anda untuk memulai monitoring',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailField(BuildContext context) {
    return TextFormField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Email wajib diisi';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Format email tidak valid';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'Masukkan email Anda',
        prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryBlue),
      ),
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    return TextFormField(
      controller: passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Password wajib diisi';
        }
        if (value.length < 6) {
          return 'Password minimal 6 karakter';
        }
        return null;
      },
      onFieldSubmitted: (_) => _handleLogin(),
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Masukkan password Anda',
        prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryBlue),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: AppColors.textSecondary,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, vm) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: vm.isLoading ? null : _handleLogin,
        child:
            vm.isLoading
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.medicalWhite,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Memproses...', style: AppTextStyles.primaryButton),
                  ],
                )
                : Text('Masuk', style: AppTextStyles.primaryButton),
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.medicalRedLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.medicalRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.medicalRed, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.medicalRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Belum punya akun? ', style: AppTextStyles.bodyMedium),
        TextButton(
          onPressed: () => context.go('/register'),
          child: Text(
            'Daftar Sekarang',
            style: AppTextStyles.textButton.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Text(
          'Dengan masuk, Anda menyetujui',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                // TODO: Buka halaman terms of service
              },
              child: Text(
                'Syarat Layanan',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primaryBlue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Text(
              ' dan ',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Buka halaman privacy policy
              },
              child: Text(
                'Kebijakan Privasi',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primaryBlue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // === METHODS ===

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = await ref
        .read(loginViewModelProvider.notifier)
        .login(emailController.text.trim(), passwordController.text);

    if (mounted) {
      if (user != null) {
        ref.read(userProvider.notifier).state = user;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.medicalWhite),
                const SizedBox(width: 8),
                Text(
                  'Login berhasil! Selamat datang',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.medicalWhite,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.medicalGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
