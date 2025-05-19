import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/monitoring_api_service.dart';
import 'package:dopply_app/features/auth/presentation/viewmodels/user_provider.dart';
import 'package:dopply_app/features/auth/data/datasources/auth_local_datasource.dart';
import '../../data/services/patient_api_service.dart';
import 'package:dopply_app/features/doctor/presentation/widgets/esp32_ble_bpm_stream_widget.dart';

final patientsByDoctorProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final api = MonitoringApiService();
  final token = await AuthLocalDataSource().getToken();
  if (token == null) return [];
  final user = ref.read(userProvider);
  final doctorId = user?.doctorId ?? user?.id;
  if (doctorId == null) return [];
  return await api.getPatientsByDoctorId(
    token,
    doctorId: int.parse(doctorId.toString()),
  );
});

class BpmPoint {
  final Duration time;
  final int bpm;
  BpmPoint(this.time, this.bpm);
}

class MonitoringViewModel extends ChangeNotifier {
  int bpm = 120;
  String selectedPatient = 'Belum ada pasien dipilih';
  bool isConnected = false;
  bool isMonitoring = false;
  bool monitoringDone = false;
  String? monitoringResult; // hasil dari API (normal/abnormal)
  String? classification; // takikardia/bradikardia/atrial fibrilasi
  String doctorNote = '';
  List<BpmPoint> bpmData = [];
  String patientId = '001'; // contoh, sebaiknya dari data pasien
  final Ref ref;
  List<Map<String, dynamic>> filteredPatients = [];
  String searchQuery = '';

  String esp32Ip = '192.168.1.100'; // Ganti dengan IP ESP32 Anda
  Esp32BleBpmStreamWidgetController? bleController;
  DateTime? monitoringStartTime;

  MonitoringViewModel(this.ref);

  void selectPatient({required String patientName, required String patientId}) {
    selectedPatient = patientName;
    this.patientId = patientId;
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
    notifyListeners();
  }

  void setBleController(Esp32BleBpmStreamWidgetController controller) {
    bleController = controller;
  }

  Future<void> startMonitoringESP32() async {
    // Ganti: kirim perintah BLE
    try {
      await bleController?.sendCommand('start');
    } catch (e) {
      debugPrint('Failed to send start command to ESP32: $e');
    }
  }

  Future<void> stopMonitoringESP32() async {
    // Ganti: kirim perintah BLE
    try {
      await bleController?.sendCommand('stop');
    } catch (e) {
      debugPrint('Failed to send stop command to ESP32: $e');
    }
  }

  void startMonitoring() {
    isMonitoring = true;
    monitoringDone = false;
    monitoringResult = null;
    classification = null;
    bpmData = [];
    monitoringStartTime = DateTime.now();
    notifyListeners();
    startMonitoringESP32();
  }

  void stopMonitoring() async {
    await stopMonitoringESP32();
    isMonitoring = false;
    monitoringDone = false;
    notifyListeners();
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

  Future<void> addNewPatient({
    required String name,
    required String email,
    required String phone,
  }) async {
    final api = PatientApiService();
    final data = {'name': name, 'email': email, 'phone': phone};
    final success = await api.addPatientByDoctor(data);
    if (!success) {
      throw Exception('Gagal menambah pasien. Email mungkin sudah terdaftar.');
    }
  }

  Future<void> addNewPatientAndAssignToDoctor({
    required String name,
    required String email,
    String? phone,
    String? birthDate,
    String? address,
    String? medicalNote,
    void Function(String?)? onError,
  }) async {
    final api = PatientApiService();
    final data = {
      'name': name,
      'email': email,
      'password': '',
      'role': 'patient',
      if (phone != null) 'phone': phone,
      if (birthDate != null) 'birth_date': birthDate,
      if (address != null) 'address': address,
      if (medicalNote != null) 'medical_note': medicalNote,
    };
    final newPatient = await api.registerPatient(data, onError: onError);
    if (newPatient == null) {
      throw Exception('Gagal menambah pasien. Email mungkin sudah terdaftar.');
    }
    // Assign ke dokter yang login
    final user = ref.read(userProvider);
    final doctorId = user?.doctorId ?? user?.id;
    if (doctorId == null) {
      throw Exception('Gagal assign pasien: doctorId tidak ditemukan!');
    }
    final assignSuccess = await api.assignPatientToDoctorByEmail(
      doctorId: int.parse(doctorId.toString()),
      email: newPatient['email'] ?? email,
      status: 'active',
      onError: onError,
    );
    if (!assignSuccess) {
      throw Exception('Gagal assign pasien ke dokter!');
    }
  }

  void updateBpmFromEsp32(dynamic data) {
    // data: format "<elapsed_ms>,<bpm>"
    if (data is int) {
      // fallback: jika hanya BPM saja
      if (isMonitoring) {
        final now = DateTime.now();
        final elapsed =
            monitoringStartTime != null
                ? now.difference(monitoringStartTime!)
                : Duration.zero;
        bpmData.add(BpmPoint(elapsed, data));
        if (bpmData.length > 120) bpmData.removeAt(0);
      }
      bpm = data;
      notifyListeners();
      return;
    }
    if (data is String && data.contains(',')) {
      final parts = data.split(',');
      if (parts.length == 2) {
        final elapsedMs = int.tryParse(parts[0]) ?? 0;
        final bpmVal = int.tryParse(parts[1]) ?? 0;
        if (isMonitoring) {
          bpmData.add(BpmPoint(Duration(milliseconds: elapsedMs), bpmVal));
          if (bpmData.length > 120) bpmData.removeAt(0);
        }
        bpm = bpmVal;
        notifyListeners();
      }
    }
  }

  // Getter yang aman: hanya return List<BpmPoint>, konversi jika perlu
  List<BpmPoint> get bpmDataForChart {
    if (bpmData.isEmpty) return [];
    // Jika sudah List<BpmPoint>, langsung return
    if (bpmData.first.runtimeType.toString() == 'BpmPoint') {
      return bpmData;
    } else {
      // Jika bukan, konversi dari List<int>
      return bpmData
          .asMap()
          .entries
          .map((e) => BpmPoint(Duration(seconds: e.key), e.value as int))
          .toList();
    }
  }

  Future<void> classifyBpmData() async {
    final bpmList =
        bpmDataForChart
            .map((e) => {'time': e.time.inSeconds, 'bpm': e.bpm})
            .toList();
    final api = MonitoringApiService();
    try {
      final response = await api.classifyBpmData({'bpm_data': bpmList});
      if (response != null) {
        classification = response['classification'];
        monitoringResult = response['result'];
        monitoringDone = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Gagal klasifikasi BPM: $e');
    }
  }

  Future<void> saveMonitoringRecord() async {
    final user = ref.read(userProvider);
    final doctorId = user?.doctorId ?? user?.id;
    final recordData = {
      'patient_id': patientId,
      'doctor_id': doctorId,
      'start_time': monitoringStartTime?.toIso8601String(),
      'end_time': DateTime.now().toIso8601String(),
      'bpm_data':
          bpmDataForChart
              .map((e) => {'time': e.time.inSeconds, 'bpm': e.bpm})
              .toList(),
      'result': monitoringResult,
      'classification': classification,
      'doctor_note': doctorNote,
    };
    final api = MonitoringApiService();
    try {
      await api.saveRecord(recordData);
      // Tampilkan notifikasi sukses/gagal jika perlu
      monitoringDone = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Gagal simpan record: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

final monitoringViewModelProvider = ChangeNotifierProvider(
  (ref) => MonitoringViewModel(ref),
);
