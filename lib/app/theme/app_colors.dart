import 'package:flutter/material.dart';

/// Kelas yang berisi semua warna untuk tema aplikasi medical Dopply
class AppColors {
  // === WARNA UTAMA MEDICAL ===

  /// Biru medical utama - menunjukkan kepercayaan dan profesionalitas
  static const Color primaryBlue = Color(0xFF2E86AB);

  /// Biru medical gelap - untuk emphasis dan contrast
  static const Color primaryBlueDark = Color(0xFF1A5F7A);

  /// Biru medical terang - untuk accent dan highlight
  static const Color primaryBlueLight = Color(0xFF57C4E5);

  /// Putih medical - menunjukkan kebersihan dan sterility
  static const Color medicalWhite = Color(0xFFFAFDFF);

  /// Abu-abu medical - untuk background dan subtle elements
  static const Color medicalGray = Color(0xFFF5F7FA);

  // === WARNA SEKUNDER ===

  /// Hijau medical - untuk success, health indicators
  static const Color medicalGreen = Color(0xFF00D4AA);
  static const Color medicalGreenLight = Color(0xFFE8F8F5);

  /// Merah medical - untuk alerts, critical values
  static const Color medicalRed = Color(0xFFE74C3C);
  static const Color medicalRedLight = Color(0xFFFDEDEA);

  /// Orange medical - untuk warnings
  static const Color medicalOrange = Color(0xFFFF9F43);
  static const Color medicalOrangeLight = Color(0xFFFFF4E6);

  /// Ungu medical - untuk premium features
  static const Color medicalPurple = Color(0xFF6C5CE7);
  static const Color medicalPurpleLight = Color(0xFFF1F0FF);

  // === WARNA NETRAL ===

  /// Teks utama - dark gray untuk readability
  static const Color textPrimary = Color(0xFF2C3E50);

  /// Teks sekunder - medium gray
  static const Color textSecondary = Color(0xFF7F8C8D);

  /// Teks tertiary - light gray untuk subtle text
  static const Color textTertiary = Color(0xFFBDC3C7);

  /// Border - untuk dividers dan outlines
  static const Color border = Color(0xFFE9ECEF);

  /// Background - main app background
  static const Color background = Color(0xFFF8FAFC);

  /// Surface - for cards and elevated surfaces
  static const Color surface = Color(0xFFFFFFFF);

  // === WARNA STATUS BPM ===

  /// Normal BPM range (120-160)
  static const Color bpmNormal = medicalGreen;

  /// Low BPM (< 120)
  static const Color bpmLow = medicalOrange;

  /// High BPM (> 160)
  static const Color bpmHigh = medicalRed;

  /// Critical BPM (< 100 or > 180)
  static const Color bpmCritical = Color(0xFF8E44AD);

  // === GRADIENTS ===

  /// Primary gradient untuk headers dan CTAs
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryBlueDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Medical gradient untuk background elements
  static const LinearGradient medicalGradient = LinearGradient(
    colors: [medicalWhite, medicalGray],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Success gradient
  static const LinearGradient successGradient = LinearGradient(
    colors: [medicalGreen, Color(0xFF00B894)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // === SHADOWS ===

  /// Soft shadow untuk cards
  static const BoxShadow softShadow = BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  /// Medium shadow untuk elevated elements
  static const BoxShadow mediumShadow = BoxShadow(
    color: Color(0x15000000),
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  /// Strong shadow untuk modals
  static const BoxShadow strongShadow = BoxShadow(
    color: Color(0x20000000),
    blurRadius: 24,
    offset: Offset(0, 8),
  );
}
