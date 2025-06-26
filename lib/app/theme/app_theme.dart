import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Tema aplikasi medical Dopply yang menunjukkan profesionalitas, integritas, dan kebersihan
class AppTheme {
  /// Light theme - tema utama aplikasi
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // === COLOR SCHEME ===
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        brightness: Brightness.light,
        primary: AppColors.primaryBlue,
        onPrimary: AppColors.medicalWhite,
        primaryContainer: AppColors.primaryBlueLight,
        onPrimaryContainer: AppColors.primaryBlueDark,
        secondary: AppColors.medicalGreen,
        onSecondary: AppColors.medicalWhite,
        tertiary: AppColors.medicalPurple,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        background: AppColors.background,
        onBackground: AppColors.textPrimary,
        error: AppColors.medicalRed,
        onError: AppColors.medicalWhite,
        outline: AppColors.border,
      ),

      // === VISUAL DENSITY ===
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // === TYPOGRAPHY ===
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),

      // === APP BAR THEME ===
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.medicalWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
        actionsIconTheme: const IconThemeData(
          color: AppColors.primaryBlue,
          size: 24,
        ),
      ),

      // === CARD THEME ===
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // === ELEVATED BUTTON THEME ===
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.medicalWhite,
          disabledBackgroundColor: AppColors.textTertiary,
          disabledForegroundColor: AppColors.medicalWhite,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: AppTextStyles.primaryButton,
          minimumSize: const Size(120, 48),
        ),
      ),

      // === OUTLINED BUTTON THEME ===
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          disabledForegroundColor: AppColors.textTertiary,
          side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: AppTextStyles.secondaryButton,
          minimumSize: const Size(120, 48),
        ),
      ),

      // === TEXT BUTTON THEME ===
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          disabledForegroundColor: AppColors.textTertiary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTextStyles.textButton,
        ),
      ),

      // === INPUT DECORATION THEME ===
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.medicalGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.medicalRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.medicalRed, width: 2),
        ),
        labelStyle: AppTextStyles.labelMedium,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),

      // === DIALOG THEME ===
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        shadowColor: AppColors.textPrimary.withOpacity(0.1),
        titleTextStyle: AppTextStyles.titleLarge,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),

      // === SNACK BAR THEME ===
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.medicalWhite,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // === FLOATING ACTION BUTTON THEME ===
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.medicalWhite,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // === BOTTOM NAVIGATION BAR THEME ===
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTextStyles.labelSmall,
        unselectedLabelStyle: AppTextStyles.labelSmall,
      ),

      // === CHIP THEME ===
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.medicalGray,
        disabledColor: AppColors.textTertiary.withOpacity(0.3),
        selectedColor: AppColors.primaryBlueLight,
        secondarySelectedColor: AppColors.medicalGreenLight,
        labelStyle: AppTextStyles.labelMedium,
        secondaryLabelStyle: AppTextStyles.labelSmall,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),

      // === DIVIDER THEME ===
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // === ICON THEME ===
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 24),

      // === PRIMARY ICON THEME ===
      primaryIconTheme: const IconThemeData(
        color: AppColors.primaryBlue,
        size: 24,
      ),
    );
  }

  /// Dark theme - untuk mode gelap (opsional)
  static ThemeData get darkTheme {
    return lightTheme.copyWith(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        brightness: Brightness.dark,
        primary: AppColors.primaryBlueLight,
        surface: const Color(0xFF1A1A1A),
        background: const Color(0xFF121212),
        onSurface: AppColors.medicalWhite,
        onBackground: AppColors.medicalWhite,
      ),
    );
  }
}

/// Extension untuk akses mudah ke custom text styles
extension AppTextStylesExtension on BuildContext {
  TextTheme get textStyles => Theme.of(this).textTheme;

  // Medical-specific styles
  TextStyle get bpmDisplay => AppTextStyles.bpmDisplay;
  TextStyle get medicalValue => AppTextStyles.medicalValue;
  TextStyle get medicalLabel => AppTextStyles.medicalLabel;
  TextStyle get statusText => AppTextStyles.statusText;
}
