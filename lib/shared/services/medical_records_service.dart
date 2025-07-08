import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service untuk klasifikasi data BPM dan sharing medical records
/// Menggunakan endpoint `/records/{id}/classify` dan `/records/{id}/share`
class MedicalRecordsService {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  static const String _baseUrl = 'https://dopply.com.my/api';

  MedicalRecordsService({Dio? dio, FlutterSecureStorage? storage})
    : _dio = dio ?? Dio(),
      _storage = storage ?? const FlutterSecureStorage();

  /// Klasifikasi data BPM untuk record tertentu
  ///
  /// [recordId] - ID record yang akan diklasifikasi
  /// [bpmData] - Data BPM yang akan diklasifikasi (opsional)
  /// Returns: Map dengan hasil klasifikasi atau null jika gagal
  Future<Map<String, dynamic>?> classifyBpmRecord(
    int recordId, {
    Map<String, dynamic>? bpmData,
  }) async {
    try {
      print(
        '[MEDICAL_RECORDS] Memulai klasifikasi BPM untuk record: $recordId',
      );

      // Ambil token dari storage
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        print('[MEDICAL_RECORDS] Token tidak ditemukan');
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      // Siapkan request body jika ada BPM data
      Map<String, dynamic>? requestBody;
      if (bpmData != null) {
        requestBody = {
          'bpm_data': bpmData,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }

      // Konfigurasi header dengan token
      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final endpoint = '$_baseUrl/records/$recordId/classify';
      print('[MEDICAL_RECORDS] Requesting: $endpoint');

      final response = await _dio.post(
        endpoint,
        data: requestBody,
        options: options,
      );

      print('[MEDICAL_RECORDS] Response status: ${response.statusCode}');
      print('[MEDICAL_RECORDS] Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        return {
          'success': false,
          'message': 'Klasifikasi gagal dengan status ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      print('[MEDICAL_RECORDS] Dio error: ${e.message}');

      if (e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic> && errorData['message'] != null) {
          return {'success': false, 'message': errorData['message']};
        }
      }

      return {
        'success': false,
        'message': 'Klasifikasi gagal: ${e.message ?? 'Kesalahan jaringan'}',
      };
    } catch (e) {
      print('[MEDICAL_RECORDS] Unexpected error: $e');
      return {
        'success': false,
        'message': 'Klasifikasi gagal: ${e.toString()}',
      };
    }
  }

  /// Share medical record dengan user lain
  ///
  /// [recordId] - ID record yang akan dishare
  /// [shareWith] - Email atau ID user yang akan menerima share
  /// [message] - Pesan opsional untuk sharing
  /// [permissions] - Permission level: 'view', 'edit', 'full'
  /// Returns: Map dengan response dari server atau null jika gagal
  Future<Map<String, dynamic>?> shareRecord(
    int recordId, {
    required String shareWith,
    String? message,
    String permissions = 'view',
  }) async {
    try {
      print('[MEDICAL_RECORDS] Memulai sharing record: $recordId');

      // Ambil token dari storage
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        print('[MEDICAL_RECORDS] Token tidak ditemukan');
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      // Siapkan request body
      final requestBody = {
        'share_with': shareWith,
        'permissions': permissions,
        if (message != null) 'message': message,
        'shared_at': DateTime.now().toIso8601String(),
      };

      // Konfigurasi header dengan token
      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final endpoint = '$_baseUrl/records/$recordId/share';
      print('[MEDICAL_RECORDS] Requesting: $endpoint');

      final response = await _dio.post(
        endpoint,
        data: requestBody,
        options: options,
      );

      print('[MEDICAL_RECORDS] Response status: ${response.statusCode}');
      print('[MEDICAL_RECORDS] Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        return {
          'success': false,
          'message': 'Sharing gagal dengan status ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      print('[MEDICAL_RECORDS] Dio error: ${e.message}');

      if (e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic> && errorData['message'] != null) {
          return {'success': false, 'message': errorData['message']};
        }
      }

      return {
        'success': false,
        'message': 'Sharing gagal: ${e.message ?? 'Kesalahan jaringan'}',
      };
    } catch (e) {
      print('[MEDICAL_RECORDS] Unexpected error: $e');
      return {'success': false, 'message': 'Sharing gagal: ${e.toString()}'};
    }
  }

  /// Ambil daftar shared records untuk user saat ini
  /// Returns: List shared records atau null jika gagal
  Future<List<Map<String, dynamic>>?> getSharedRecords() async {
    try {
      print('[MEDICAL_RECORDS] Mengambil shared records...');

      // Ambil token dari storage
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        print('[MEDICAL_RECORDS] Token tidak ditemukan');
        return null;
      }

      // Konfigurasi header dengan token
      final options = Options(headers: {'Authorization': 'Bearer $token'});

      final endpoint = '$_baseUrl/records/shared';
      print('[MEDICAL_RECORDS] Requesting: $endpoint');

      final response = await _dio.get(endpoint, options: options);

      print('[MEDICAL_RECORDS] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        } else if (data is Map<String, dynamic> && data['records'] is List) {
          return (data['records'] as List).cast<Map<String, dynamic>>();
        }
      }

      return null;
    } on DioException catch (e) {
      print('[MEDICAL_RECORDS] Dio error: ${e.message}');
      return null;
    } catch (e) {
      print('[MEDICAL_RECORDS] Unexpected error: $e');
      return null;
    }
  }

  /// Revoke sharing untuk record tertentu
  ///
  /// [recordId] - ID record
  /// [revokeFrom] - User yang akan direvoke aksesnya
  /// Returns: Map dengan response dari server atau null jika gagal
  Future<Map<String, dynamic>?> revokeSharing(
    int recordId,
    String revokeFrom,
  ) async {
    try {
      print('[MEDICAL_RECORDS] Revoking sharing untuk record: $recordId');

      // Ambil token dari storage
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        print('[MEDICAL_RECORDS] Token tidak ditemukan');
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      // Siapkan request body
      final requestBody = {'revoke_from': revokeFrom};

      // Konfigurasi header dengan token
      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final endpoint = '$_baseUrl/records/$recordId/share';
      print('[MEDICAL_RECORDS] Requesting DELETE: $endpoint');

      final response = await _dio.delete(
        endpoint,
        data: requestBody,
        options: options,
      );

      print('[MEDICAL_RECORDS] Response status: ${response.statusCode}');
      print('[MEDICAL_RECORDS] Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        return {
          'success': false,
          'message':
              'Revoke sharing gagal dengan status ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      print('[MEDICAL_RECORDS] Dio error: ${e.message}');

      if (e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic> && errorData['message'] != null) {
          return {'success': false, 'message': errorData['message']};
        }
      }

      return {
        'success': false,
        'message': 'Revoke sharing gagal: ${e.message ?? 'Kesalahan jaringan'}',
      };
    } catch (e) {
      print('[MEDICAL_RECORDS] Unexpected error: $e');
      return {
        'success': false,
        'message': 'Revoke sharing gagal: ${e.toString()}',
      };
    }
  }
}
