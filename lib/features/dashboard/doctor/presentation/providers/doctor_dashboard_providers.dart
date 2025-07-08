// =============================================================================
// Doctor Dashboard Providers
//
// Centralized state management for doctor dashboard features including
// statistics, patient management, and active monitoring sessions.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../services/api/doctor_api_service.dart';

// Doctor Statistics State
class DoctorStats {
  final int totalPatients;
  final int activeMonitoring;
  final int todaysSessions;
  final int pendingReviews;
  final bool isLoading;
  final String? error;

  const DoctorStats({
    this.totalPatients = 0,
    this.activeMonitoring = 0,
    this.todaysSessions = 0,
    this.pendingReviews = 0,
    this.isLoading = false,
    this.error,
  });

  DoctorStats copyWith({
    int? totalPatients,
    int? activeMonitoring,
    int? todaysSessions,
    int? pendingReviews,
    bool? isLoading,
    String? error,
  }) {
    return DoctorStats(
      totalPatients: totalPatients ?? this.totalPatients,
      activeMonitoring: activeMonitoring ?? this.activeMonitoring,
      todaysSessions: todaysSessions ?? this.todaysSessions,
      pendingReviews: pendingReviews ?? this.pendingReviews,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Doctor Statistics Notifier
class DoctorStatsNotifier extends StateNotifier<DoctorStats> {
  DoctorStatsNotifier() : super(const DoctorStats());

  final DoctorApiService _doctorApiService = DoctorApiService();

  Future<void> loadStats(String doctorId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Use the new dedicated statistics endpoint
      final statsData = await _doctorApiService.getDoctorStatistics(
        doctorId: int.parse(doctorId),
      );

      final patients = statsData['patients'] as Map<String, dynamic>? ?? {};
      final records = statsData['records'] as Map<String, dynamic>? ?? {};

      state = state.copyWith(
        totalPatients: patients['total'] ?? 0,
        activeMonitoring: patients['active'] ?? 0,
        todaysSessions:
            records['this_week'] ?? 0, // Using week records as session proxy
        pendingReviews: 0, // Can be added to backend later
        isLoading: false,
      );
    } catch (e) {
      // Enhanced error handling for backend database issues
      String errorMessage = e.toString();

      if (e.toString().contains('Could not determine join condition') ||
          e.toString().contains('foreign keys linking') ||
          e.toString().contains('doctor_patient_associations')) {
        errorMessage = 'Server configuration error. Please contact support.';
        print(
          '[DOCTOR_STATS] Backend database relationship error: ${e.toString()}',
        );
      } else if (e.toString().contains('403') ||
          e.toString().contains('unauthorized')) {
        errorMessage = 'Access denied. Please check your doctor permissions.';
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  Future<void> refreshStats(String doctorId) async {
    await loadStats(doctorId);
  }
}

// Doctor Patients State
class DoctorPatientsState {
  final List<Map<String, dynamic>> patients;
  final bool isLoading;
  final String? error;

  const DoctorPatientsState({
    this.patients = const [],
    this.isLoading = false,
    this.error,
  });

  DoctorPatientsState copyWith({
    List<Map<String, dynamic>>? patients,
    bool? isLoading,
    String? error,
  }) {
    return DoctorPatientsState(
      patients: patients ?? this.patients,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Doctor Patients Notifier
class DoctorPatientsNotifier extends StateNotifier<DoctorPatientsState> {
  DoctorPatientsNotifier() : super(const DoctorPatientsState());

  Future<void> loadPatients(String doctorId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Use DoctorApiService to get patients assigned to this doctor
      final response = await DoctorApiService().getPatientsForDoctor(
        doctorId: int.parse(doctorId),
        limit: 100, // Ensure we get all patients
      );

      // Extract patients array from the response
      final patients = List<Map<String, dynamic>>.from(
        response['patients'] ?? [],
      );

      state = state.copyWith(patients: patients, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Providers
final doctorStatsProvider =
    StateNotifierProvider<DoctorStatsNotifier, DoctorStats>((ref) {
      return DoctorStatsNotifier();
    });

final doctorPatientsProvider =
    StateNotifierProvider<DoctorPatientsNotifier, DoctorPatientsState>((ref) {
      return DoctorPatientsNotifier();
    });
