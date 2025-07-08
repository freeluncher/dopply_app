// User Management API Service
// Endpoints: /records, /account/email, /account/password, /users, dll

import 'dart:convert';
import './api_client.dart';

/// Service untuk User Management endpoints
class UserApiService {
  final ApiClient _apiClient = ApiClient();

  /// Get user records - GET /records
  Future<List<Map<String, dynamic>>> getUserRecords() async {
    final response = await _apiClient.get('/records');
    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Update account email - PUT /account/email
  Future<Map<String, dynamic>> updateAccountEmail({
    required String newEmail,
    required String password, // Usually required for email change
  }) async {
    final response = await _apiClient.put(
      '/account/email',
      body: {'new_email': newEmail, 'password': password}, // ✅ Fixed field name
    );

    return json.decode(response.body);
  }

  /// Update account password - PUT /account/password
  Future<Map<String, dynamic>> updateAccountPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _apiClient.put(
      '/account/password',
      body: {'current_password': currentPassword, 'new_password': newPassword},
    );

    return json.decode(response.body);
  }

  // ===== ADMIN ONLY ENDPOINTS =====

  /// Get all users (Admin only) - GET /users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final response = await _apiClient.get('/users');
    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Create user (Admin only) - POST /users
  Future<Map<String, dynamic>> createUser({
    required Map<String, dynamic> userData,
  }) async {
    final response = await _apiClient.post('/users', body: userData);
    return json.decode(response.body);
  }

  /// Update user (Admin only) - PUT /users/{user_id}
  Future<Map<String, dynamic>> updateUser({
    required int userId,
    required Map<String, dynamic> userData,
  }) async {
    final response = await _apiClient.put('/users/$userId', body: userData);
    return json.decode(response.body);
  }

  /// Delete user (Admin only) - DELETE /users/{user_id}
  Future<Map<String, dynamic>> deleteUser({required int userId}) async {
    final response = await _apiClient.delete('/users/$userId');
    return json.decode(response.body);
  }
}
