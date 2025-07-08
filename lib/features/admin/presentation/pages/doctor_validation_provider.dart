import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:dopply_app/shared/services/token_storage_service.dart';

final _secureStorage = FlutterSecureStorage();

Future<String?> getAdminToken() async {
  // Ganti key sesuai penyimpanan token Anda
  return await _secureStorage.read(key: 'token');
}

final doctorValidationCountProvider = FutureProvider<int>((ref) async {
  final tokenStorage = TokenStorageService();
  final token = await tokenStorage.getToken();
  if (token == null) return 0;
  final response = await http.get(
    Uri.parse(
      'https://dopply.my.id/api/v1/admin/doctor/validation-requests/count',
    ), // ✅ Fixed: Correct endpoint
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
