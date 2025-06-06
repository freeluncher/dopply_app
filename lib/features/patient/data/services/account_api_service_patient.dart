import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dopply_app/features/auth/data/datasources/auth_local_datasource.dart';

class AccountApiServicePatient {
  final String _baseUrl = 'https://dopply.my.id/api/v1';

  /// Ganti email pasien
  Future<bool> changeEmail({required String newEmail}) async {
    final token = await AuthLocalDataSource().getToken();
    if (token == null) return false;
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/patient/account/email'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': newEmail}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('[AccountApiServicePatient] changeEmail Exception: $e');
    }
    return false;
  }

  /// Ganti password pasien
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final token = await AuthLocalDataSource().getToken();
    if (token == null) return false;
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/patient/account/password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('[AccountApiServicePatient] changePassword Exception: $e');
    }
    return false;
  }
}
