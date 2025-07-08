import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/services/api/patient_api_service.dart';
import 'package:dopply_app/shared/models/user.dart';

/// State untuk patient dashboard
class PatientDashboardState {
  final bool isLoading;
  final User? patientProfile;
  final String? error;
  final Map<String, dynamic>? healthMetrics;
  final List<Map<String, dynamic>> recentActivities;

  const PatientDashboardState({
    this.isLoading = false,
    this.patientProfile,
    this.error,
    this.healthMetrics,
    this.recentActivities = const [],
  });

  PatientDashboardState copyWith({
    bool? isLoading,
    User? patientProfile,
    String? error,
    Map<String, dynamic>? healthMetrics,
    List<Map<String, dynamic>>? recentActivities,
  }) {
    return PatientDashboardState(
      isLoading: isLoading ?? this.isLoading,
      patientProfile: patientProfile ?? this.patientProfile,
      error: error ?? this.error,
      healthMetrics: healthMetrics ?? this.healthMetrics,
      recentActivities: recentActivities ?? this.recentActivities,
    );
  }
}

/// Notifier untuk patient dashboard
class PatientDashboardNotifier extends StateNotifier<PatientDashboardState> {
  final PatientApiService _patientApiService;

  PatientDashboardNotifier(this._patientApiService)
    : super(const PatientDashboardState());

  /// Load patient profile and dashboard data
  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('[PATIENT_DASHBOARD] 📊 Loading dashboard data...');

      // Load patient profile
      final profileResponse = await _patientApiService.getPatientProfile();
      final patientProfile = User.fromJson(profileResponse);

      print('[PATIENT_DASHBOARD] ✅ Profile loaded: ${patientProfile.name}');

      // TODO: Load health metrics from monitoring history
      // TODO: Load recent activities

      state = state.copyWith(
        isLoading: false,
        patientProfile: patientProfile,
        healthMetrics: {
          'lastMonitoring': null,
          'gestationalAge': null,
          'totalSessions': 0,
        },
        recentActivities: [], // Will be populated when history API is available
      );
    } catch (e) {
      print('[PATIENT_DASHBOARD] ❌ Error loading dashboard: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh dashboard data
  Future<void> refresh() async {
    await loadDashboardData();
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider untuk PatientApiService
final patientApiServiceProvider = Provider<PatientApiService>((ref) {
  return PatientApiService();
});

/// Provider untuk PatientDashboardNotifier
final patientDashboardProvider =
    StateNotifierProvider<PatientDashboardNotifier, PatientDashboardState>((
      ref,
    ) {
      final apiService = ref.watch(patientApiServiceProvider);
      return PatientDashboardNotifier(apiService);
    });
