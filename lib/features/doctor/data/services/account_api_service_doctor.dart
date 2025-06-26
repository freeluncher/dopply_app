import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dopply_app/features/auth/data/datasources/auth_local_datasource.dart';

/// Service untuk API pengelolaan akun dokter (ganti email & password)
class AccountApiServiceDoctor {
  final String _baseUrl = 'https://dopply.my.id/api/v1';

  /// Ganti email dokter yang sedang login
  Future<bool> changeEmail({required String newEmail}) async {
    final token = await AuthLocalDataSource().getToken(); // Ambil token login
    if (token == null) return false; // Jika belum login, gagal
    try {
      final response = await http.patch(
        Uri.parse(
          '$_baseUrl/doctor/account/email',
        ), // Endpoint ganti email dokter
        headers: {
          'Authorization': 'Bearer $token', // Sertakan token
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': newEmail}), // Kirim email baru
      );
      return response.statusCode == 200; // Sukses jika status 200
    } catch (e) {
      print('[AccountApiServiceDoctor] changeEmail Exception: $e'); // Log error
    }
    return false;
  }

  /// Ganti password dokter yang sedang login
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final token = await AuthLocalDataSource().getToken(); // Ambil token login
    if (token == null) return false; // Jika belum login, gagal
    try {
      final response = await http.patch(
        Uri.parse(
          '$_baseUrl/doctor/account/password',
        ), // Endpoint ganti password dokter
        headers: {
          'Authorization': 'Bearer $token', // Sertakan token
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'old_password': oldPassword, // Password lama
          'new_password': newPassword, // Password baru
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
