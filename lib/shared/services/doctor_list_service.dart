import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Model untuk doctor data
class Doctor {
  final int id;
  final String name;
  final String email;
  final String? specialization;
  final String? photoUrl;
  final bool isValid;
  final String? experience;
  final String? workLocation;
  final double? rating;
  final int? patientCount;

  const Doctor({
    required this.id,
    required this.name,
    required this.email,
    this.specialization,
    this.photoUrl,
    required this.isValid,
    this.experience,
    this.workLocation,
    this.rating,
    this.patientCount,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      specialization: json['specialization'] as String?,
      photoUrl: json['photo_url'] as String?,
      isValid: json['is_valid'] as bool? ?? true,
      experience: json['experience'] as String?,
      workLocation: json['work_location'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      patientCount: json['patient_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'specialization': specialization,
      'photo_url': photoUrl,
      'is_valid': isValid,
      'experience': experience,
      'work_location': workLocation,
      'rating': rating,
      'patient_count': patientCount,
    };
  }
}

/// Service untuk mengelola daftar dokter
/// Menggunakan endpoint `/doctors` dari backend API
class DoctorListService {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  static const String _baseUrl = 'https://dopply.com.my/api';
  static const String _doctorsEndpoint = '/doctors';

  DoctorListService({Dio? dio, FlutterSecureStorage? storage})
    : _dio = dio ?? Dio(),
      _storage = storage ?? const FlutterSecureStorage();

  /// Ambil daftar semua dokter
  ///
  /// [page] - Nomor halaman untuk pagination (default: 1)
  /// [limit] - Jumlah data per halaman (default: 20)
  /// [search] - Query pencarian nama atau spesialisasi
  /// [specialization] - Filter berdasarkan spesialisasi
  /// [isValid] - Filter berdasarkan status validasi
  /// Returns: Map dengan list dokter dan metadata pagination
  Future<Map<String, dynamic>?> getDoctors({
    int page = 1,
    int limit = 20,
    String? search,
    String? specialization,
    bool? isValid,
  }) async {
    try {
      print('[DOCTOR_LIST] Mengambil daftar dokter...');

      // Ambil token dari storage
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        print('[DOCTOR_LIST] Token tidak ditemukan');
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      // Siapkan query parameters
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (specialization != null && specialization.isNotEmpty) {
        queryParams['specialization'] = specialization;
      }

      if (isValid != null) {
        queryParams['is_valid'] = isValid;
      }

      // Konfigurasi header dengan token
      final options = Options(headers: {'Authorization': 'Bearer $token'});

      print('[DOCTOR_LIST] Requesting: $_baseUrl$_doctorsEndpoint');
      print('[DOCTOR_LIST] Query params: $queryParams');

      final response = await _dio.get(
        '$_baseUrl$_doctorsEndpoint',
        queryParameters: queryParams,
        options: options,
      );

      print('[DOCTOR_LIST] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        // Parse doctors list
        List<Doctor> doctors = [];
        if (data['doctors'] is List) {
          doctors =
              (data['doctors'] as List)
                  .map((json) => Doctor.fromJson(json as Map<String, dynamic>))
                  .toList();
        }

        return {
          'success': true,
          'doctors': doctors,
          'pagination': {
            'current_page': data['current_page'] ?? page,
            'total_pages': data['total_pages'] ?? 1,
            'total_count': data['total_count'] ?? doctors.length,
            'per_page': data['per_page'] ?? limit,
          },
        };
      } else {
        return {
          'success': false,
          'message':
              'Gagal mengambil daftar dokter dengan status ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      print('[DOCTOR_LIST] Dio error: ${e.message}');

      if (e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic> && errorData['message'] != null) {
          return {'success': false, 'message': errorData['message']};
        }
      }

      return {
        'success': false,
        'message':
            'Gagal mengambil daftar dokter: ${e.message ?? 'Kesalahan jaringan'}',
      };
    } catch (e) {
      print('[DOCTOR_LIST] Unexpected error: $e');
      return {
        'success': false,
        'message': 'Gagal mengambil daftar dokter: ${e.toString()}',
      };
    }
  }

  /// Ambil detail dokter berdasarkan ID
  ///
  /// [doctorId] - ID dokter yang akan diambil detailnya
  /// Returns: Map dengan data dokter atau null jika gagal
  Future<Map<String, dynamic>?> getDoctorById(int doctorId) async {
    try {
      print('[DOCTOR_LIST] Mengambil detail dokter: $doctorId');

      // Ambil token dari storage
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        print('[DOCTOR_LIST] Token tidak ditemukan');
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      // Konfigurasi header dengan token
      final options = Options(headers: {'Authorization': 'Bearer $token'});

      final endpoint = '$_baseUrl$_doctorsEndpoint/$doctorId';
      print('[DOCTOR_LIST] Requesting: $endpoint');

      final response = await _dio.get(endpoint, options: options);

      print('[DOCTOR_LIST] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        // Parse doctor data
        final doctor = Doctor.fromJson(data);

        return {'success': true, 'doctor': doctor};
      } else {
        return {
          'success': false,
          'message':
              'Gagal mengambil detail dokter dengan status ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      print('[DOCTOR_LIST] Dio error: ${e.message}');

      if (e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic> && errorData['message'] != null) {
          return {'success': false, 'message': errorData['message']};
        }
      }

      return {
        'success': false,
        'message':
            'Gagal mengambil detail dokter: ${e.message ?? 'Kesalahan jaringan'}',
      };
    } catch (e) {
      print('[DOCTOR_LIST] Unexpected error: $e');
      return {
        'success': false,
        'message': 'Gagal mengambil detail dokter: ${e.toString()}',
      };
    }
  }

  /// Assign pasien ke dokter (untuk admin atau pasien)
  ///
  /// [patientId] - ID pasien yang akan di-assign
  /// [doctorId] - ID dokter yang akan menjadi doctor pasien
  /// Returns: Map dengan response dari server atau null jika gagal
  Future<Map<String, dynamic>?> assignPatientToDoctor(
    int patientId,
    int doctorId,
  ) async {
    try {
      print('[DOCTOR_LIST] Assign pasien $patientId ke dokter $doctorId');

      // Ambil token dari storage
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        print('[DOCTOR_LIST] Token tidak ditemukan');
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      // Siapkan request body
      final requestBody = {
        'doctor_id': doctorId,
        'assigned_at': DateTime.now().toIso8601String(),
      };

      // Konfigurasi header dengan token
      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final endpoint = '$_baseUrl/users/$patientId/assign-doctor';
      print('[DOCTOR_LIST] Requesting: $endpoint');

      final response = await _dio.post(
        endpoint,
        data: requestBody,
        options: options,
      );

      print('[DOCTOR_LIST] Response status: ${response.statusCode}');
      print('[DOCTOR_LIST] Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        return {
          'success': false,
          'message': 'Assign dokter gagal dengan status ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      print('[DOCTOR_LIST] Dio error: ${e.message}');

      if (e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic> && errorData['message'] != null) {
          return {'success': false, 'message': errorData['message']};
        }
      }

      return {
        'success': false,
        'message': 'Assign dokter gagal: ${e.message ?? 'Kesalahan jaringan'}',
      };
    } catch (e) {
      print('[DOCTOR_LIST] Unexpected error: $e');
      return {
        'success': false,
        'message': 'Assign dokter gagal: ${e.toString()}',
      };
    }
  }

  /// Unassign pasien dari dokter
  ///
  /// [patientId] - ID pasien yang akan di-unassign
  /// Returns: Map dengan response dari server atau null jika gagal
  Future<Map<String, dynamic>?> unassignPatientFromDoctor(int patientId) async {
    try {
      print('[DOCTOR_LIST] Unassign pasien $patientId dari dokter');

      // Ambil token dari storage
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        print('[DOCTOR_LIST] Token tidak ditemukan');
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      // Konfigurasi header dengan token
      final options = Options(headers: {'Authorization': 'Bearer $token'});

      final endpoint = '$_baseUrl/users/$patientId/assign-doctor';
      print('[DOCTOR_LIST] Requesting DELETE: $endpoint');

      final response = await _dio.delete(endpoint, options: options);

      print('[DOCTOR_LIST] Response status: ${response.statusCode}');
      print('[DOCTOR_LIST] Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        return {
          'success': false,
          'message':
              'Unassign dokter gagal dengan status ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      print('[DOCTOR_LIST] Dio error: ${e.message}');

      if (e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic> && errorData['message'] != null) {
          return {'success': false, 'message': errorData['message']};
        }
      }

      return {
        'success': false,
        'message':
            'Unassign dokter gagal: ${e.message ?? 'Kesalahan jaringan'}',
      };
    } catch (e) {
      print('[DOCTOR_LIST] Unexpected error: $e');
      return {
        'success': false,
        'message': 'Unassign dokter gagal: ${e.toString()}',
      };
    }
  }
}
