import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service untuk menangani upload foto user
/// Menggunakan endpoint `/user/photo` dari backend API
class PhotoUploadService {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  static const String _baseUrl = 'https://dopply.com.my/api';
  static const String _uploadEndpoint = '/user/photo';

  PhotoUploadService({Dio? dio, FlutterSecureStorage? storage})
    : _dio = dio ?? Dio(),
      _storage = storage ?? const FlutterSecureStorage();

  /// Upload foto user ke server
  ///
  /// [imageFile] - File gambar yang akan diupload
  /// Returns: Map dengan response dari server atau null jika gagal
  Future<Map<String, dynamic>?> uploadPhoto(File imageFile) async {
    try {
      print('[PHOTO] Memulai upload foto...');

      // Ambil token dari storage
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        print('[PHOTO] Token tidak ditemukan');
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      // Siapkan form data dengan file
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'profile_photo.${imageFile.path.split('.').last}',
        ),
      });

      // Konfigurasi header dengan token
      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        },
      );

      print('[PHOTO] Uploading ke: $_baseUrl$_uploadEndpoint');

      final response = await _dio.post(
        '$_baseUrl$_uploadEndpoint',
        data: formData,
        options: options,
      );

      print('[PHOTO] Response status: ${response.statusCode}');
      print('[PHOTO] Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        return {
          'success': false,
          'message': 'Upload gagal dengan status ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      print('[PHOTO] Dio error: ${e.message}');

      if (e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic> && errorData['message'] != null) {
          return {'success': false, 'message': errorData['message']};
        }
      }

      return {
        'success': false,
        'message': 'Upload gagal: ${e.message ?? 'Kesalahan jaringan'}',
      };
    } catch (e) {
      print('[PHOTO] Unexpected error: $e');
      return {'success': false, 'message': 'Upload gagal: ${e.toString()}'};
    }
  }

  /// Hapus foto user
  /// Returns: Map dengan response dari server atau null jika gagal
  Future<Map<String, dynamic>?> deletePhoto() async {
    try {
      print('[PHOTO] Memulai hapus foto...');

      // Ambil token dari storage
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        print('[PHOTO] Token tidak ditemukan');
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      // Konfigurasi header dengan token
      final options = Options(headers: {'Authorization': 'Bearer $token'});

      print('[PHOTO] Deleting dari: $_baseUrl$_uploadEndpoint');

      final response = await _dio.delete(
        '$_baseUrl$_uploadEndpoint',
        options: options,
      );

      print('[PHOTO] Response status: ${response.statusCode}');
      print('[PHOTO] Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        return {
          'success': false,
          'message': 'Hapus foto gagal dengan status ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      print('[PHOTO] Dio error: ${e.message}');

      if (e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic> && errorData['message'] != null) {
          return {'success': false, 'message': errorData['message']};
        }
      }

      return {
        'success': false,
        'message': 'Hapus foto gagal: ${e.message ?? 'Kesalahan jaringan'}',
      };
    } catch (e) {
      print('[PHOTO] Unexpected error: $e');
      return {'success': false, 'message': 'Hapus foto gagal: ${e.toString()}'};
    }
  }
}
