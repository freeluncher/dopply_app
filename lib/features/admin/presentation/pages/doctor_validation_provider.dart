import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:dopply_app/features/auth/data/datasources/auth_local_datasource.dart';

final _secureStorage = FlutterSecureStorage();

Future<String?> getAdminToken() async {
  // Ganti key sesuai penyimpanan token Anda
  return await _secureStorage.read(key: 'token');
}

final doctorValidationCountProvider = FutureProvider<int>((ref) async {
  final localDataSource = AuthLocalDataSource();
  final token = await localDataSource.getToken();
  if (token == null) return 0;
  final response = await http.get(
    Uri.parse('https://dopply.my.id/v1/admin/doctor/validation-requests/count'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data is Map && data['pending_validation'] != null) {
      return data['pending_validation'] as int;
    }
  }
  return 0;
});
