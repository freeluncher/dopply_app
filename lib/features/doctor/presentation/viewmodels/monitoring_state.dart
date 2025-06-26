import '../models/monitoring_patient.dart';

/// State utama untuk monitoring BPM dan BLE
class MonitoringState {
  final int bpm;
  final String selectedPatientName;
  final String selectedPatientId;
  final bool isConnected;
  final bool isMonitoring;
  final bool monitoringDone;
  final String? monitoringResult;
  final String? classification;
  final String doctorNote;
  final List<int> bpmData;
  final List<Map<String, dynamic>> filteredPatients;
  final String searchQuery;
  final String? bleError;
  final List<MonitoringPatient> filteredPatientModels;

  MonitoringState({
    this.bpm = 120,
    this.selectedPatientName = 'Belum ada pasien dipilih',
    this.selectedPatientId = '',
    this.isConnected = false,
    this.isMonitoring = false,
    this.monitoringDone = false,
    this.monitoringResult,
    this.classification,
    this.doctorNote = '',
    this.bpmData = const [],
    this.filteredPatients = const [],
    this.searchQuery = '',
    this.bleError,
    this.filteredPatientModels = const [],
  });

  MonitoringState copyWith({
    int? bpm,
    String? selectedPatientName,
    String? selectedPatientId,
    bool? isConnected,
    bool? isMonitoring,
    bool? monitoringDone,
    String? monitoringResult,
    String? classification,
    String? doctorNote,
    List<int>? bpmData,
    List<Map<String, dynamic>>? filteredPatients,
    String? searchQuery,
    String? bleError,
    List<MonitoringPatient>? filteredPatientModels,
  }) {
    return MonitoringState(
      bpm: bpm ?? this.bpm,
      selectedPatientName: selectedPatientName ?? this.selectedPatientName,
      selectedPatientId: selectedPatientId ?? this.selectedPatientId,
      isConnected: isConnected ?? this.isConnected,
      isMonitoring: isMonitoring ?? this.isMonitoring,
      monitoringDone: monitoringDone ?? this.monitoringDone,
      monitoringResult: monitoringResult ?? this.monitoringResult,
      classification: classification ?? this.classification,
      doctorNote: doctorNote ?? this.doctorNote,
      bpmData: bpmData ?? this.bpmData,
      filteredPatients: filteredPatients ?? this.filteredPatients,
      searchQuery: searchQuery ?? this.searchQuery,
      bleError: bleError ?? this.bleError,
      filteredPatientModels:
          filteredPatientModels ?? this.filteredPatientModels,
    );
  }
}
