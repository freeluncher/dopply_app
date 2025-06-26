import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dopply_app/features/auth/data/datasources/auth_local_datasource.dart';

/// Service utama untuk operasi monitoring dokter (kirim hasil, ambil pasien, klasifikasi BPM)
class MonitoringApiService {
  final String _baseUrl = 'https://dopply.my.id/api/v1';

  /// Kirim hasil monitoring pasien ke backend
  Future<Map<String, dynamic>?> sendMonitoringResult({
    required String patientId,
    required List<int> bpmData,
    required String doctorNote,
    String? doctorId,
  }) async {
    try {
      final data = {
        'patient_id': patientId, // ID pasien (patients.id)
        'bpm_data': bpmData, // Data BPM hasil monitoring
        'doctor_note': doctorNote, // Catatan dokter
      };
      if (doctorId != null) {
        data['doctor_id'] = doctorId; // Opsional: ID dokter
      }
      final response = await http.post(
        Uri.parse('$_baseUrl/monitoring'), // Endpoint kirim hasil monitoring
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Return response jika sukses
      }
    } catch (e) {
      rethrow; // Lempar error ke atas
    }
    return null;
  }

  /// Ambil daftar pasien yang ditangani dokter tertentu
  Future<List<Map<String, dynamic>>> getPatientsByDoctorId(
    String token, {
    required int doctorId,
    String? search,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/doctors/$doctorId/patients', // Endpoint ambil pasien dokter
      ).replace(queryParameters: search != null ? {'search': search} : null);
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'}, // Sertakan token
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data); // Return list pasien
        }
      }
    } catch (e) {
      print('Error getPatientsByDoctorId: $e'); // Log error
    }
    return [];
  }

  /// Wrapper: ambil token dari storage, lalu ambil daftar pasien dokter
  Future<List<Map<String, dynamic>>> getPatientsByDoctorIdWithStorage({
    required int doctorId,
    String? search,
  }) async {
    final token = await AuthLocalDataSource().getToken(); // Ambil token login
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

  /// Kirim data BPM ke backend untuk diklasifikasikan (normal/abnormal)
  Future<Map<String, dynamic>?> classifyBpmData(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/classify_bpm'), // Endpoint klasifikasi BPM
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Return hasil klasifikasi
      }
    } catch (e) {
      print('Error classifyBpmData: $e'); // Log error
    }
    return null;
  }
}
