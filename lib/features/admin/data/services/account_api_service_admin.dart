import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dopply_app/features/auth/data/datasources/auth_local_datasource.dart';

class AccountApiServiceAdmin {
  final String _baseUrl = 'https://dopply.my.id/api/v1';

  Future<bool> changeEmail({required String newEmail}) async {
    final token = await AuthLocalDataSource().getToken();
    if (token == null) return false;
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/admin/account/email'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': newEmail}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('[AccountApiServiceAdmin] changeEmail Exception: $e');
    }
    return false;
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final token = await AuthLocalDataSource().getToken();
    if (token == null) return false;
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/admin/account/password'),
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
      print('[AccountApiServiceAdmin] changePassword Exception: $e');
    }
    return false;
  }

  Future<List<Map<String, dynamic>>?> getUsers() async {
    final token = await AuthLocalDataSource().getToken();
    if (token == null) return null;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (e) {
      print('[AccountApiServiceAdmin] getUsers Exception: $e');
    }
    return null;
  }

  Future<bool> createUser(Map<String, dynamic> userData) async {
    final token = await AuthLocalDataSource().getToken();
    if (token == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/admin/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(userData),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('[AccountApiServiceAdmin] createUser Exception: $e');
    }
    return false;
  }

  Future<bool> updateUser(String userId, Map<String, dynamic> userData) async {
    final token = await AuthLocalDataSource().getToken();
    if (token == null) return false;
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/admin/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(userData),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('[AccountApiServiceAdmin] updateUser Exception: $e');
    }
    return false;
  }

  Future<bool> deleteUser(String userId) async {
    final token = await AuthLocalDataSource().getToken();
    if (token == null) return false;
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/admin/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('[AccountApiServiceAdmin] deleteUser Exception: $e');
    }
    return false;
  }
}
