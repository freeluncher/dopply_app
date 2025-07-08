// Medical Monitoring API Service
// Endpoints: /monitoring, /classify_bmp, /monitoring_record, /patient/monitoring, dll

import 'dart:convert';
import './api_client.dart';

/// Service untuk Medical Monitoring endpoints
class MonitoringApiService {
  final ApiClient _apiClient = ApiClient();

  /// Send monitoring result - POST /monitoring
  Future<Map<String, dynamic>> sendMonitoringResult({
    required int patientId,
    required List<double> bpmData,
    String? doctorNote,
    int? doctorId,
  }) async {
    final response = await _apiClient.post(
      '/monitoring',
      body: {
        'patient_id': patientId,
        'bpm_data': bpmData,
        if (doctorNote != null) 'doctor_note': doctorNote,
        if (doctorId != null) 'doctor_id': doctorId,
      },
    );

    return json.decode(response.body);
  }

  /// Classify BPM data - POST /classify_bmp
  Future<Map<String, dynamic>> classifyBPM({
    required List<double> bpmData,
  }) async {
    final response = await _apiClient.post(
      '/classify_bmp',
      body: {'bpm_data': bpmData},
    );

    return json.decode(response.body);
  }

  /// Save monitoring record - POST /monitoring_record
  Future<Map<String, dynamic>> saveMonitoringRecord({
    required Map<String, dynamic> recordData,
  }) async {
    final response = await _apiClient.post(
      '/monitoring_record',
      body: recordData,
    );
    return json.decode(response.body);
  }

  /// Patient self monitoring - POST /patient/monitoring
  Future<Map<String, dynamic>> patientSelfMonitoring({
    required List<double> bpmData,
    String? notes,
  }) async {
    final response = await _apiClient.post(
      '/patient/monitoring',
      body: {'bmp_data': bpmData, if (notes != null) 'notes': notes},
    );

    return json.decode(response.body);
  }

  /// Get patient monitoring history - GET /patient/monitoring/history
  Future<List<Map<String, dynamic>>> getPatientMonitoringHistory() async {
    try {
      final response = await _apiClient.get('/patient/monitoring/history');
      final data = json.decode(response.body);

      // Handle different response formats
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data.containsKey('data')) {
        // In case backend returns {data: [...]}
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Invalid response format from server');
      }
    } catch (e) {
      // Add more specific error information
      final errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('502') ||
          errorMessage.contains('bad gateway')) {
        throw Exception(
          'Server temporarily unavailable. Please try again in a few minutes.',
        );
      } else if (errorMessage.contains('attributeerror') ||
          errorMessage.contains('patient_id') ||
          errorMessage.contains('500')) {
        throw Exception('Server configuration error. Please try again later.');
      } else if (errorMessage.contains('network') ||
          errorMessage.contains('connection')) {
        throw Exception(
          'Network connection error. Please check your internet connection.',
        );
      }

      rethrow;
    }
  }

  /// Share monitoring to doctor - POST /patient/share_monitoring
  Future<Map<String, dynamic>> shareMonitoringToDoctor({
    required int monitoringId,
    required int doctorId,
  }) async {
    final response = await _apiClient.post(
      '/patient/share_monitoring',
      body: {'monitoring_id': monitoringId, 'doctor_id': doctorId},
    );

    return json.decode(response.body);
  }
}
