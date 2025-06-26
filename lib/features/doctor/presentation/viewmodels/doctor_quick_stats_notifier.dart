import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Model untuk quick stats dashboard dokter
class DoctorQuickStats {
  final int totalPatients;
  final int activeMonitoring;
  final int totalHistory;
  final int todayMonitoring;

  const DoctorQuickStats({
    required this.totalPatients,
    required this.activeMonitoring,
    required this.totalHistory,
    required this.todayMonitoring,
  });

  factory DoctorQuickStats.empty() {
    return const DoctorQuickStats(
      totalPatients: 0,
      activeMonitoring: 0,
      totalHistory: 0,
      todayMonitoring: 0,
    );
  }
}

/// State untuk quick stats
class DoctorQuickStatsState {
  final DoctorQuickStats stats;
  final bool isLoading;
  final String? error;

  const DoctorQuickStatsState({
    required this.stats,
    this.isLoading = false,
    this.error,
  });

  DoctorQuickStatsState copyWith({
    DoctorQuickStats? stats,
    bool? isLoading,
    String? error,
  }) {
    return DoctorQuickStatsState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// StateNotifier untuk mengelola quick stats
class DoctorQuickStatsNotifier extends StateNotifier<DoctorQuickStatsState> {
  DoctorQuickStatsNotifier()
    : super(
        DoctorQuickStatsState(
          stats: DoctorQuickStats.empty(),
          isLoading: false,
        ),
      );

  /// Load stats untuk dokter tertentu
  Future<void> loadStats(String? doctorId) async {
    if (doctorId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Simulate API call - ganti dengan real API call
      await Future.delayed(const Duration(seconds: 1));

      // TODO: Ganti dengan actual API call
      final stats = await _fetchDoctorStats(doctorId);

      state = state.copyWith(stats: stats, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat statistik: $e',
      );
    }
  }

  /// Refresh stats
  Future<void> refreshStats(String? doctorId) async {
    await loadStats(doctorId);
  }

  /// Mock function - ganti dengan real API call
  Future<DoctorQuickStats> _fetchDoctorStats(String doctorId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Mock realistic data - ganti dengan real API response
    final now = DateTime.now();
    final baseCount = now.day % 10; // Variasi berdasarkan tanggal

    return DoctorQuickStats(
      totalPatients: 15 + baseCount, // 15-24 pasien
      activeMonitoring:
          (now.hour < 8 || now.hour > 17)
              ? 0
              : (baseCount % 4), // 0-3 monitoring aktif (jam kerja)
      totalHistory: 45 + (baseCount * 3), // 45-72 riwayat
      todayMonitoring:
          now.hour < 8
              ? 0
              : ((now.hour - 8) ~/ 2), // Monitoring bertambah seiring hari
    );
  }
}

/// Provider untuk quick stats
final doctorQuickStatsProvider =
    StateNotifierProvider<DoctorQuickStatsNotifier, DoctorQuickStatsState>((
      ref,
    ) {
      return DoctorQuickStatsNotifier();
    });
