// Patient Management API Service
// Endpoints: /patients, /patients/{id}, /patient/profile

import 'dart:convert';
import './api_client.dart';

/// Service untuk Patient Management endpoints
class PatientApiService {
  final ApiClient _apiClient = ApiClient();

  /// Get patient profile (Patient only) - GET /patient/profile
  Future<Map<String, dynamic>> getPatientProfile() async {
    final response = await _apiClient.get('/patient/profile');
    return json.decode(response.body);
  }

  // ===== ADMIN & DOCTOR ENDPOINTS =====

  /// Get all patients (Admin/Doctor only) - GET /patients
  Future<List<Map<String, dynamic>>> getAllPatients() async {
    final response = await _apiClient.get('/patients');
    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Get patient by ID (Admin/Doctor only) - GET /patients/{patient_id}
  Future<Map<String, dynamic>> getPatientById({required int patientId}) async {
    final response = await _apiClient.get('/patients/$patientId');
    return json.decode(response.body);
  }

  /// Create patient (Admin/Doctor only) - POST /patients
  Future<Map<String, dynamic>> createPatient({
    required Map<String, dynamic> patientData,
  }) async {
    final response = await _apiClient.post('/patients', body: patientData);
    return json.decode(response.body);
  }

  /// Update patient (Admin/Doctor only) - PUT /patients/{patient_id}
  Future<Map<String, dynamic>> updatePatient({
    required int patientId,
    required Map<String, dynamic> patientData,
  }) async {
    final response = await _apiClient.put(
      '/patients/$patientId',
      body: patientData,
    );
    return json.decode(response.body);
  }

  /// Delete patient (Admin/Doctor only) - DELETE /patients/{patient_id}
  Future<Map<String, dynamic>> deletePatient({required int patientId}) async {
    final response = await _apiClient.delete('/patients/$patientId');
    return json.decode(response.body);
  }
}
