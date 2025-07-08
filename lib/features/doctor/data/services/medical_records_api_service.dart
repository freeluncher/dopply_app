import 'dart:convert';
import 'package:dopply_app/features/doctor/data/models/medical_record.dart';
import 'package:dopply_app/services/api/api_client.dart';

/// Service untuk mengakses medical records API
class MedicalRecordsApiService {
  final ApiClient _apiClient;

  MedicalRecordsApiService(this._apiClient);

  /// Build URL dengan query parameters
  String _buildUrlWithParams(String endpoint, Map<String, String> params) {
    if (params.isEmpty) return endpoint;

    final queryString = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');

    return '$endpoint?$queryString';
  }

  /// Ambil semua medical records dengan filter
  Future<List<MedicalRecord>> getRecords({MedicalRecordFilter? filter}) async {
    try {
      final queryParams = filter?.toQueryParams() ?? {};
      final endpoint = _buildUrlWithParams('/records', queryParams);

      print('[MEDICAL_RECORDS_API] Getting records with filter: $queryParams');

      final response = await _apiClient.get(endpoint);

      print(
        '[MEDICAL_RECORDS_API] Records response status: ${response.statusCode}',
      );
      print('[MEDICAL_RECORDS_API] Records response data: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final records =
            data
                .map(
                  (json) =>
                      MedicalRecord.fromJson(json as Map<String, dynamic>),
                )
                .toList();

        print('[MEDICAL_RECORDS_API] Parsed ${records.length} records');
        return records;
      } else {
        print(
          '[MEDICAL_RECORDS_API] Error: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Failed to load medical records: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[MEDICAL_RECORDS_API] Exception: $e');

      // Handle specific error cases with user-friendly messages
      final errorMessage = _handleApiError(e);
      throw Exception(errorMessage);
    }
  }

  /// Ambil monitoring history untuk pasien tertentu (doctor only)
  Future<PatientMonitoringHistory> getPatientMonitoringHistory({
    required int patientId,
    int limit = 10,
    int offset = 0,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;

      final endpoint = _buildUrlWithParams(
        '/patients/$patientId/monitoring/history',
        queryParams,
      );

      print(
        '[MEDICAL_RECORDS_API] Getting patient monitoring history for patient ID: $patientId',
      );

      final response = await _apiClient.get(endpoint);

      print(
        '[MEDICAL_RECORDS_API] Patient monitoring response status: ${response.statusCode}',
      );
      print(
        '[MEDICAL_RECORDS_API] Patient monitoring response data: ${response.body}',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return PatientMonitoringHistory.fromJson(data);
      } else {
        print(
          '[MEDICAL_RECORDS_API] Error: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Failed to load patient monitoring history: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[MEDICAL_RECORDS_API] Exception: $e');

      // Handle specific error cases with user-friendly messages
      final errorMessage = _handleApiError(e);
      throw Exception(errorMessage);
    }
  }

  /// Ambil general monitoring history (patient/doctor)
  Future<List<MedicalRecord>> getMonitoringHistory() async {
    try {
      print('[MEDICAL_RECORDS_API] Getting general monitoring history');

      final response = await _apiClient.get('/patient/monitoring/history');

      print(
        '[MEDICAL_RECORDS_API] Monitoring history response status: ${response.statusCode}',
      );
      print(
        '[MEDICAL_RECORDS_API] Monitoring history response data: ${response.body}',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final records =
            data
                .map(
                  (json) =>
                      MedicalRecord.fromJson(json as Map<String, dynamic>),
                )
                .toList();

        print(
          '[MEDICAL_RECORDS_API] Parsed ${records.length} monitoring records',
        );
        return records;
      } else {
        print(
          '[MEDICAL_RECORDS_API] Error: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Failed to load monitoring history: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[MEDICAL_RECORDS_API] Exception: $e');
      rethrow;
    }
  }

  /// Share monitoring result to doctor (patient only)
  Future<bool> shareMonitoringToDoctor({
    required int monitoringId,
    required int doctorId,
  }) async {
    try {
      print(
        '[MEDICAL_RECORDS_API] Sharing monitoring $monitoringId to doctor $doctorId',
      );

      final response = await _apiClient.post(
        '/patient/share_monitoring',
        body: {'monitoring_id': monitoringId, 'doctor_id': doctorId},
      );

      print(
        '[MEDICAL_RECORDS_API] Share monitoring response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        print('[MEDICAL_RECORDS_API] Successfully shared monitoring');
        return true;
      } else {
        print(
          '[MEDICAL_RECORDS_API] Failed to share monitoring: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('[MEDICAL_RECORDS_API] Exception sharing monitoring: $e');
      return false;
    }
  }

  /// Handle API errors and return user-friendly error messages
  String _handleApiError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Handle 500 Internal Server Error
    if (errorString.contains('500') ||
        errorString.contains('internal server error')) {
      return 'Medical Records service is temporarily unavailable. This feature may still be under development. Please try again later.';
    }

    // Handle 404 Not Found
    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'Medical Records endpoint not found. This feature may not be available yet.';
    }

    // Handle 403 Forbidden
    if (errorString.contains('403') ||
        errorString.contains('forbidden') ||
        errorString.contains('access denied')) {
      return 'Access denied. Please check your permissions or contact administrator.';
    }

    // Handle 401 Unauthorized
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'Authentication failed. Please login again.';
    }

    // Handle network/connection errors
    if (errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('timeout')) {
      return 'Network connection error. Please check your internet connection and try again.';
    }

    // Handle JSON parsing errors
    if (errorString.contains('json') || errorString.contains('format')) {
      return 'Data format error. The server response is invalid.';
    }

    // Generic error message for other cases
    if (errorString.length > 100) {
      return 'An unexpected error occurred. Please try again or contact support if the problem persists.';
    }

    return errorString;
  }
}

/// Model untuk patient monitoring history response (doctor endpoint)
class PatientMonitoringHistory {
  final PatientBasicInfo patient;
  final List<MedicalRecord> records;
  final int total;
  final int limit;
  final int offset;

  const PatientMonitoringHistory({
    required this.patient,
    required this.records,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory PatientMonitoringHistory.fromJson(Map<String, dynamic> json) {
    return PatientMonitoringHistory(
      patient: PatientBasicInfo.fromJson(
        json['patient'] as Map<String, dynamic>,
      ),
      records:
          (json['records'] as List<dynamic>)
              .map((e) => MedicalRecord.fromJson(e as Map<String, dynamic>))
              .toList(),
      total: json['total'] ?? 0,
      limit: json['limit'] ?? 10,
      offset: json['offset'] ?? 0,
    );
  }
}

/// Model untuk basic patient info
class PatientBasicInfo {
  final int id;
  final String name;
  final String email;

  const PatientBasicInfo({
    required this.id,
    required this.name,
    required this.email,
  });

  factory PatientBasicInfo.fromJson(Map<String, dynamic> json) {
    return PatientBasicInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}
