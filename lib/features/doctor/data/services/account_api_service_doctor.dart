import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dopply_app/shared/services/token_storage_service.dart';

/// Service untuk API pengelolaan akun dokter (ganti email & password)
class AccountApiServiceDoctor {
  final String _baseUrl = 'https://dopply.my.id/api/v1';

  /// Ganti email dokter yang sedang login
  /// Requires password verification
  Future<bool> changeEmail({
    required String newEmail,
    required String password,
  }) async {
    final token = await TokenStorageService().getToken(); // Ambil token login
    if (token == null) return false; // Jika belum login, gagal
    try {
      final response = await http.put(
        Uri.parse(
          '$_baseUrl/account/email', // ✅ Fixed: Universal endpoint
        ),
        headers: {
          'Authorization': 'Bearer $token', // Sertakan token
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'new_email': newEmail, // ✅ Fixed field name
          'password': password, // ✅ Required for verification
        }),
      );
      return response.statusCode == 200; // Sukses jika status 200
    } catch (e) {
      print('[AccountApiServiceDoctor] changeEmail Exception: $e'); // Log error
    }
    return false;
  }

  /// Ganti password dokter yang sedang login
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await TokenStorageService().getToken(); // Ambil token login
    if (token == null) return false; // Jika belum login, gagal
    try {
      final response = await http.put(
        Uri.parse(
          '$_baseUrl/account/password', // ✅ Fixed: Universal endpoint
        ),
        headers: {
          'Authorization': 'Bearer $token', // Sertakan token
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'current_password': currentPassword, // ✅ Fixed field name
          'new_password': newPassword, // ✅ Fixed field name
        }),
      );
      return response.statusCode == 200; // Sukses jika status 200
    } catch (e) {
      print(
        '[AccountApiServiceDoctor] changePassword Exception: $e',
      ); // Log error
    }
    return false;
  }
}
