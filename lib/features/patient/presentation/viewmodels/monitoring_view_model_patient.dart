import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../features/doctor/presentation/widgets/esp32_ble_bpm_stream_widget.dart';
import '../../data/services/monitoring_api_service_patient.dart';

class BpmPoint {
  final Duration time;
  final int bpm;
  BpmPoint(this.time, this.bpm);
}

class MonitoringViewModelPatient extends ChangeNotifier {
  int bpm = 120;
  String _patientName = '';
  String _patientId = '';
  bool isConnected = false;
  bool isMonitoring = false;
  bool monitoringDone = false;
  String? monitoringResult;
  String? classification;
  List<BpmPoint> bpmData = [];
  Esp32BleBpmStreamWidgetController? bleController;
  DateTime? monitoringStartTime;
  bool _disposed = false;

  MonitoringViewModelPatient();

  void setPatientInfo({required String name, required String id}) {
    _patientName = name;
    _patientId = id;
    notifyListeners();
  }

  void connectESP32() {
    isConnected = true;
    notifyListeners();
  }

  void disconnectESP32({bool silent = false}) {
    isConnected = false;
    isMonitoring = false;
    monitoringDone = false;
    monitoringResult = null;
    classification = null;
    if (!silent) notifyListeners();
  }

  void setBleController(Esp32BleBpmStreamWidgetController controller) {
    bleController = controller;
  }

  Future<void> startMonitoringESP32() async {
    try {
      await bleController?.sendCommand('start');
    } catch (e) {
      debugPrint('Failed to send start command to ESP32: $e');
    }
  }

  Future<void> stopMonitoringESP32() async {
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

  void stopMonitoring(BuildContext context) async {
    await stopMonitoringESP32();
    isMonitoring = false;
    notifyListeners();
    // Simulasi hasil monitoring (di real app, dapat dari API)
    monitoringResult = 'Normal';
    classification = 'Tidak terdeteksi kelainan';
    monitoringDone = true;
    notifyListeners();
  }

  void updateBpmFromEsp32(int bpmValue) {
    final now = DateTime.now();
    final start = monitoringStartTime ?? now;
    bpm = bpmValue;
    bpmData.add(BpmPoint(now.difference(start), bpmValue));
    notifyListeners();
  }

  List<BpmPoint> get bpmDataForChart => bpmData;

  void resetAllMonitoringState() {
    isConnected = false;
    isMonitoring = false;
    monitoringDone = false;
    monitoringResult = null;
    classification = null;
    bpmData = [];
    _patientName = '';
    _patientId = '';
    monitoringStartTime = null;
    notifyListeners();
  }

  String get patientName => _patientName;
  String get patientId => _patientId;

  void setPatientName(String name) {
    _patientName = name;
    notifyListeners();
  }

  void setPatientId(String id) {
    _patientId = id;
    notifyListeners();
  }

  Future<void> saveResult(BuildContext context) async {
    // Kirim data ke backend (API call)
    debugPrint(
      '[PATIENT] Simpan hasil: nama=$_patientName, id=$_patientId, bpmData=bpmData.length}',
    );
    final api = MonitoringApiServicePatient();
    final bpmDataList =
        bpmData.map((e) => {'time': e.time.inSeconds, 'bpm': e.bpm}).toList();
    final success = await api.sendMonitoringResultPatient(
      patientId: _patientId,
      bpmData: bpmDataList,
      classification: classification,
      monitoringResult: monitoringResult,
    );
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hasil monitoring berhasil disimpan ke server!'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan hasil monitoring ke server!'),
        ),
      );
    }
    monitoringDone = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}

final monitoringViewModelPatientProvider =
    AutoDisposeChangeNotifierProvider<MonitoringViewModelPatient>(
      (ref) => MonitoringViewModelPatient(),
    );
