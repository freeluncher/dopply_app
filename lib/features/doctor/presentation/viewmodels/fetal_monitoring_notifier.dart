// =============================================================================
// Fetal Monitoring View Model
//
// State management for fetal heart rate monitoring using the new architecture
// =============================================================================

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/shared/models/fetal_monitoring.dart';
import 'package:dopply_app/shared/services/fetal_doppler_ble_service.dart';
import 'package:dopply_app/shared/services/fetal_monitoring_api_service.dart';
import 'package:dopply_app/features/doctor/presentation/models/monitoring_patient.dart';

// Fetal Monitoring State
class FetalMonitoringState {
  final String? selectedPatientId;
  final String selectedPatientName;
  final MonitoringPatient? selectedPatient;
  final int gestationalAge;
  final FetalMonitoringSession? currentSession;
  final List<FetalHeartRateReading> readings;
  final FetalHeartRateData? latestReading;
  final bool isMonitoring;
  final String? errorMessage;
  final FetalMonitoringResult? result;

  const FetalMonitoringState({
    this.selectedPatientId,
    this.selectedPatientName = 'Belum ada pasien dipilih',
    this.selectedPatient,
    this.gestationalAge = 20,
    this.currentSession,
    this.readings = const [],
    this.latestReading,
    this.isMonitoring = false,
    this.errorMessage,
    this.result,
  });

  FetalMonitoringState copyWith({
    String? selectedPatientId,
    String? selectedPatientName,
    MonitoringPatient? selectedPatient,
    int? gestationalAge,
    FetalMonitoringSession? currentSession,
    List<FetalHeartRateReading>? readings,
    FetalHeartRateData? latestReading,
    bool? isMonitoring,
    String? errorMessage,
    FetalMonitoringResult? result,
  }) {
    return FetalMonitoringState(
      selectedPatientId: selectedPatientId ?? this.selectedPatientId,
      selectedPatientName: selectedPatientName ?? this.selectedPatientName,
      selectedPatient: selectedPatient ?? this.selectedPatient,
      gestationalAge: gestationalAge ?? this.gestationalAge,
      currentSession: currentSession ?? this.currentSession,
      readings: readings ?? this.readings,
      latestReading: latestReading ?? this.latestReading,
      isMonitoring: isMonitoring ?? this.isMonitoring,
      errorMessage: errorMessage ?? this.errorMessage,
      result: result ?? this.result,
    );
  }
}

// Fetal Monitoring Notifier
class FetalMonitoringNotifier extends StateNotifier<FetalMonitoringState> {
  final Ref ref;
  final FetalMonitoringApiService _apiService = FetalMonitoringApiService();
  StreamSubscription<FetalHeartRateData>? _heartRateSubscription;

  FetalMonitoringNotifier(this.ref) : super(const FetalMonitoringState()) {
    _listenToHeartRateData();
  }

  // Listen to heart rate data from BLE service
  void _listenToHeartRateData() {
    final bleService = ref.read(fetalDopplerBLEProvider.notifier);
    _heartRateSubscription = bleService.heartRateStream.listen((data) {
      _processHeartRateData(data);
    });
  }

  // Process incoming heart rate data
  void _processHeartRateData(FetalHeartRateData data) {
    if (!state.isMonitoring) return;

    // Create new reading
    final reading = FetalHeartRateReading(
      timestamp: data.timestamp,
      bpm: data.bpm,
      signalQuality: data.signalQuality,
      classification: data.classification.name, // Convert enum to string
    );

    // Add to readings list
    final updatedReadings = [...state.readings, reading];

    state = state.copyWith(latestReading: data, readings: updatedReadings);
  }

  // Select patient for monitoring
  void selectPatient({
    required String patientId,
    required String patientName,
    required int gestationalAge,
    MonitoringPatient? patient,
  }) {
    state = state.copyWith(
      selectedPatientId: patientId,
      selectedPatientName: patientName,
      selectedPatient: patient,
      gestationalAge: gestationalAge,
    );
  }

  // Select patient using MonitoringPatient object
  void selectPatientObject(MonitoringPatient patient, {int? gestationalAge}) {
    state = state.copyWith(
      selectedPatientId: patient.id,
      selectedPatientName: patient.name,
      selectedPatient: patient,
      gestationalAge: gestationalAge ?? state.gestationalAge,
    );
  }

  // Start monitoring session
  Future<void> startMonitoring({required MonitoringType type}) async {
    try {
      // Create new monitoring session
      final session = FetalMonitoringSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        patientId:
            state.selectedPatientId != null
                ? int.tryParse(state.selectedPatientId!)
                : null,
        type: type,
        gestationalAge: state.gestationalAge,
        startTime: DateTime.now(),
      );

      state = state.copyWith(
        currentSession: session,
        isMonitoring: true,
        readings: [],
        errorMessage: null,
      );

      // Start BLE monitoring
      final bleService = ref.read(fetalDopplerBLEProvider.notifier);
      await bleService.startMonitoring();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to start monitoring: ${e.toString()}',
        isMonitoring: false,
      );
    }
  }

  // Stop monitoring session
  Future<void> stopMonitoring() async {
    try {
      if (state.currentSession == null) return;

      // Stop BLE monitoring
      final bleService = ref.read(fetalDopplerBLEProvider.notifier);
      await bleService.stopMonitoring();

      // Update session with end time and readings
      final updatedSession = state.currentSession!.copyWith(
        endTime: DateTime.now(),
        readings: state.readings,
      );

      state = state.copyWith(
        currentSession: updatedSession,
        isMonitoring: false,
      );

      // Classify the session and get result
      await _classifySession();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to stop monitoring: ${e.toString()}',
        isMonitoring: false,
      );
    }
  }

  // Classify monitoring session
  Future<void> _classifySession() async {
    try {
      if (state.currentSession == null || state.readings.isEmpty) return;

      final bpmData = state.readings.map((r) => r.bpm).toList();
      final avgBpm = bpmData.reduce((a, b) => a + b) / bpmData.length;

      final classificationResult = await _apiService.classifyFetalBPM(
        bpm: avgBpm.round(),
        gestationalAge: state.gestationalAge,
        readings: state.readings,
      );

      state = state.copyWith(result: classificationResult);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to classify session: ${e.toString()}',
      );
    }
  }

  // Save monitoring session
  Future<bool> saveSession({String? doctorNotes}) async {
    try {
      if (state.currentSession == null) return false;

      final sessionToSave = state.currentSession!.copyWith(
        doctorNotes: doctorNotes,
        result: state.result,
      );

      await _apiService.saveMonitoringSession(session: sessionToSave);

      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to save session: ${e.toString()}',
      );
      return false;
    }
  }

  // Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  // Reset monitoring state
  void resetState() {
    state = const FetalMonitoringState();
  }

  @override
  void dispose() {
    _heartRateSubscription?.cancel();
    super.dispose();
  }
}

// Provider for fetal monitoring state
final fetalMonitoringProvider =
    StateNotifierProvider<FetalMonitoringNotifier, FetalMonitoringState>((ref) {
      return FetalMonitoringNotifier(ref);
    });

// Chart data point for compatibility with existing chart widgets
class FetalBpmPoint {
  final Duration time;
  final int bpm;
  final FetalBPMClassification classification;

  FetalBpmPoint(this.time, this.bpm, this.classification);
}

// Provider for chart data
final fetalBpmChartDataProvider = Provider<List<FetalBpmPoint>>((ref) {
  final monitoringState = ref.watch(fetalMonitoringProvider);

  if (monitoringState.currentSession == null) return [];

  final startTime = monitoringState.currentSession!.startTime;

  return monitoringState.readings.map((reading) {
    final duration = reading.timestamp.difference(startTime);
    // Convert string back to enum for chart compatibility
    final classification = FetalBPMClassification.values.firstWhere(
      (c) => c.name == reading.classification,
      orElse: () => FetalBPMClassification.normal,
    );
    return FetalBpmPoint(duration, reading.bpm, classification);
  }).toList();
});
