// Flutter framework imports
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Shared models
import '../../../../shared/models/user.dart';

// Auth feature imports
import 'providers/login_view_model.dart';
import 'providers/user_provider.dart';
import 'providers/auth_startup_provider_enhanced.dart';
import 'privacy_policy_page.dart';
import 'terms_of_service_page.dart';

// Third-party packages
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

// App theme
import 'package:dopply_app/app/theme.dart';

/// Provider untuk status login (optional, bisa digunakan untuk tracking)
final loginStatusProvider = StateProvider<String?>((ref) => null);

/// Halaman Login - StatefulWidget dengan Riverpod Consumer
/// Menggunakan ConsumerStatefulWidget untuk akses ke Riverpod providers
/// dan state management local untuk form handling
class LoginPage extends ConsumerStatefulWidget {
  LoginPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  // Controllers untuk input fields - perlu di-dispose untuk mencegah memory leak
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Form key untuk validasi - GlobalKey memungkinkan akses ke form state
  final _formKey = GlobalKey<FormState>();

  // State untuk toggle visibility password - private variable dengan underscore
  bool _obscurePassword = true;

  // State untuk checkbox Remember Me
  bool _rememberMe = false;

  @override
  void dispose() {
    // Dispose controllers untuk mencegah memory leak
    // Penting untuk lifecycle management di Flutter
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Melakukan pengecekan update setelah frame pertama selesai
    // Menggunakan addPostFrameCallback untuk menghindari masalah dengan context
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final info = await PackageInfo.fromPlatform();
      _checkForUpdate(context, info.version);
    });
  }

  /// Method untuk mengecek pembaruan aplikasi dari server
  /// Menggunakan file JSON di Google Drive sebagai source of truth
  Future<void> _checkForUpdate(
    BuildContext context,
    String currentVersion,
  ) async {
    const String updateInfoUrl =
        'https://drive.google.com/uc?export=download&id=1PNmL0Dg6TDOp6l-igmFqw9eP_COLTlqTc'; // Ganti dengan file JSON Google Drive Anda
    try {
      // Fetch update info dari remote source
      final response = await http.get(Uri.parse(updateInfoUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['version'] as String?;
        final apkUrl = data['apk_url'] as String?;
        final changelog = data['changelog'] as String?;

        // Cek apakah ada versi yang lebih baru
        if (latestVersion != null &&
            apkUrl != null &&
            latestVersion != currentVersion) {
          // Pastikan widget masih mounted sebelum menampilkan dialog
          if (!mounted) return;

          // Tampilkan dialog update kepada user
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
                        // Launch external browser untuk download
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
      // Silent fail untuk update checker - tidak mengganggu user experience
      // Bisa menambahkan logging jika diperlukan untuk debugging
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen untuk perubahan user state dan navigasi otomatis
    // Ketika user berhasil login, listener ini akan mendeteksi perubahan
    // dan melakukan navigasi ke dashboard sesuai role user
    ref.listen<User?>(userProvider, (previous, next) {
      if (previous != next && next != null) {
        // Navigasi berdasarkan role user yang login
        if (next.role == 'admin') {
          context.go('/adminDashboard');
        } else if (next.role == 'doctor') {
          context.go('/doctorDashboard');
        } else if (next.role == 'patient') {
          context.go('/patientDashboard');
        }
      }
    });

    // Watch ViewModel untuk reactive updates
    final vm = ref.watch(loginViewModelProvider);

    // Responsive design berdasarkan lebar layar
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // Responsive padding berdasarkan lebar layar
            padding: EdgeInsets.symmetric(
              horizontal: isWideScreen ? 40 : 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              // Batasi lebar maksimal untuk tablet/desktop
              constraints: BoxConstraints(
                maxWidth: isWideScreen ? 400 : double.infinity,
              ),
              child: Form(
                key: _formKey, // Kunci untuk form validation
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Section - Logo, title, dan subtitle
                    _buildHeader(context),

                    const SizedBox(height: 48),

                    // Login Form - Card container dengan form fields
                    MedicalCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildEmailField(context),
                          const SizedBox(height: 20),
                          _buildPasswordField(context),
                          const SizedBox(height: 16),
                          _buildRememberMeCheckbox(),
                          const SizedBox(height: 24),
                          _buildLoginButton(context, vm),
                          // Conditional error message display
                          if (vm.error != null) ...[
                            const SizedBox(height: 16),
                            _buildErrorMessage(vm.error!),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Register Link - Navigasi ke halaman registrasi
                    _buildRegisterLink(context),

                    const SizedBox(height: 24),

                    // Footer - Link ke Terms dan Privacy Policy
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
        // Logo Dopply dengan fallback handling
        Container(
          width: 80,
          height: 80,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [AppColors.mediumShadow],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/icon-dopply-transparent.png',
              width: 64,
              height: 64,
              fit: BoxFit.contain,
              // Error builder untuk fallback jika asset tidak ditemukan
              // Ini penting untuk development dan produksi yang robust
              errorBuilder: (context, error, stackTrace) {
                print('[AUTH][UI] Error loading logo: $error');
                // Fallback ke icon default yang pasti ada di Material Design
                return const Icon(
                  Icons.medical_services_rounded,
                  size: 40,
                  color: AppColors.primaryBlue,
                );
              },
            ),
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

        // Welcome message untuk user guidance
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
    final vm = ref.watch(loginViewModelProvider);
    return TextFormField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      enabled:
          !vm.isLoading, // Disable field saat proses login untuk UX yang baik
      validator: (value) {
        // Validasi kosong
        if (value == null || value.isEmpty) {
          return 'Email wajib diisi';
        }
        // Validasi format email menggunakan regex yang robust
        // Pattern ini mendukung format email standar
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Format email tidak valid';
        }
        return null; // Validasi berhasil
      },
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'Masukkan email Anda',
        prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryBlue),
        // Semantic label untuk screen reader accessibility
        semanticCounterText: 'Email input field',
      ),
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    final vm = ref.watch(loginViewModelProvider);
    return TextFormField(
      controller: passwordController,
      obscureText: _obscurePassword, // Toggle visibility berdasarkan state
      textInputAction: TextInputAction.done,
      enabled: !vm.isLoading, // Disable field saat proses login
      validator: (value) {
        // Validasi kosong
        if (value == null || value.isEmpty) {
          return 'Password wajib diisi';
        }
        // Validasi panjang minimum untuk keamanan dasar
        if (value.length < 6) {
          return 'Password minimal 6 karakter';
        }
        return null; // Validasi berhasil
      },
      // Submit form ketika user menekan enter/done di keyboard
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
          // Disable toggle saat loading untuk konsistensi UX
          onPressed:
              vm.isLoading
                  ? null
                  : () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
        ),
        // Semantic label untuk screen reader accessibility
        semanticCounterText: 'Password input field',
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, vm) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        // Disable tombol saat loading untuk mencegah multiple requests
        onPressed: vm.isLoading ? null : _handleLogin,
        child:
            vm.isLoading
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Loading indicator dengan ukuran yang sesuai
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
                    // Text yang menunjukkan status loading
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
            // Tombol navigasi ke Terms of Service
            TextButton(
              onPressed: () {
                print('[LEGAL] Navigasi ke TermsOfServicePage');
                // Menggunakan MaterialPageRoute untuk navigasi modal
                // Alternatif bisa menggunakan GoRouter jika diperlukan
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
                );
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
            // Tombol navigasi ke Privacy Policy
            TextButton(
              onPressed: () {
                print('[LEGAL] Navigasi ke PrivacyPolicyPage');
                // Konsisten dengan navigasi Terms of Service
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                );
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

  /// Method untuk menangani proses login
  /// Melakukan validasi form, memanggil AuthRepository, dan menangani response
  Future<void> _handleLogin() async {
    // Validasi form menggunakan GlobalKey form validator
    if (!_formKey.currentState!.validate()) {
      print('[AUTH][UI] Form tidak valid');
      return;
    }

    print('[AUTH][UI] Input valid, proses login...');

    // Ambil dan bersihkan input dari controller
    final email = emailController.text.trim();
    final password = passwordController.text;

    try {
      // Gunakan Enhanced Auth Repository untuk login
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.login(
        email,
        password,
        rememberMe: _rememberMe,
      );

      // Pastikan widget masih mounted sebelum update UI
      if (mounted) {
        if (user != null) {
          print('[AUTH][UI] Login berhasil, navigasi ke dashboard');

          // Set user di provider global
          ref.read(userProvider.notifier).state = user;

          // Tampilkan feedback sukses kepada user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.medicalWhite),
                  const SizedBox(width: 8),
                  Text('Login berhasil! Selamat datang'),
                ],
              ),
              backgroundColor: AppColors.medicalGreen,
            ),
          );

          // Navigasi berdasarkan role
          if (user.role == 'admin') {
            context.go('/adminDashboard');
          } else if (user.role == 'doctor') {
            context.go('/doctorDashboard');
          } else if (user.role == 'patient') {
            context.go('/patientDashboard');
          } else {
            context.go('/login');
          }
        } else {
          print('[AUTH][UI] Login gagal');
          // Tampilkan error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: AppColors.medicalWhite),
                  const SizedBox(width: 8),
                  Text('Login gagal. Periksa email dan password Anda.'),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('[AUTH][UI] Login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: AppColors.medicalWhite),
                const SizedBox(width: 8),
                Text('Terjadi kesalahan: $e'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildRememberMeCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (value) {
            setState(() {
              _rememberMe = value ?? false;
            });
          },
          activeColor: AppColors.primaryBlue,
        ),
        Expanded(
          child: Text(
            'Ingat saya (tetap login)',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
