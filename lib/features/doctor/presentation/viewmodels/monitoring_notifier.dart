import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'monitoring_state.dart';
import '../models/monitoring_patient.dart';
import '../../data/services/monitoring_api_service.dart';
import 'package:dopply_app/features/auth/presentation/viewmodels/user_provider.dart';
import '../../presentation/services/esp32_ble_service.dart';
import 'package:dopply_app/features/doctor/presentation/viewmodels/bpm_point.dart';
import 'package:dopply_app/features/doctor/presentation/widgets/esp32_ble_bpm_stream_widget.dart';
import 'dart:async';

class MonitoringNotifier extends StateNotifier<MonitoringState> {
  final Ref ref;
  final MonitoringApiService _apiService = MonitoringApiService();
  Timer? _bpmTimer;
  Esp32BleService bleService = Esp32BleService();

  MonitoringNotifier(this.ref) : super(MonitoringState());

  void selectPatientModel(MonitoringPatient patient) {
    state = state.copyWith(
      selectedPatientId: patient.id,
      selectedPatientName: patient.name,
    );
  }

  void setBleController(Esp32BleBpmStreamWidgetController controller) {
    bleService.setBleController(controller);
  }

  void connectESP32() {
    try {
      bleService.connect();
      state = state.copyWith(
        isConnected: bleService.isConnected,
        bleError: bleService.bleError,
      );
    } catch (e) {
      state = state.copyWith(bleError: e.toString());
    }
  }

  void disconnectESP32() {
    try {
      bleService.disconnect();
      state = state.copyWith(
        isConnected: bleService.isConnected,
        bleError: bleService.bleError,
        isMonitoring: false,
        monitoringDone: false,
        monitoringResult: null,
        classification: null,
      );
      _bpmTimer?.cancel();
    } catch (e) {
      state = state.copyWith(bleError: e.toString());
    }
  }

  void startMonitoring() {
    try {
      state = state.copyWith(
        isMonitoring: true,
        monitoringDone: false,
        monitoringResult: null,
        classification: null,
        bpmData: [],
      );
      _bpmTimer?.cancel();
      _bpmTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final newBpm = 110 + (state.bpm + 1) % 30;
        final newBpmData = List<int>.from(state.bpmData)..add(newBpm);
        state = state.copyWith(bpm: newBpm, bpmData: newBpmData);
      });
      Future.delayed(const Duration(seconds: 10), () async {
        _bpmTimer?.cancel();
        try {
          final user = ref.read(userProvider);
          String? doctorIdToSend;
          if (user != null && user.role == 'doctor') {
            doctorIdToSend = user.doctorId ?? user.id;
          }
          final apiResult = await _apiService.sendMonitoringResult(
            patientId: state.selectedPatientId,
            bpmData: state.bpmData,
            doctorNote: state.doctorNote,
            doctorId: doctorIdToSend,
          );
          String? monitoringResult;
          String? classification;
          if (apiResult != null) {
            monitoringResult = apiResult['result'] ?? 'Unknown';
            classification = apiResult['classification'] ?? null;
          } else {
            monitoringResult = 'Gagal mengirim ke API';
            classification = null;
          }
          state = state.copyWith(
            isMonitoring: false,
            monitoringDone: true,
            monitoringResult: monitoringResult,
            classification: classification,
          );
        } catch (e) {
          state = state.copyWith(
            isMonitoring: false,
            monitoringDone: true,
            monitoringResult: e.toString(),
            classification: null,
          );
        }
      });
    } catch (e) {
      state = state.copyWith(
        isMonitoring: false,
        monitoringDone: false,
        monitoringResult: e.toString(),
        classification: null,
      );
    }
  }

  void updateDoctorNote(String note) {
    state = state.copyWith(doctorNote: note);
  }

  Future<bool> saveResult() async {
    try {
      state = state.copyWith(monitoringDone: false, doctorNote: '');
      return true;
    } catch (e) {
      state = state.copyWith(bleError: e.toString());
      return false;
    }
  }

  void filterPatientsModel(List<Map<String, dynamic>> patients, String query) {
    try {
      final filteredModels =
          patients
              .where(
                (p) => (p['name'] ?? '').toLowerCase().contains(
                  query.toLowerCase(),
                ),
              )
              .map((p) => MonitoringPatient.fromMap(p))
              .toList();
      state = state.copyWith(
        searchQuery: query,
        filteredPatients: patients,
        filteredPatientModels: filteredModels,
      );
    } catch (e) {
      state = state.copyWith(bleError: e.toString());
    }
  }

  void stopMonitoringESP32() {
    try {
      bleService.stopMonitoring();
      state = state.copyWith(bleError: bleService.bleError);
    } catch (e) {
      state = state.copyWith(bleError: e.toString());
    }
  }

  void updateBpmFromEsp32(int bpmValue) {
    try {
      final newBpmData = List<int>.from(state.bpmData)..add(bpmValue);
      state = state.copyWith(bpm: bpmValue, bpmData: newBpmData);
    } catch (e) {
      state = state.copyWith(bleError: e.toString());
    }
  }

  List<BpmPoint> get bpmDataForChart =>
      state.bpmData
          .asMap()
          .entries
          .map((e) => BpmPoint(Duration(seconds: e.key), e.value))
          .toList();

  void stopMonitoring() {
    stopMonitoringESP32();
    state = state.copyWith(
      isMonitoring: false,
      monitoringResult: 'Normal',
      classification: 'Tidak terdeteksi kelainan',
      monitoringDone: true,
    );
  }

  void resetAllMonitoringState() {
    state = MonitoringState();
  }
}

final monitoringNotifierProvider =
    StateNotifierProvider.autoDispose<MonitoringNotifier, MonitoringState>(
      (ref) => MonitoringNotifier(ref),
    );
