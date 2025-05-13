import 'dart:convert';
import 'package:http/http.dart' as http;

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>?> login(String email, String password);
  Future<String?> register(
    String name,
    String email,
    String password,
    String role,
  );
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  @override
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final url = Uri.parse('https://dopply.my.id/api/v1/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  @override
  Future<String?> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    final url = Uri.parse('https://dopply.my.id/api/v1/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      }),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['role'] ?? 'success';
    }
    return null;
  }
}
