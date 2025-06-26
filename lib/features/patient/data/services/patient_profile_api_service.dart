import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dopply_app/features/auth/data/datasources/auth_local_datasource.dart';

class PatientProfileApiService {
  final String _baseUrl = 'https://dopply.my.id/api/v1';

  /// Ambil profile pasien (mengembalikan patients.id)
  Future<Map<String, dynamic>?> fetchPatientProfile() async {
    final token = await AuthLocalDataSource().getToken();
    if (token == null) return null;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/patient/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('[PatientProfileApiService] Exception: $e');
    }
    return null;
  }
}
