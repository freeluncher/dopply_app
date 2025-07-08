// Authentication API Service
// Endpoints: /login, /register, /refresh, /token/verify, /user/photo

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import './api_client.dart';

/// Service untuk Authentication endpoints
class AuthApiService {
  final ApiClient _apiClient = ApiClient();

  /// Login user - POST /login
  /// Returns: access_token, user data
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        '/login',
        body: {'email': email, 'password': password},
        requireAuth: false,
      );

      final result = json.decode(response.body);
      // API returns user data directly in response, add success flag for consistency
      result['success'] = true;
      return result;
    } catch (e) {
      // Handle API exceptions and return error format for login
      String errorMessage = e.toString();

      // Extract meaningful error message from API exceptions
      if (e is ApiException) {
        // Try to parse JSON error message from API
        try {
          final errorBody = errorMessage.split(': ').last;
          final errorJson = json.decode(errorBody);
          errorMessage =
              errorJson['message'] ?? errorJson['error'] ?? errorMessage;
        } catch (_) {
          // If parsing fails, use the exception message
          errorMessage = errorMessage.replaceAll('ApiException: ', '');
        }
      } else {
        errorMessage = errorMessage.replaceAll('Exception: ', '');
      }

      return {'success': false, 'message': errorMessage};
    }
  }

  /// Register user baru - POST /register
  /// Returns: user data or registration result
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role, // 'patient' atau 'doctor'
    String? birthDate,
    String? address,
    String? medicalNote,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      };

      // Add optional fields
      if (birthDate != null) body['birth_date'] = birthDate;
      if (address != null) body['address'] = address;
      if (medicalNote != null) body['medical_note'] = medicalNote;

      final response = await _apiClient.post(
        '/register',
        body: body,
        requireAuth: false,
      );

      final result = json.decode(response.body);
      // API returns user data directly in response, add success flag for consistency
      result['success'] = true;
      return result;
    } catch (e) {
      // Handle API exceptions and return error format for registration
      String errorMessage = e.toString();

      // Extract meaningful error message from API exceptions
      if (e is ApiException) {
        // Try to parse JSON error message from API
        try {
          final errorBody = errorMessage.split(': ').last;
          final errorJson = json.decode(errorBody);
          errorMessage =
              errorJson['message'] ?? errorJson['error'] ?? errorMessage;
        } catch (_) {
          // If parsing fails, use the exception message
          errorMessage = errorMessage.replaceAll('ApiException: ', '');
        }
      } else {
        errorMessage = errorMessage.replaceAll('Exception: ', '');
      }

      return {'success': false, 'message': errorMessage};
    }
  }

  /// Refresh access token - POST /auth/refresh
  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) async {
    print('[AuthAPI] 🔄 Calling refresh token endpoint...');
    print('[AuthAPI] 🔑 Refresh token: ${refreshToken.substring(0, 20)}...');

    final response = await _apiClient.post(
      '/auth/refresh',
      body: {'refresh_token': refreshToken},
      requireAuth: false,
    );

    print('[AuthAPI] 📊 Refresh response status: ${response.statusCode}');
    print('[AuthAPI] 📦 Refresh response body: ${response.body}');

    if (response.statusCode != 200) {
      print('[AuthAPI] ❌ Refresh failed with status: ${response.statusCode}');
      throw Exception('Token refresh failed: ${response.statusCode}');
    }

    final result = json.decode(response.body);
    print('[AuthAPI] ✅ Refresh response parsed: $result');

    return result;
  }

  /// Verify token validity - GET /token/verify
  Future<bool> verifyToken() async {
    try {
      final response = await _apiClient.get('/token/verify');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Upload user photo - POST /user/photo
  Future<Map<String, dynamic>> uploadUserPhoto({
    required File imageFile,
  }) async {
    // Create multipart file
    final multipartFile = await http.MultipartFile.fromPath(
      'photo',
      imageFile.path,
    );

    final response = await _apiClient.multipart('/user/photo', [multipartFile]);

    final responseBody = await response.stream.bytesToString();
    return json.decode(responseBody);
  }
}
