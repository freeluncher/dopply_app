import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dopply_app/shared/services/token_storage_service.dart';

class PatientApiService {
  final String _baseUrl = 'https://dopply.my.id/api/v1';

  Future<List<Map<String, dynamic>>> getAllPatients() async {
    final token = await TokenStorageService().getToken();
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
    final token = await TokenStorageService().getToken();
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
    final token = await TokenStorageService().getToken();
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

  Future<bool> updatePatient(int patientId, Map<String, dynamic> data) async {
    final token = await TokenStorageService().getToken();
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
    final token = await TokenStorageService().getToken();
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
    final token = await TokenStorageService().getToken();
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

        // Handle enhanced API format (with patients array)
        if (data is Map && data.containsKey('patients')) {
          final patients = data['patients'];
          if (patients is List) {
            return List<Map<String, dynamic>>.from(patients);
          }
        }

        // Handle legacy format (direct array)
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      print('[getPatientsByDoctorId] Exception: $e');
    }
    return [];
  }

  /// Assign pasien ke dokter (dengan atribut status/note opsional)
  Future<bool> assignPatientToDoctor(
    int doctorId,
    int patientUserId, { // gunakan patientUserId (FK ke users.id)
    String? status,
    String? note,
  }) async {
    final token = await TokenStorageService().getToken();
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
    final token = await TokenStorageService().getToken();
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
    final token = await TokenStorageService().getToken();
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
    final token = await TokenStorageService().getToken();
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

  /// Update patient status and notes (API endpoint #11)
  /// PATCH /doctors/{doctor_id}/patients/{patient_id}/status
  Future<Map<String, dynamic>?> updatePatientStatus({
    required int doctorId,
    required int patientId,
    required String status,
    String? notes,
  }) async {
    final token = await TokenStorageService().getToken();
    if (token == null) {
      print('[updatePatientStatus] Token not found');
      return null;
    }

    try {
      final url = '$_baseUrl/doctors/$doctorId/patients/$patientId/status';
      print('[updatePatientStatus] PATCH $url');

      final body = jsonEncode({
        'status': status,
        if (notes != null) 'notes': notes,
      });
      print('[updatePatientStatus] Body: $body');

      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print(
        '[updatePatientStatus] Response: ${response.statusCode} ${response.body}',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print(
          '[updatePatientStatus] Error: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('[updatePatientStatus] Exception: $e');
      return null;
    }
  }

  /// Validate status transition
  bool isValidStatusTransition(String currentStatus, String newStatus) {
    // Business rules for status transitions
    const validTransitions = {
      'active': ['inactive', 'discharged'],
      'inactive': ['active', 'discharged'],
      'discharged': [], // Cannot transition from discharged
    };

    return validTransitions[currentStatus]?.contains(newStatus) ?? false;
  }

  /// Get available status options
  List<String> getAvailableStatuses(String currentStatus) {
    const statusOptions = {
      'active': ['active', 'inactive', 'discharged'],
      'inactive': ['inactive', 'active', 'discharged'],
      'discharged': ['discharged'], // Read-only
    };

    return statusOptions[currentStatus] ?? ['active', 'inactive', 'discharged'];
  }
}
