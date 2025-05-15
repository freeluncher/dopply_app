import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dopply_app/features/auth/data/datasources/auth_local_datasource.dart';

class MonitoringApiService {
  final String _baseUrl = 'https://dopply.my.id/api/v1';

  Future<Map<String, dynamic>?> sendMonitoringResult({
    required String patientId,
    required List<int> bpmData,
    required String doctorNote,
    String? doctorId,
  }) async {
    try {
      final data = {
        'patient_id': patientId,
        'bpm_data': bpmData,
        'doctor_note': doctorNote,
      };
      if (doctorId != null) {
        data['doctor_id'] = doctorId;
      }
      final response = await http.post(
        Uri.parse('$_baseUrl/monitoring'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getPatientsByDoctorId(
    String token, {
    required int doctorId,
    String? search,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/doctors/$doctorId/patients',
      ).replace(queryParameters: search != null ? {'search': search} : null);
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      print('Error getPatientsByDoctorId: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getPatientsByDoctorIdWithStorage({
    required int doctorId,
    String? search,
  }) async {
    final token = await AuthLocalDataSource().getToken();
    if (token == null) {
      print('Token tidak ditemukan, user belum login.');
      return [];
    }
    return await getPatientsByDoctorId(
      token,
      doctorId: doctorId,
      search: search,
    );
  }
}
