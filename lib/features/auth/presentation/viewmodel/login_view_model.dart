import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final loginViewModelProvider = ChangeNotifierProvider<LoginViewModel>((ref) {
  return LoginViewModel();
});

class LoginViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? error;

  Future<String?> login(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('https://dopply.my.id/api/v1/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Assume API returns a field 'role' in response
        final role = data['role'];
        isLoading = false;
        notifyListeners();
        return role;
      } else {
        error = 'Invalid credentials';
      }
    } catch (e) {
      error = 'Login failed: $e';
    }
    isLoading = false;
    notifyListeners();
    return null;
  }
}
