// Flutter framework imports
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Feature imports
import 'providers/auth_startup_provider_enhanced.dart';

// App theme
import 'package:dopply_app/app/theme.dart';

/// Splash Screen - Halaman awal aplikasi dengan logo dan loading
/// Berfungsi sebagai authentication guard dan entry point utama
/// Menampilkan logo Dopply dengan animasi dan feedback status yang informatif
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Inisialisasi animation controller untuk logo
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Fade animation untuk logo
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Scale animation untuk logo (bounce effect)
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    // Mulai animasi
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch enhanced auth startup provider
    final authStartup = ref.watch(authStartupProvider);

    return authStartup.when(
      // Loading state saat mengecek authentication
      loading:
          () => _buildSplashContent(
            context,
            isLoading: true,
            statusText: 'Memeriksa status login...',
          ),

      // Error state jika terjadi error
      error:
          (e, _) => _buildSplashContent(
            context,
            isLoading: false,
            errorMessage: 'Gagal memuat: $e',
          ),

      // Success state dengan navigasi berdasarkan hasil
      data: (result) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (context.mounted) {
              switch (result.status) {
                case AuthStartupStatus.firstLaunch:
                case AuthStartupStatus.unauthenticated:
                  context.go('/login');
                  break;
                case AuthStartupStatus.authenticated:
                  final user = result.user!;
                  if (user.role == 'admin') {
                    context.go('/adminDashboard');
                  } else if (user.role == 'doctor') {
                    context.go('/doctorDashboard');
                  } else if (user.role == 'patient') {
                    context.go('/patientDashboard');
                  } else {
                    context.go('/login');
                  }
                  break;
                case AuthStartupStatus.error:
                  context.go('/login');
                  break;
              }
            }
          });
        });

        String statusText;
        switch (result.status) {
          case AuthStartupStatus.firstLaunch:
            statusText = 'Mengarahkan ke halaman login...';
            break;
          case AuthStartupStatus.authenticated:
            statusText = 'Selamat datang kembali!';
            break;
          case AuthStartupStatus.unauthenticated:
            statusText = 'Mengarahkan ke halaman login...';
            break;
          case AuthStartupStatus.error:
            statusText = 'Terjadi kesalahan...';
            break;
        }

        return _buildSplashContent(
          context,
          isLoading: true,
          statusText: statusText,
        );
      },
    );
  }

  /// Widget builder untuk konten splash screen dengan logo dan animasi
  Widget _buildSplashContent(
    BuildContext context, {
    bool isLoading = false,
    String? statusText,
    String? errorMessage,
  }) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Spacer untuk positioning
              const Spacer(flex: 2),

              // Logo Container dengan animasi dan shadow
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            AppColors.mediumShadow,
                            BoxShadow(
                              color: AppColors.primaryBlue.withOpacity(0.1),
                              spreadRadius: 8,
                              blurRadius: 20,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/icon-dopply-64.png',
                            width: 88,
                            height: 88,
                            fit: BoxFit.contain,
                            // Error builder untuk fallback jika asset tidak ditemukan
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.medical_services_rounded,
                                  size: 50,
                                  color: AppColors.primaryBlue,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // App Title dengan style medical
              Text(
                'Dopply',
                style: AppTextStyles.displayLarge.copyWith(
                  color: AppColors.primaryBlue,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Medical Monitoring System',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Loading atau Status Area
              SizedBox(
                height: 80,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading) ...[
                      // Loading indicator dengan warna medical
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status text
                      if (statusText != null)
                        Text(
                          statusText,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],

                    // Error message jika ada
                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.medicalRedLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.medicalRed.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppColors.medicalRed,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                errorMessage,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.medicalRed,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Spacer untuk balance
              const Spacer(flex: 3),

              // Footer dengan versi atau copyright
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  children: [
                    Text(
                      'Powered by',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dopply Medical Technology',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
