import 'package:flutter/material.dart';
import '../../data/services/monitoring_history_api_service_patient.dart';

class MonitoringHistoryViewModelPatient extends ChangeNotifier {
  List<Map<String, dynamic>> history = [];
  bool isLoading = false;
  String? error;

  Future<void> fetchHistory() async {
    isLoading = true;
    error = null;
    notifyListeners();
    final api = MonitoringHistoryApiServicePatient();
    try {
      history = await api.fetchMonitoringHistoryPatient();
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }
}
