// =============================================================================
// Authentication Service - Simplified with Dio HTTP Client
// =============================================================================

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/core/storage.dart';
import 'package:dopply_app/models/user.dart';

// Simple HTTP client for auth
class SimpleHttpClient {
  final Dio _dio;

  SimpleHttpClient() : _dio = Dio() {
    _dio.options.baseUrl = 'https://dopply.my.id/api/v1'; // Dopply API base URL
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } catch (e) {
      throw Exception('HTTP request failed: $e');
    }
  }
}

// Authentication service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Current user provider
final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, User?>((
  ref,
) {
  return CurrentUserNotifier();
});

class CurrentUserNotifier extends StateNotifier<User?> {
  CurrentUserNotifier() : super(null);

  void setUser(User user) {
    state = user;
  }

  void clearUser() {
    state = null;
  }

  bool get isLoggedIn => state != null;
  String? get userRole => state?.role;
}

class AuthService {
  final SimpleHttpClient _httpClient;

  AuthService() : _httpClient = SimpleHttpClient();

  // Login
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _httpClient.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response['success'] == true) {
        final userData = response['data'];
        final user = User.fromJson(userData['user']);
        final token = userData['token'];

        // Store auth data
        await StorageService.saveToken(token);
        await StorageService.saveUserData(jsonEncode(user.toJson()));
        await StorageService.saveUserRole(user.role);

        return AuthResult.success(user: user, token: token);
      } else {
        return AuthResult.error(message: response['message'] ?? 'Login gagal');
      }
    } catch (e) {
      return AuthResult.error(message: 'Terjadi kesalahan: ${e.toString()}');
    }
  }

  // Register
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _httpClient.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });

      if (response['success'] == true) {
        final userData = response['data'];
        final user = User.fromJson(userData['user']);
        final token = userData['token'];

        // Store auth data
        await StorageService.saveToken(token);
        await StorageService.saveUserData(jsonEncode(user.toJson()));
        await StorageService.saveUserRole(user.role);

        return AuthResult.success(user: user, token: token);
      } else {
        return AuthResult.error(
          message: response['message'] ?? 'Registrasi gagal',
        );
      }
    } catch (e) {
      return AuthResult.error(message: 'Terjadi kesalahan: ${e.toString()}');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _httpClient.post('/auth/logout', {});
    } catch (e) {
      // Even if API call fails, we still clear local storage
      print('Logout API call failed: $e');
    } finally {
      await StorageService.clearAll();
    }
  }

  // Get current user from storage
  Future<User?> getCurrentUser() async {
    try {
      final userData = await StorageService.getUserData();
      if (userData != null) {
        final userJson = jsonDecode(userData);
        return User.fromJson(userJson);
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await StorageService.isLoggedIn();
  }

  // Get user role
  Future<String?> getUserRole() async {
    return await StorageService.getUserRole();
  }

  // Refresh token
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _httpClient.post('/auth/refresh', {
        'refresh_token': refreshToken,
      });

      if (response['success'] == true) {
        final newToken = response['data']['token'];
        await StorageService.saveToken(newToken);
        return true;
      }
      return false;
    } catch (e) {
      print('Token refresh failed: $e');
      return false;
    }
  }
}

// Auth result wrapper
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? token;
  final String? errorMessage;

  const AuthResult._({
    required this.isSuccess,
    this.user,
    this.token,
    this.errorMessage,
  });

  factory AuthResult.success({required User user, required String token}) {
    return AuthResult._(isSuccess: true, user: user, token: token);
  }

  factory AuthResult.error({required String message}) {
    return AuthResult._(isSuccess: false, errorMessage: message);
  }
}
