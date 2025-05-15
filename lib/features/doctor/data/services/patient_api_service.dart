import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dopply_app/features/auth/data/datasources/auth_local_datasource.dart';

class PatientApiService {
  final String _baseUrl = 'https://dopply.my.id/v1';

  Future<List<Map<String, dynamic>>> getAllPatients() async {
    final token = await AuthLocalDataSource().getToken();
    if (token == null) return [];
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/patients'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {}
    return [];
  }

  Future<Map<String, dynamic>?> getPatientDetail(int patientId) async {
    final token = await AuthLocalDataSource().getToken();
    if (token == null) return null;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/patients/$patientId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {}
    return null;
  }

  Future<bool> addPatient(Map<String, dynamic> data) async {
    final token = await AuthLocalDataSource().getToken();
    if (token == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/patients'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {}
    return false;
  }

  Future<bool> addPatientByDoctor(Map<String, dynamic> data) async {
    final token = await AuthLocalDataSource().getToken();
    if (token == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/patients/by-doctor'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {}
    return false;
  }

  Future<bool> registerPatient(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/patients/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {}
    return false;
  }

  Future<bool> updatePatient(int patientId, Map<String, dynamic> data) async {
    final token = await AuthLocalDataSource().getToken();
    if (token == null) return false;
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/patients/$patientId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {}
    return false;
  }

  Future<bool> deletePatient(int patientId) async {
    final token = await AuthLocalDataSource().getToken();
    if (token == null) return false;
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/patients/$patientId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {}
    return false;
  }
}
