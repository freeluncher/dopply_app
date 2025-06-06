import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dopply_app/features/auth/data/datasources/auth_local_datasource.dart';

class MonitoringApiServicePatient {
  final String _baseUrl = 'https://dopply.my.id/api/v1';

  /// Simpan hasil monitoring pasien (self-monitoring)
  Future<bool> sendMonitoringResultPatient({
    required String patientId,
    required List<Map<String, dynamic>> bpmData,
    String? classification,
    String? monitoringResult,
  }) async {
    final token = await AuthLocalDataSource().getToken();
    if (token == null) return false;
    try {
      final data = {
        'patient_id': patientId,
        'bpm_data': bpmData,
        if (classification != null) 'classification': classification,
        if (monitoringResult != null) 'monitoring_result': monitoringResult,
      };
      final response = await http.post(
        Uri.parse('$_baseUrl/patient/monitoring'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('[MonitoringApiServicePatient] Exception: $e');
    }
    return false;
  }
}
