// Doctor Management API Service
// Endpoints: /doctor/list, /patients/by-doctor, /doctor/validation-requests, dll

import 'dart:convert';
import './api_client.dart';

/// Service untuk Doctor Management endpoints
class DoctorApiService {
  final ApiClient _apiClient = ApiClient();

  /// Get doctor list (For patients) - GET /doctor/list
  Future<List<Map<String, dynamic>>> getDoctorList() async {
    final response = await _apiClient.get('/doctor/list');
    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Get patients by doctor - GET /patients/by-doctor
  Future<List<Map<String, dynamic>>> getPatientsByDoctor() async {
    final response = await _apiClient.get('/patients/by-doctor');
    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Get patients for specific doctor - GET /doctors/{doctor_id}/patients
  Future<Map<String, dynamic>> getPatientsForDoctor({
    required int doctorId,
    String? status,
    int? limit,
    int? offset,
  }) async {
    final Map<String, String> queryParams = {};
    if (status != null) queryParams['status'] = status;
    if (limit != null) queryParams['limit'] = limit.toString();
    if (offset != null) queryParams['offset'] = offset.toString();

    String url = '/doctors/$doctorId/patients';
    if (queryParams.isNotEmpty) {
      final query = queryParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      url += '?$query';
    }

    print('[DOCTOR_API] Getting patients for doctor ID: $doctorId, URL: $url');
    final response = await _apiClient.get(url);
    print('[DOCTOR_API] Patients response status: ${response.statusCode}');
    final data = json.decode(response.body);
    print('[DOCTOR_API] Patients response data: $data');
    return data; // Returns {patients: [...], total: int, limit: int, offset: int}
  }

  /// Get patient details - GET /patients/{patient_id}
  Future<Map<String, dynamic>> getPatientDetails({
    required int patientId,
  }) async {
    final response = await _apiClient.get('/patients/$patientId');
    final data = json.decode(response.body);
    return data;
  }

  /// Get patient monitoring history - GET /patients/{patient_id}/monitoring/history
  Future<Map<String, dynamic>> getPatientMonitoringHistory({
    required int patientId,
    int? limit,
    int? offset,
    String? dateFrom,
    String? dateTo,
  }) async {
    final Map<String, String> queryParams = {};
    if (limit != null) queryParams['limit'] = limit.toString();
    if (offset != null) queryParams['offset'] = offset.toString();
    if (dateFrom != null) queryParams['date_from'] = dateFrom;
    if (dateTo != null) queryParams['date_to'] = dateTo;

    String url = '/patients/$patientId/monitoring/history';
    if (queryParams.isNotEmpty) {
      final query = queryParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      url += '?$query';
    }

    final response = await _apiClient.get(url);
    final data = json.decode(response.body);
    return data; // Returns {patient: {...}, records: [...], total: int, limit: int, offset: int}
  }

  /// Get doctor statistics - GET /doctors/{doctor_id}/statistics
  Future<Map<String, dynamic>> getDoctorStatistics({
    required int doctorId,
  }) async {
    print('[DOCTOR_API] Getting statistics for doctor ID: $doctorId');
    final response = await _apiClient.get('/doctors/$doctorId/statistics');
    print('[DOCTOR_API] Statistics response status: ${response.statusCode}');
    final data = json.decode(response.body);
    print('[DOCTOR_API] Statistics response data: $data');
    return data;
  }

  /// Update patient status - PATCH /doctors/{doctor_id}/patients/{patient_id}/status
  Future<Map<String, dynamic>> updatePatientStatus({
    required int doctorId,
    required int patientId,
    required String status,
    String? notes,
  }) async {
    final Map<String, dynamic> body = {'status': status};
    if (notes != null && notes.isNotEmpty) {
      body['notes'] = notes;
    }

    final response = await _apiClient.patch(
      '/doctors/$doctorId/patients/$patientId/status',
      body: body,
    );
    return json.decode(response.body);
  }

  /// Assign patient to doctor - POST /doctors/{doctor_id}/assign-patient/{patient_id}
  Future<Map<String, dynamic>> assignPatientToDoctor({
    required int doctorId,
    required int patientId,
  }) async {
    final response = await _apiClient.post(
      '/doctors/$doctorId/assign-patient/$patientId',
    );
    return json.decode(response.body);
  }

  /// Assign patient by email - POST /doctors/{doctor_id}/assign-patient-by-email
  Future<Map<String, dynamic>> assignPatientByEmail({
    required int doctorId,
    required String patientEmail,
    String? note,
  }) async {
    final Map<String, dynamic> body = {'patient_email': patientEmail};
    if (note != null && note.isNotEmpty) {
      body['note'] = note;
    }

    final response = await _apiClient.post(
      '/doctors/$doctorId/assign-patient-by-email',
      body: body,
    );
    return json.decode(response.body);
  }

  /// Update doctor-patient association - PATCH /doctors/{doctor_id}/patients/{patient_id}
  Future<Map<String, dynamic>> updateDoctorPatientAssociation({
    required int doctorId,
    required int patientId,
    required Map<String, dynamic> updateData,
  }) async {
    final response = await _apiClient.put(
      '/doctors/$doctorId/patients/$patientId',
      body: updateData,
    );
    return json.decode(response.body);
  }

  /// Unassign patient from doctor - DELETE /doctors/{doctor_id}/unassign-patient/{patient_id}
  Future<Map<String, dynamic>> unassignPatientFromDoctor({
    required int doctorId,
    required int patientId,
  }) async {
    final response = await _apiClient.delete(
      '/doctors/$doctorId/unassign-patient/$patientId',
    );
    return json.decode(response.body);
  }

  // ===== ADMIN ONLY ENDPOINTS =====

  /// Count doctor validation requests (Admin only) - GET /doctor/validation-requests/count
  Future<int> countDoctorValidationRequests() async {
    final response = await _apiClient.get('/doctor/validation-requests/count');
    final data = json.decode(response.body);
    return data['count'] ?? 0;
  }

  /// List doctor validation requests (Admin only) - GET /doctor/validation-requests
  Future<List<Map<String, dynamic>>> listDoctorValidationRequests() async {
    final response = await _apiClient.get('/doctor/validation-requests');
    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Validate doctor (Admin only) - POST /doctor/validate/{doctor_id}
  Future<Map<String, dynamic>> validateDoctor({required int doctorId}) async {
    final response = await _apiClient.post('/doctor/validate/$doctorId');
    return json.decode(response.body);
  }

  // ===== MONITORING ENDPOINTS =====

  /// Save monitoring record - POST /monitoring_record
  Future<Map<String, dynamic>> saveMonitoringRecord({
    required int patientId,
    required List<Map<String, dynamic>> bpmData,
    String? notes,
  }) async {
    final Map<String, dynamic> body = {
      'patient_id': patientId,
      'bpm_data': bpmData,
    };
    if (notes != null && notes.isNotEmpty) {
      body['notes'] = notes;
    }

    final response = await _apiClient.post('/monitoring_record', body: body);
    return json.decode(response.body);
  }

  /// Classify BPM data - POST /classify_bpm
  Future<Map<String, dynamic>> classifyBpm({
    required List<Map<String, dynamic>> bpmData,
  }) async {
    final response = await _apiClient.post(
      '/classify_bpm',
      body: {'bpm_data': bpmData},
    );
    return json.decode(response.body);
  }

  /// Get patient monitoring history - GET /patient/monitoring/history (Patient endpoint)
  Future<List<Map<String, dynamic>>> getPatientOwnMonitoringHistory() async {
    final response = await _apiClient.get('/patient/monitoring/history');
    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Patient self monitoring - POST /patient/monitoring
  Future<Map<String, dynamic>> patientSelfMonitoring({
    required List<Map<String, dynamic>> bpmData,
    String? notes,
  }) async {
    final Map<String, dynamic> body = {'bpm_data': bpmData};
    if (notes != null && notes.isNotEmpty) {
      body['notes'] = notes;
    }

    final response = await _apiClient.post('/patient/monitoring', body: body);
    return json.decode(response.body);
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

  /// Get records with filtering - GET /records
  Future<List<Map<String, dynamic>>> getRecords({
    int? patientId,
    int? doctorId,
    String? dateFrom,
    String? dateTo,
    String? classification,
    String? source,
  }) async {
    final Map<String, String> queryParams = {};
    if (patientId != null) queryParams['patient_id'] = patientId.toString();
    if (doctorId != null) queryParams['doctor_id'] = doctorId.toString();
    if (dateFrom != null) queryParams['date_from'] = dateFrom;
    if (dateTo != null) queryParams['date_to'] = dateTo;
    if (classification != null) queryParams['classification'] = classification;
    if (source != null) queryParams['source'] = source;

    String url = '/records';
    if (queryParams.isNotEmpty) {
      final query = queryParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      url += '?$query';
    }

    final response = await _apiClient.get(url);
    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data);
  }
}
