import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/models/patient.dart';
import 'package:dopply_app/core/api_client.dart';
import 'package:dopply_app/core/storage.dart';
import 'dart:convert';

final patientServiceProvider = Provider<PatientService>((ref) {
  return PatientService();
});

class PatientService {
  final ApiClient _apiClient = ApiClient();

  // Get patients for doctor
  Future<List<Patient>> getPatients() async {
    print('[PatientService] Fetching patients...');
    try {
      final response = await _apiClient.dio.get('/monitoring/patients');
      print('[PatientService] Response: ${response.data}');
      if (response.statusCode == 200 && response.data is List) {
        final patients =
            (response.data as List)
                .map((json) => Patient.fromJson(json))
                .toList();
        print('[PatientService] Parsed patients: $patients');
        return patients;
      } else {
        print('[PatientService] Unexpected response: ${response.statusCode}');
        return [];
      }
    } catch (e, st) {
      print('[PatientService] Error fetching patients: $e');
      print(st);
      return [];
    }
  }

  // Add patient by email
  Future<(bool, String?)> addPatient(String email) async {
    print('[PatientService] Adding patient with email: $email');
    // Always set JWT token from storage before request
    final token = await StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      ApiClient().setAuthToken(token);
      print('[PatientService] JWT token set in ApiClient: $token');
      // Debug print JWT header & payload
      final parts = token.split('.');
      if (parts.length == 3) {
        try {
          final header = utf8.decode(
            base64Url.decode(base64Url.normalize(parts[0])),
          );
          final payload = utf8.decode(
            base64Url.decode(base64Url.normalize(parts[1])),
          );
          print('[PatientService] JWT header: $header');
          print('[PatientService] JWT payload: $payload');
          // Print expiry info
          final payloadMap = json.decode(payload);
          if (payloadMap is Map && payloadMap.containsKey('exp')) {
            final exp = payloadMap['exp'];
            final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
            print('[PatientService] JWT exp: $exp ($expDate)');
            print(
              '[PatientService] JWT is expired: ${DateTime.now().isAfter(expDate)}',
            );
          }
        } catch (e) {
          print('[PatientService] Failed to decode JWT: $e');
        }
      }
    } else {
      print('[PatientService] No JWT token found in storage');
    }
    print(
      '[PatientService] Dio headers before request: ${_apiClient.dio.options.headers}',
    );
    try {
      final response = await _apiClient.dio.post(
        '/monitoring/patients/add',
        data: {'email': email},
      );
      print(
        '[PatientService] Add response: ${response.statusCode} ${response.data}',
      );
      print(
        '[PatientService] Dio headers after request: ${_apiClient.dio.options.headers}',
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return (true, null);
      } else {
        String? errorMsg;
        if (response.data is Map && response.data['message'] != null) {
          errorMsg = response.data['message'].toString();
        } else {
          errorMsg = 'Gagal menambah pasien (status ${response.statusCode})';
        }
        return (false, errorMsg);
      }
    } catch (e, st) {
      print('[PatientService] Error adding patient: $e');
      print(st);
      return (false, e.toString());
    }
  }
}
