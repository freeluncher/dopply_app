import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/features/doctor/data/models/medical_record.dart';
import 'package:dopply_app/features/doctor/data/services/medical_records_api_service.dart';
import 'package:dopply_app/services/api/api_client.dart';

/// State untuk medical records
class MedicalRecordsState {
  final List<MedicalRecord> records;
  final bool isLoading;
  final String? error;
  final MedicalRecordFilter? currentFilter;
  final bool hasMore;
  final int total;

  const MedicalRecordsState({
    this.records = const [],
    this.isLoading = false,
    this.error,
    this.currentFilter,
    this.hasMore = true,
    this.total = 0,
  });

  MedicalRecordsState copyWith({
    List<MedicalRecord>? records,
    bool? isLoading,
    String? error,
    MedicalRecordFilter? currentFilter,
    bool? hasMore,
    int? total,
  }) {
    return MedicalRecordsState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentFilter: currentFilter ?? this.currentFilter,
      hasMore: hasMore ?? this.hasMore,
      total: total ?? this.total,
    );
  }
}

/// Notifier untuk mengelola medical records
class MedicalRecordsNotifier extends StateNotifier<MedicalRecordsState> {
  final MedicalRecordsApiService _apiService;

  MedicalRecordsNotifier(this._apiService) : super(const MedicalRecordsState());

  /// Load medical records dengan filter
  Future<void> loadRecords({
    MedicalRecordFilter? filter,
    bool refresh = false,
  }) async {
    try {
      if (refresh) {
        state = state.copyWith(isLoading: true, error: null);
      } else if (state.isLoading) {
        return; // Avoid multiple simultaneous requests
      }

      if (!refresh && !state.hasMore) {
        return; // No more data to load
      }

      final currentFilter =
          filter ?? state.currentFilter ?? const MedicalRecordFilter();
      final offset = refresh ? 0 : state.records.length;
      final filterWithOffset = currentFilter.copyWith(offset: offset);

      print(
        '[MEDICAL_RECORDS_VM] Loading records with filter: ${filterWithOffset.toQueryParams()}',
      );

      if (!refresh) {
        state = state.copyWith(isLoading: true, error: null);
      }

      final newRecords = await _apiService.getRecords(filter: filterWithOffset);

      if (refresh) {
        state = state.copyWith(
          records: newRecords,
          isLoading: false,
          error: null,
          currentFilter: currentFilter,
          hasMore: newRecords.length >= currentFilter.limit,
          total: newRecords.length,
        );
      } else {
        final allRecords = [...state.records, ...newRecords];
        state = state.copyWith(
          records: allRecords,
          isLoading: false,
          error: null,
          currentFilter: currentFilter,
          hasMore: newRecords.length >= currentFilter.limit,
          total: allRecords.length,
        );
      }

      print(
        '[MEDICAL_RECORDS_VM] Loaded ${newRecords.length} records, total: ${state.records.length}',
      );
    } catch (e) {
      print('[MEDICAL_RECORDS_VM] Error loading records: $e');

      // Check if this is a "feature under development" error
      final errorMessage = e.toString();
      if (errorMessage.contains('temporarily unavailable') ||
          errorMessage.contains('under development') ||
          errorMessage.contains('500') ||
          errorMessage.contains('not found')) {
        // Provide sample/demo data for testing UI
        final sampleRecords = _generateSampleRecords();
        state = state.copyWith(
          records: sampleRecords,
          isLoading: false,
          error:
              'Demo Mode: Medical Records feature is under development. Showing sample data.',
          currentFilter:
              filter ?? state.currentFilter ?? const MedicalRecordFilter(),
          hasMore: false,
          total: sampleRecords.length,
        );
      } else {
        state = state.copyWith(isLoading: false, error: errorMessage);
      }
    }
  }

  /// Refresh records
  Future<void> refreshRecords() async {
    await loadRecords(refresh: true);
  }

  /// Load more records (pagination)
  Future<void> loadMoreRecords() async {
    if (!state.hasMore || state.isLoading) return;
    await loadRecords();
  }

  /// Filter records
  Future<void> filterRecords(MedicalRecordFilter filter) async {
    await loadRecords(filter: filter, refresh: true);
  }

  /// Clear filter
  Future<void> clearFilter() async {
    await loadRecords(filter: const MedicalRecordFilter(), refresh: true);
  }

  /// Search records by patient name/email
  Future<void> searchRecords(String query) async {
    if (query.isEmpty) {
      await clearFilter();
      return;
    }

    // Note: API doesn't have search by name/email directly
    // We'll filter locally or you can modify API to support this
    final allRecords =
        state.records.where((record) {
          final patientName = record.patientName?.toLowerCase() ?? '';
          final patientEmail = record.patientEmail?.toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();

          return patientName.contains(searchQuery) ||
              patientEmail.contains(searchQuery);
        }).toList();

    state = state.copyWith(records: allRecords, total: allRecords.length);
  }

  /// Generate sample medical records for demo/testing purposes
  List<MedicalRecord> _generateSampleRecords() {
    final now = DateTime.now();
    return [
      MedicalRecord(
        id: 1,
        patientId: 101,
        source: 'clinic',
        bpmData: [
          BpmDataPoint(time: 0.0, bpm: 72.5),
          BpmDataPoint(time: 5.0, bpm: 75.2),
          BpmDataPoint(time: 10.0, bpm: 68.8),
          BpmDataPoint(time: 15.0, bpm: 71.3),
          BpmDataPoint(time: 20.0, bpm: 73.8),
        ],
        startTime: now.subtract(const Duration(hours: 1)).toIso8601String(),
        endTime: now.subtract(const Duration(minutes: 15)).toIso8601String(),
        classification: 'normal',
        notes: 'Regular monitoring session - all vitals normal',
        patientName: 'Sarah Johnson',
        patientEmail: 'sarah.johnson@email.com',
      ),
      MedicalRecord(
        id: 2,
        patientId: 102,
        source: 'home',
        bpmData: [
          BpmDataPoint(time: 0.0, bpm: 85.1),
          BpmDataPoint(time: 3.0, bpm: 88.5),
          BpmDataPoint(time: 6.0, bpm: 90.2),
          BpmDataPoint(time: 9.0, bpm: 87.8),
          BpmDataPoint(time: 12.0, bpm: 89.3),
        ],
        startTime: now.subtract(const Duration(hours: 2)).toIso8601String(),
        endTime:
            now
                .subtract(const Duration(hours: 1, minutes: 45))
                .toIso8601String(),
        classification: 'irregular',
        notes: 'Slightly elevated heart rate during home monitoring',
        patientName: 'Maria Garcia',
        patientEmail: 'maria.garcia@email.com',
      ),
      MedicalRecord(
        id: 3,
        patientId: 103,
        source: 'clinic',
        bpmData: [
          BpmDataPoint(time: 0.0, bpm: 65.3),
          BpmDataPoint(time: 4.0, bpm: 67.8),
          BpmDataPoint(time: 8.0, bpm: 70.1),
          BpmDataPoint(time: 12.0, bpm: 68.5),
          BpmDataPoint(time: 16.0, bpm: 66.9),
        ],
        startTime: now.subtract(const Duration(hours: 3)).toIso8601String(),
        endTime:
            now
                .subtract(const Duration(hours: 2, minutes: 45))
                .toIso8601String(),
        classification: 'normal',
        notes: 'Excellent vital signs - patient is healthy',
        patientName: 'Emma Wilson',
        patientEmail: 'emma.wilson@email.com',
      ),
    ];
  }
}

/// State untuk patient monitoring history (doctor endpoint)
class PatientMonitoringState {
  final PatientMonitoringHistory? history;
  final bool isLoading;
  final String? error;

  const PatientMonitoringState({
    this.history,
    this.isLoading = false,
    this.error,
  });

  PatientMonitoringState copyWith({
    PatientMonitoringHistory? history,
    bool? isLoading,
    String? error,
  }) {
    return PatientMonitoringState(
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier untuk patient monitoring history
class PatientMonitoringNotifier extends StateNotifier<PatientMonitoringState> {
  final MedicalRecordsApiService _apiService;

  PatientMonitoringNotifier(this._apiService)
    : super(const PatientMonitoringState());

  /// Load monitoring history untuk pasien tertentu
  Future<void> loadPatientHistory({
    required int patientId,
    int limit = 10,
    int offset = 0,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      print('[PATIENT_MONITORING_VM] Loading history for patient $patientId');

      final history = await _apiService.getPatientMonitoringHistory(
        patientId: patientId,
        limit: limit,
        offset: offset,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

      state = state.copyWith(history: history, isLoading: false, error: null);

      print(
        '[PATIENT_MONITORING_VM] Loaded ${history.records.length} records for patient ${history.patient.name}',
      );
    } catch (e) {
      print('[PATIENT_MONITORING_VM] Error loading patient history: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load more records
  Future<void> loadMore(int patientId) async {
    final current = state.history;
    if (current == null) return;

    await loadPatientHistory(
      patientId: patientId,
      limit: current.limit,
      offset: current.offset + current.limit,
    );
  }
}

/// Providers
final medicalRecordsApiServiceProvider = Provider<MedicalRecordsApiService>((
  ref,
) {
  final apiClient = ApiClient();
  return MedicalRecordsApiService(apiClient);
});

final medicalRecordsProvider =
    StateNotifierProvider<MedicalRecordsNotifier, MedicalRecordsState>((ref) {
      final apiService = ref.read(medicalRecordsApiServiceProvider);
      return MedicalRecordsNotifier(apiService);
    });

final patientMonitoringProvider =
    StateNotifierProvider<PatientMonitoringNotifier, PatientMonitoringState>((
      ref,
    ) {
      final apiService = ref.read(medicalRecordsApiServiceProvider);
      return PatientMonitoringNotifier(apiService);
    });
