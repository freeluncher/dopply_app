import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/monitoring_api_service.dart';
import 'package:dopply_app/features/auth/presentation/viewmodels/user_provider.dart';
import 'package:dopply_app/features/doctor/presentation/viewmodels/bpm_point.dart';
import 'package:dopply_app/features/doctor/presentation/widgets/esp32_ble_bpm_stream_widget.dart';

final patientsByDoctorProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final user = ref.read(userProvider);
  if (user == null || user.role != 'doctor') return [];
  final api = MonitoringApiService();
  return await api.getPatientsByDoctorIdWithStorage(
    doctorId: int.parse((user.doctorId ?? user.id).toString()),
  );
});

class MonitoringViewModel extends ChangeNotifier {
  int bpm = 120;
  String selectedPatientName = 'Belum ada pasien dipilih';
  String selectedPatientId = '';
  bool isConnected = false;
  bool isMonitoring = false;
  bool monitoringDone = false;
  String? monitoringResult; // hasil dari API (normal/abnormal)
  String? classification; // takikardia/bradikardia/atrial fibrilasi
  String doctorNote = '';
  Timer? _bpmTimer;
  List<int> bpmData = [];
  final MonitoringApiService _apiService = MonitoringApiService();
  final Ref ref;
  List<Map<String, dynamic>> filteredPatients = [];
  String searchQuery = '';
  String? bleError; // Tambahan untuk error BLE

  MonitoringViewModel(this.ref);

  void selectPatient({required String id, required String name}) {
    selectedPatientId = id;
    selectedPatientName = name;
    notifyListeners();
  }

  void connectESP32() {
    try {
      bleController?.connect();
      isConnected = true;
      bleError = null;
    } catch (e) {
      isConnected = false;
      bleError = 'Gagal koneksi BLE: $e';
    }
    notifyListeners();
  }

  void disconnectESP32() {
    try {
      bleController?.disconnect();
      isConnected = false;
      bleError = null;
    } catch (e) {
      bleError = 'Gagal disconnect BLE: $e';
    }
    isMonitoring = false;
    monitoringDone = false;
    monitoringResult = null;
    classification = null;
    _bpmTimer?.cancel();
    notifyListeners();
  }

  void startMonitoring() {
    isMonitoring = true;
    monitoringDone = false;
    monitoringResult = null;
    classification = null;
    bpmData = [];
    notifyListeners();
    _bpmTimer?.cancel();
    _bpmTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      bpm = 110 + (bpm + 1) % 30;
      bpmData.add(bpm);
      notifyListeners();
    });
    Future.delayed(const Duration(seconds: 10), () async {
      _bpmTimer?.cancel();
      isMonitoring = false;
      monitoringDone = true;
      // Ambil user dari provider
      final user = ref.read(userProvider);
      String? doctorIdToSend;
      if (user != null && user.role == 'doctor') {
        doctorIdToSend = user.doctorId ?? user.id;
      }
      // Kirim ke API FastAPI
      final apiResult = await _apiService.sendMonitoringResult(
        patientId: selectedPatientId,
        bpmData: bpmData,
        doctorNote: doctorNote,
        doctorId: doctorIdToSend,
      );
      if (apiResult != null) {
        monitoringResult = apiResult['result'] ?? 'Unknown';
        classification = apiResult['classification'] ?? null;
      } else {
        monitoringResult = 'Gagal mengirim ke API';
        classification = null;
      }
      notifyListeners();
    });
  }

  void updateDoctorNote(String note) {
    doctorNote = note;
    notifyListeners();
  }

  void saveResult(BuildContext context) async {
    // Simpan hasil ke database jika perlu
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hasil pemeriksaan berhasil disimpan!')),
    );
    monitoringDone = false;
    doctorNote = '';
    notifyListeners();
  }

  void filterPatients(List<Map<String, dynamic>> patients, String query) {
    searchQuery = query;
    filteredPatients =
        patients
            .where(
              (p) =>
                  (p['name'] ?? '').toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
    notifyListeners();
  }

  // Tambahan untuk BLE controller
  Esp32BleBpmStreamWidgetController? bleController;
  void setBleController(Esp32BleBpmStreamWidgetController controller) {
    bleController = controller;
    // Jika di masa depan controller BLE punya event/callback, tambahkan sinkronisasi di sini.
  }

  void stopMonitoringESP32() {
    try {
      bleController?.sendCommand('stop');
      bleError = null;
    } catch (e) {
      bleError = 'Gagal stop monitoring BLE: $e';
    }
    notifyListeners();
  }

  void updateBpmFromEsp32(int bpmValue) {
    bpm = bpmValue;
    bpmData.add(bpmValue);
    notifyListeners();
  }

  List<BpmPoint> get bpmDataForChart =>
      bpmData
          .asMap()
          .entries
          .map((e) => BpmPoint(Duration(seconds: e.key), e.value))
          .toList();

  void stopMonitoring(BuildContext context) {
    stopMonitoringESP32();
    isMonitoring = false;
    monitoringResult = 'Normal';
    classification = 'Tidak terdeteksi kelainan';
    monitoringDone = true;
    notifyListeners();
  }

  void resetAllMonitoringState() {
    isConnected = false;
    isMonitoring = false;
    monitoringDone = false;
    monitoringResult = null;
    classification = null;
    bpmData = [];
    selectedPatientName = 'Belum ada pasien dipilih';
    selectedPatientId = '';
    doctorNote = '';
    bleError = null;
    notifyListeners();
  }

  String get patientName => selectedPatientName;
  String get patientId => selectedPatientId;

  @override
  void dispose() {
    _bpmTimer?.cancel();
    super.dispose();
  }
}

final monitoringViewModelProvider = ChangeNotifierProvider.autoDispose(
  (ref) => MonitoringViewModel(ref),
);
