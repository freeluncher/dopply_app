import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Kelas yang berisi definisi typography untuk aplikasi medical
class AppTextStyles {
  // === FONT FAMILY ===
  static const String primaryFont = 'Inter'; // Clean, medical-grade font
  static const String secondaryFont = 'Roboto'; // Fallback font

  // === DISPLAY STYLES (untuk headers besar) ===

  /// Display Large - untuk welcome screens dan main titles
  static const TextStyle displayLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  /// Display Medium - untuk section headers
  static const TextStyle displayMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// Display Small - untuk card headers
  static const TextStyle displaySmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // === HEADLINE STYLES ===

  /// Headline Large - untuk page titles
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /// Headline Medium - untuk section titles
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /// Headline Small - untuk subsection titles
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // === TITLE STYLES ===

  /// Title Large - untuk dialog titles
  static const TextStyle titleLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Title Medium - untuk card titles
  static const TextStyle titleMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Title Small - untuk list item titles
  static const TextStyle titleSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // === BODY STYLES ===

  /// Body Large - untuk main content
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  /// Body Medium - untuk descriptions
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
  );

  /// Body Small - untuk captions dan small text
  static const TextStyle bodySmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // === LABEL STYLES ===

  /// Label Large - untuk button labels
  static const TextStyle labelLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /// Label Medium - untuk form labels
  static const TextStyle labelMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  /// Label Small - untuk tiny labels
  static const TextStyle labelSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    color: AppColors.textTertiary,
    height: 1.4,
  );

  // === SPECIALIZED MEDICAL STYLES ===

  /// BPM Display - untuk menampilkan nilai BPM besar
  static const TextStyle bpmDisplay = TextStyle(
    fontFamily: primaryFont,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: AppColors.medicalRed,
    height: 1.1,
  );

  /// Medical Value - untuk nilai-nilai medical
  static const TextStyle medicalValue = TextStyle(
    fontFamily: primaryFont,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryBlue,
    height: 1.2,
  );

  /// Medical Label - untuk label medical
  static const TextStyle medicalLabel = TextStyle(
    fontFamily: primaryFont,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.8,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  /// Status Text - untuk status indicators
  static const TextStyle statusText = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 1.3,
  );

  // === BUTTON STYLES ===

  /// Primary Button Text
  static const TextStyle primaryButton = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    color: AppColors.medicalWhite,
    height: 1.2,
  );

  /// Secondary Button Text
  static const TextStyle secondaryButton = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    color: AppColors.primaryBlue,
    height: 1.2,
  );

  /// Text Button
  static const TextStyle textButton = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    color: AppColors.primaryBlue,
    height: 1.3,
  );
}
