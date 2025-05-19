import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dopply_app/features/auth/data/datasources/auth_local_datasource.dart';

class PatientApiService {
  final String _baseUrl = 'https://dopply.my.id/api/v1';

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

  Future<Map<String, dynamic>?> registerPatient(
    Map<String, dynamic> data, {
    void Function(String?)? onError,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        try {
          final res = jsonDecode(response.body);
          if (onError != null)
            onError(res['message'] ?? 'Gagal mendaftarkan pasien');
        } catch (_) {
          if (onError != null)
            onError('Gagal mendaftarkan pasien: ${response.body}');
        }
      }
    } catch (e) {
      if (onError != null) onError('Gagal mendaftarkan pasien: $e');
    }
    return null;
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

  /// Menghapus relasi dokter-pasien (unassign), bukan menghapus akun pasien
  Future<bool> deletePatient(int patientUserId, {required int doctorId}) async {
    final token = await AuthLocalDataSource().getToken();
    if (token == null) {
      print('[deletePatient] Token not found');
      return false;
    }
    try {
      final url = '$_baseUrl/doctors/$doctorId/unassign-patient/$patientUserId';
      print('[deletePatient] DELETE $url');
      final response = await http.delete(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      print(
        '[deletePatient] Response: ${response.statusCode} ${response.body}',
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('[deletePatient] Exception: $e');
    }
    return false;
  }

  /// Ambil daftar pasien yang ditangani oleh dokter tertentu (beserta atribut relasi)
  Future<List<Map<String, dynamic>>> getPatientsByDoctorId(int doctorId) async {
    final token = await AuthLocalDataSource().getToken();
    if (token == null) return [];
    try {
      final url = '$_baseUrl/doctors/$doctorId/patients';
      print('[getPatientsByDoctorId] GET $url');
      final response = await http.get(
        Uri.parse(url),
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

  /// Assign pasien ke dokter (dengan atribut status/note opsional)
  Future<bool> assignPatientToDoctor(
    int doctorId,
    int patientUserId, { // gunakan patientUserId (FK ke users.id)
    String? status,
    String? note,
  }) async {
    final token = await AuthLocalDataSource().getToken();
    if (token == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/doctors/$doctorId/assign-patient/$patientUserId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          if (status != null) 'status': status,
          if (note != null) 'note': note,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {}
    return false;
  }

  /// Assign pasien ke dokter berdasarkan email (dengan atribut status/note opsional)
  Future<bool> assignPatientToDoctorByEmail({
    required int doctorId,
    required String email,
    String? status,
    String? note,
    void Function(String?)? onError,
  }) async {
    final token = await AuthLocalDataSource().getToken();
    if (token == null) return false;
    try {
      final url = '$_baseUrl/doctors/$doctorId/assign-patient-by-email';
      final body = jsonEncode({
        'email': email,
        if (status != null) 'status': status,
        if (note != null) 'note': note,
      });
      print('[assignPatientToDoctorByEmail] POST $url');
      print('[assignPatientToDoctorByEmail] Body: $body');
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );
      print(
        '[assignPatientToDoctorByEmail] Response: ${response.statusCode} ${response.body}',
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        try {
          final res = jsonDecode(response.body);
          if (onError != null)
            onError(res['detail'] ?? res['message'] ?? 'Gagal assign pasien');
        } catch (_) {
          if (onError != null) onError('Gagal assign pasien: ${response.body}');
        }
      }
    } catch (e) {
      print('[assignPatientToDoctorByEmail] Exception: $e');
      if (onError != null) onError('Gagal assign pasien: $e');
    }
    return false;
  }

  /// Update atribut relasi dokter-pasien (status/note)
  Future<bool> updateDoctorPatientRelation(
    int doctorId,
    int patientId, {
    String? status,
    String? note,
  }) async {
    final token = await AuthLocalDataSource().getToken();
    if (token == null) return false;
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/doctors/$doctorId/patients/$patientId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          if (status != null) 'status': status,
          if (note != null) 'note': note,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {}
    return false;
  }

  /// Unassign pasien dari dokter (hapus relasi)
  Future<bool> unassignPatientFromDoctor(
    int doctorId,
    int patientUserId,
  ) async {
    // gunakan patientUserId (FK ke users.id)
    final token = await AuthLocalDataSource().getToken();
    if (token == null) {
      print('[unassignPatientFromDoctor] Token not found');
      return false;
    }
    try {
      final url = '$_baseUrl/doctors/$doctorId/unassign-patient/$patientUserId';
      print('[unassignPatientFromDoctor] DELETE $url');
      final response = await http.delete(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      print(
        '[unassignPatientFromDoctor] Response: ${response.statusCode} ${response.body}',
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('[unassignPatientFromDoctor] Exception: $e');
    }
    return false;
  }
}
