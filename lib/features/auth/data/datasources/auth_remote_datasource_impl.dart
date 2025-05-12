import 'dart:convert';
import 'package:http/http.dart' as http;

abstract class AuthRemoteDataSource {
  Future<String?> login(String email, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  @override
  Future<String?> login(String email, String password) async {
    final url = Uri.parse('https://dopply.my.id/api/v1/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['role'];
    }
    return null;
  }
}
