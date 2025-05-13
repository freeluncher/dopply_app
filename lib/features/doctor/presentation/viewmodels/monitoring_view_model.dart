import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/monitoring_api_service.dart';
import 'package:dopply_app/features/auth/presentation/viewmodels/user_provider.dart';
import 'package:dopply_app/features/auth/data/datasources/auth_local_datasource.dart';

final patientsByDoctorProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final api = MonitoringApiService();
  final token = await AuthLocalDataSource().getToken();
  if (token == null) return [];
  return await api.getPatientsByDoctorId(token);
});

class MonitoringViewModel extends ChangeNotifier {
  int bpm = 120;
  String selectedPatient = 'Belum ada pasien dipilih';
  bool isConnected = false;
  bool isMonitoring = false;
  bool monitoringDone = false;
  String? monitoringResult; // hasil dari API (normal/abnormal)
  String? classification; // takikardia/bradikardia/atrial fibrilasi
  String doctorNote = '';
  Timer? _bpmTimer;
  List<int> bpmData = [];
  String patientId = '001'; // contoh, sebaiknya dari data pasien
  final MonitoringApiService _apiService = MonitoringApiService();
  final Ref ref;
  List<Map<String, dynamic>> filteredPatients = [];
  String searchQuery = '';

  MonitoringViewModel(this.ref);

  void selectPatient(String patient) {
    selectedPatient = patient;
    notifyListeners();
  }

  void connectESP32() {
    isConnected = true;
    notifyListeners();
  }

  void disconnectESP32() {
    isConnected = false;
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
        patientId: patientId,
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

  @override
  void dispose() {
    _bpmTimer?.cancel();
    super.dispose();
  }
}

final monitoringViewModelProvider = ChangeNotifierProvider(
  (ref) => MonitoringViewModel(ref),
);
