import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dopply_app/shared/services/token_storage_service.dart';

/// Universal Account API Service
///
/// Menangani account management untuk semua role (admin, doctor, patient)
/// menggunakan endpoint universal sesuai API documentation
class AccountApiService {
  final String _baseUrl = 'https://dopply.my.id/api/v1';

  /// Update email (universal untuk semua role)
  /// Endpoint: PUT /account/email
  /// Requires password verification
  Future<bool> changeEmail({
    required String newEmail,
    required String password,
  }) async {
    final token = await TokenStorageService().getToken();
    if (token == null) return false;

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/account/email'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'new_email': newEmail,
          'password': password, // Required for verification
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print(
          '[AccountApiService] changeEmail failed: ${response.statusCode} ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('[AccountApiService] changeEmail Exception: $e');
      return false;
    }
  }

  /// Update password (universal untuk semua role)
  /// Endpoint: PUT /account/password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await TokenStorageService().getToken();
    if (token == null) return false;

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/account/password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print(
          '[AccountApiService] changePassword failed: ${response.statusCode} ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('[AccountApiService] changePassword Exception: $e');
      return false;
    }
  }
}
