import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/app/theme.dart';

/// Centralized error handling service untuk standardisasi error display
class ErrorHandlingService {
  static const Duration _snackBarDuration = Duration(seconds: 4);

  /// Show error snackbar dengan styling medical theme
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    Duration? duration,
    VoidCallback? onRetry,
    String? retryLabel,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.medicalWhite,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.medicalWhite,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.medicalRed,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? _snackBarDuration,
        action:
            onRetry != null
                ? SnackBarAction(
                  label: retryLabel ?? 'Coba Lagi',
                  textColor: AppColors.medicalWhite,
                  onPressed: onRetry,
                )
                : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show success snackbar
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppColors.medicalWhite,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.medicalWhite,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.medicalGreen,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? _snackBarDuration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show warning snackbar
  static void showWarningSnackBar(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning_outlined,
              color: AppColors.textPrimary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.medicalOrange,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? _snackBarDuration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show info snackbar
  static void showInfoSnackBar(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: AppColors.medicalWhite,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.medicalWhite,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? _snackBarDuration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show error dialog dengan retry option
  static Future<bool?> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    bool showRetry = false,
    String? retryLabel,
    String? cancelLabel,
  }) async {
    if (!context.mounted) return null;

    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.medicalRed,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.medicalRed,
                  ),
                ),
              ],
            ),
            content: Text(message, style: AppTextStyles.bodyMedium),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(cancelLabel ?? 'Tutup'),
              ),
              if (showRetry)
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                  ),
                  child: Text(
                    retryLabel ?? 'Coba Lagi',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.medicalWhite,
                    ),
                  ),
                ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
    );
  }

  /// Parse dan format error message dari API response
  static String parseApiError(dynamic error) {
    if (error == null) return 'Terjadi kesalahan yang tidak diketahui';

    // String error langsung
    if (error is String) {
      return error.isNotEmpty ? error : 'Terjadi kesalahan';
    }

    // Map error dengan message
    if (error is Map<String, dynamic>) {
      if (error['message'] != null) {
        return error['message'] as String;
      }
      if (error['error'] != null) {
        return error['error'] as String;
      }
      if (error['details'] != null) {
        return error['details'] as String;
      }
    }

    // List errors (validation errors)
    if (error is List) {
      if (error.isNotEmpty) {
        final firstError = error.first;
        if (firstError is String) {
          return firstError;
        }
        if (firstError is Map<String, dynamic> &&
            firstError['message'] != null) {
          return firstError['message'] as String;
        }
      }
    }

    return 'Terjadi kesalahan yang tidak diketahui';
  }

  /// Get user-friendly error message berdasarkan error type
  static String getUserFriendlyErrorMessage(dynamic error) {
    final errorMessage = parseApiError(error).toLowerCase();

    // Network errors
    if (errorMessage.contains('network') ||
        errorMessage.contains('connection') ||
        errorMessage.contains('timeout')) {
      return 'Koneksi internet bermasalah. Periksa koneksi Anda dan coba lagi.';
    }

    // Authentication errors
    if (errorMessage.contains('unauthorized') ||
        errorMessage.contains('token') ||
        errorMessage.contains('authentication')) {
      return 'Sesi Anda telah berakhir. Silakan login kembali.';
    }

    // Validation errors
    if (errorMessage.contains('validation') ||
        errorMessage.contains('invalid')) {
      return 'Data yang dimasukkan tidak valid. Periksa kembali form Anda.';
    }

    // Permission errors
    if (errorMessage.contains('forbidden') ||
        errorMessage.contains('permission')) {
      return 'Anda tidak memiliki izin untuk melakukan aksi ini.';
    }

    // Server errors
    if (errorMessage.contains('server') || errorMessage.contains('internal')) {
      return 'Terjadi masalah pada server. Coba lagi dalam beberapa saat.';
    }

    // Not found errors
    if (errorMessage.contains('not found')) {
      return 'Data yang dicari tidak ditemukan.';
    }

    // Default fallback
    return parseApiError(error);
  }
}

/// Loading state management untuk standardisasi loading indicators
class LoadingState {
  final bool isLoading;
  final String? loadingMessage;

  const LoadingState({this.isLoading = false, this.loadingMessage});

  LoadingState copyWith({bool? isLoading, String? loadingMessage}) {
    return LoadingState(
      isLoading: isLoading ?? this.isLoading,
      loadingMessage: loadingMessage ?? this.loadingMessage,
    );
  }
}

/// Global loading state provider
final globalLoadingProvider = StateProvider<LoadingState>(
  (ref) => const LoadingState(),
);

/// Widget untuk menampilkan loading overlay
class LoadingOverlay extends ConsumerWidget {
  final Widget child;
  final String? customMessage;

  const LoadingOverlay({Key? key, required this.child, this.customMessage})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadingState = ref.watch(globalLoadingProvider);

    return Stack(
      children: [
        child,
        if (loadingState.isLoading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    customMessage ?? loadingState.loadingMessage ?? 'Memuat...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.medicalWhite,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
