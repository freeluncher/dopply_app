// =============================================================================
// Fetal Monitoring API Service
//
// Handles API communication for fetal heart rate monitoring
// =============================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fetal_monitoring.dart';

class FetalMonitoringApiService {
  static const String _baseUrl = 'https://dopply.my.id/api/v1';

  // Headers for API requests
  Map<String, String> _getHeaders({String? token}) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  /// Classify fetal BPM data
  Future<FetalMonitoringResult> classifyFetalBPM({
    required int bpm,
    required int gestationalAge,
    required List<FetalHeartRateReading> readings,
    String? token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/fetal/classify_bpm');
      final body = jsonEncode({
        'bpm': bpm,
        'gestational_age': gestationalAge,
        'readings': readings.map((r) => r.toJson()).toList(),
        'monitoring_type': 'fetal',
      });

      print('[FETAL_API] Classifying BPM: $bpm for GA: $gestationalAge weeks');

      final response = await http.post(
        url,
        headers: _getHeaders(token: token),
        body: body,
      );

      print('[FETAL_API] Classification response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[FETAL_API] Classification result: $data');
        return FetalMonitoringResult.fromJson(data);
      } else {
        throw Exception('Classification failed: ${response.body}');
      }
    } catch (e) {
      print('[FETAL_API] Error classifying BPM: $e');
      // Return default classification on error
      return FetalMonitoringResult(
        overallClassification: _getDefaultClassification(bpm, gestationalAge),
        averageBPM: bpm.toDouble(),
        findings: ['Manual classification due to API error'],
        recommendations: ['Consult with healthcare provider'],
        riskLevel: 'medium',
      );
    }
  }

  /// Save fetal monitoring session
  Future<FetalMonitoringSession> saveMonitoringSession({
    required FetalMonitoringSession session,
    String? token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/fetal/monitoring_sessions');
      final body = jsonEncode(session.toJson());

      print('[FETAL_API] Saving monitoring session: ${session.id}');

      final response = await http.post(
        url,
        headers: _getHeaders(token: token),
        body: body,
      );

      print('[FETAL_API] Save session response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('[FETAL_API] Session saved successfully');
        return FetalMonitoringSession.fromJson(data);
      } else {
        throw Exception('Failed to save session: ${response.body}');
      }
    } catch (e) {
      print('[FETAL_API] Error saving session: $e');
      throw Exception('Failed to save monitoring session: $e');
    }
  }

  /// Get monitoring sessions for patient
  Future<List<FetalMonitoringSession>> getPatientMonitoringSessions({
    required int patientId,
    int? limit,
    String? token,
  }) async {
    try {
      var url = Uri.parse('$_baseUrl/fetal/patients/$patientId/sessions');
      if (limit != null) {
        url = url.replace(queryParameters: {'limit': limit.toString()});
      }

      print('[FETAL_API] Getting sessions for patient: $patientId');

      final response = await http.get(url, headers: _getHeaders(token: token));

      print('[FETAL_API] Get sessions response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessions =
            (data['sessions'] as List)
                .map((s) => FetalMonitoringSession.fromJson(s))
                .toList();

        print('[FETAL_API] Retrieved ${sessions.length} sessions');
        return sessions;
      } else {
        throw Exception('Failed to get sessions: ${response.body}');
      }
    } catch (e) {
      print('[FETAL_API] Error getting sessions: $e');
      return [];
    }
  }

  /// Get monitoring sessions for doctor
  Future<List<FetalMonitoringSession>> getDoctorMonitoringSessions({
    required int doctorId,
    int? limit,
    String? token,
  }) async {
    try {
      var url = Uri.parse('$_baseUrl/fetal/doctors/$doctorId/sessions');
      if (limit != null) {
        url = url.replace(queryParameters: {'limit': limit.toString()});
      }

      print('[FETAL_API] Getting sessions for doctor: $doctorId');

      final response = await http.get(url, headers: _getHeaders(token: token));

      print('[FETAL_API] Get doctor sessions response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessions =
            (data['sessions'] as List)
                .map((s) => FetalMonitoringSession.fromJson(s))
                .toList();

        print('[FETAL_API] Retrieved ${sessions.length} doctor sessions');
        return sessions;
      } else {
        throw Exception('Failed to get doctor sessions: ${response.body}');
      }
    } catch (e) {
      print('[FETAL_API] Error getting doctor sessions: $e');
      return [];
    }
  }

  /// Share monitoring session with doctor
  Future<bool> shareSessionWithDoctor({
    required String sessionId,
    required int doctorId,
    String? notes,
    String? token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/fetal/sessions/$sessionId/share');
      final body = jsonEncode({'doctor_id': doctorId, 'notes': notes});

      print('[FETAL_API] Sharing session $sessionId with doctor $doctorId');

      final response = await http.post(
        url,
        headers: _getHeaders(token: token),
        body: body,
      );

      print('[FETAL_API] Share session response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('[FETAL_API] Session shared successfully');
        return true;
      } else {
        throw Exception('Failed to share session: ${response.body}');
      }
    } catch (e) {
      print('[FETAL_API] Error sharing session: $e');
      return false;
    }
  }

  /// Get patient pregnancy info
  Future<PatientPregnancyInfo?> getPatientPregnancyInfo({
    required int patientId,
    String? token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/fetal/patients/$patientId/pregnancy');

      print('[FETAL_API] Getting pregnancy info for patient: $patientId');

      final response = await http.get(url, headers: _getHeaders(token: token));

      print('[FETAL_API] Get pregnancy info response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[FETAL_API] Retrieved pregnancy info');
        return PatientPregnancyInfo.fromJson(data);
      } else if (response.statusCode == 404) {
        print('[FETAL_API] No pregnancy info found');
        return null;
      } else {
        throw Exception('Failed to get pregnancy info: ${response.body}');
      }
    } catch (e) {
      print('[FETAL_API] Error getting pregnancy info: $e');
      return null;
    }
  }

  /// Update patient pregnancy info
  Future<PatientPregnancyInfo> updatePatientPregnancyInfo({
    required PatientPregnancyInfo pregnancyInfo,
    String? token,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/fetal/patients/${pregnancyInfo.patientId}/pregnancy',
      );
      final body = jsonEncode(pregnancyInfo.toJson());

      print(
        '[FETAL_API] Updating pregnancy info for patient: ${pregnancyInfo.patientId}',
      );

      final response = await http.put(
        url,
        headers: _getHeaders(token: token),
        body: body,
      );

      print(
        '[FETAL_API] Update pregnancy info response: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[FETAL_API] Pregnancy info updated successfully');
        return PatientPregnancyInfo.fromJson(data);
      } else {
        throw Exception('Failed to update pregnancy info: ${response.body}');
      }
    } catch (e) {
      print('[FETAL_API] Error updating pregnancy info: $e');
      throw Exception('Failed to update pregnancy info: $e');
    }
  }

  // Helper method for default classification
  String _getDefaultClassification(int bpm, int gestationalAge) {
    if (gestationalAge < 20) {
      if (bpm < 120 || bpm > 180) return 'abnormal';
    } else if (gestationalAge < 32) {
      if (bpm < 115 || bpm > 170) return 'abnormal';
    } else {
      if (bpm < 110 || bpm > 160) return 'abnormal';
    }
    return 'normal';
  }
}
