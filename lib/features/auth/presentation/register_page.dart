// Flutter framework imports
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Feature imports
import 'providers/register_view_model.dart';
import 'privacy_policy_page.dart';
import 'terms_of_service_page.dart';

// App theme
import 'package:dopply_app/app/theme.dart';

/// Halaman Registrasi - StatefulWidget dengan Riverpod Consumer
/// Menggunakan konsisten design dengan LoginPage dan tema aplikasi medical
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  // Controllers untuk input fields - perlu di-dispose untuk mencegah memory leak
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Form key untuk validasi - GlobalKey memungkinkan akses ke form state
  final _formKey = GlobalKey<FormState>();

  // State untuk role selection dan password visibility
  String selectedRole = 'patient';
  final List<String> roles = ['patient', 'doctor'];
  bool _obscurePassword = true;

  @override
  void dispose() {
    // Dispose controllers untuk mencegah memory leak
    // Penting untuk lifecycle management di Flutter
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    // Reset pesan sukses/error setiap kali halaman register dibuka
    // Menggunakan addPostFrameCallback untuk menghindari masalah dengan context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(registerViewModelProvider.notifier).resetMessage();
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    // Watch ViewModel untuk reactive updates
    final vm = ref.watch(registerViewModelProvider);

    // Responsive design berdasarkan lebar layar
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Main content area yang bisa di-scroll
            Expanded(
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

                          const SizedBox(height: 32),

                          // Register Form - Card container dengan form fields
                          MedicalCard(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                _buildNameField(context),
                                const SizedBox(height: 20),
                                _buildEmailField(context),
                                const SizedBox(height: 20),
                                _buildPasswordField(context),
                                const SizedBox(height: 20),
                                _buildRoleSelector(context),
                                const SizedBox(height: 24),
                                _buildRegisterButton(context, vm),
                                // Conditional error/success message display
                                if (vm.error != null) ...[
                                  const SizedBox(height: 16),
                                  _buildErrorMessage(vm.error!),
                                ],
                                if (vm.success != null) ...[
                                  const SizedBox(height: 16),
                                  _buildSuccessMessage(vm.success!),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Footer yang selalu di bawah
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isWideScreen ? 40 : 24,
                vertical: 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWideScreen ? 400 : double.infinity,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Legal Links - Privacy Policy & Terms of Service
                    _buildLegalLinks(context),

                    const SizedBox(height: 16),

                    // Login Link - Navigasi ke halaman login
                    _buildLoginLink(context),
                  ],
                ),
              ),
            ),
          ],
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
              errorBuilder: (context, error, stackTrace) {
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
          'Daftar Akun',
          style: AppTextStyles.displayLarge.copyWith(
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Bergabung dengan Dopply Medical System',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Welcome message untuk user guidance
        Text(
          'Buat akun untuk mulai monitoring kesehatan Anda',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNameField(BuildContext context) {
    final vm = ref.watch(registerViewModelProvider);
    return TextFormField(
      controller: nameController,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      enabled: !vm.isLoading, // Disable field saat proses registrasi
      validator: (value) {
        // Validasi kosong
        if (value == null || value.isEmpty) {
          return 'Nama lengkap wajib diisi';
        }
        // Validasi panjang minimum
        if (value.length < 2) {
          return 'Nama minimal 2 karakter';
        }
        return null; // Validasi berhasil
      },
      decoration: InputDecoration(
        labelText: 'Nama Lengkap',
        hintText: 'Masukkan nama lengkap Anda',
        prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryBlue),
        // Semantic label untuk screen reader accessibility
        semanticCounterText: 'Name input field',
      ),
    );
  }

  Widget _buildEmailField(BuildContext context) {
    final vm = ref.watch(registerViewModelProvider);
    return TextFormField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      enabled: !vm.isLoading, // Disable field saat proses registrasi
      validator: (value) {
        // Validasi kosong
        if (value == null || value.isEmpty) {
          return 'Email wajib diisi';
        }
        // Validasi format email menggunakan regex yang robust
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
    final vm = ref.watch(registerViewModelProvider);
    return TextFormField(
      controller: passwordController,
      obscureText: _obscurePassword, // Toggle visibility berdasarkan state
      textInputAction: TextInputAction.next,
      enabled: !vm.isLoading, // Disable field saat proses registrasi
      validator: (value) {
        // Validasi kosong
        if (value == null || value.isEmpty) {
          return 'Password wajib diisi';
        }
        // Validasi panjang minimum untuk keamanan
        if (value.length < 6) {
          return 'Password minimal 6 karakter';
        }
        // Validasi kompleksitas password
        if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
          return 'Password harus mengandung huruf dan angka';
        }
        return null; // Validasi berhasil
      },
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
        helperText: 'Minimal 6 karakter, mengandung huruf dan angka',
        helperStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildRoleSelector(BuildContext context) {
    final vm = ref.watch(registerViewModelProvider);
    return DropdownButtonFormField<String>(
      value: selectedRole,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Role wajib dipilih';
        }
        return null;
      },
      items:
          roles
              .map(
                (role) => DropdownMenuItem(
                  value: role,
                  child: Row(
                    children: [
                      Icon(
                        role == 'patient'
                            ? Icons.person_outline
                            : Icons.medical_services_outlined,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        role == 'patient' ? 'Pasien' : 'Dokter',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
      onChanged:
          vm.isLoading
              ? null
              : (val) {
                if (val != null) setState(() => selectedRole = val);
              },
      decoration: InputDecoration(
        labelText: 'Role/Peran',
        hintText: 'Pilih peran Anda',
        prefixIcon: Icon(Icons.work_outline, color: AppColors.primaryBlue),
        semanticCounterText: 'Role selection field',
      ),
    );
  }

  Widget _buildRegisterButton(BuildContext context, vm) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        // Disable tombol saat loading untuk mencegah multiple requests
        onPressed: vm.isLoading ? null : _handleRegister,
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
                : Text('Daftar Akun', style: AppTextStyles.primaryButton),
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

  Widget _buildSuccessMessage(String success) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.medicalGreenLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.medicalGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.medicalGreen,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              success,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.medicalGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Sudah punya akun? ', style: AppTextStyles.bodyMedium),
        TextButton(
          onPressed: () => context.go('/login'),
          child: Text(
            'Masuk Sekarang',
            style: AppTextStyles.textButton.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Legal links section for privacy policy and terms of service
  Widget _buildLegalLinks(BuildContext context) {
    return Column(
      children: [
        Text(
          'Dengan mendaftar, Anda setuju dengan:',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyPage(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: Text(
                'Kebijakan Privasi',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryBlue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Text(
              ' & ',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TermsOfServicePage(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: Text(
                'Syarat Layanan',
                style: AppTextStyles.bodySmall.copyWith(
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

  /// Method untuk menangani proses registrasi
  /// Melakukan validasi form, memanggil ViewModel, dan menangani response
  Future<void> _handleRegister() async {
    // Validasi form menggunakan GlobalKey form validator
    // Ini akan memanggil semua validator yang didefinisikan di TextFormField
    if (!_formKey.currentState!.validate()) {
      print('[AUTH][UI] Form registrasi tidak valid');
      return;
    }

    print('[AUTH][UI] Input valid, proses registrasi...');

    // Ambil dan bersihkan input dari controller
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    // Panggil register method dari ViewModel melalui Riverpod
    // ViewModel akan menangani business logic dan API call
    final result = await ref
        .read(registerViewModelProvider.notifier)
        .register(name, email, password, selectedRole);

    // Pastikan widget masih mounted sebelum update UI
    if (mounted) {
      final vm = ref.read(registerViewModelProvider);

      if (result != null) {
        print('[AUTH][UI] Registrasi berhasil');

        // Tampilkan feedback sukses kepada user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.medicalWhite),
                const SizedBox(width: 8),
                Text(
                  'Registrasi berhasil! Silakan login.',
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

        // Navigasi ke halaman login setelah registrasi berhasil
        context.go('/login');
      } else {
        print('[AUTH][UI] Registrasi gagal');

        // Tampilkan error message kepada user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.medicalWhite),
                const SizedBox(width: 8),
                Text(
                  vm.error ?? 'Registrasi gagal, coba lagi',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.medicalWhite,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.medicalRed,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
