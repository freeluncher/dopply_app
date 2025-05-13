import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dopply_app/features/auth/data/datasources/auth_local_datasource.dart';

class RecordApiService {
  final String _baseUrl = 'https://dopply.my.id/api/v1';

  Future<List<Map<String, dynamic>>> fetchRecords() async {
    final token = await AuthLocalDataSource().getToken();
    print('[RecordApiService] Token: $token');
    if (token == null) return [];
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/records'),
        headers: {'Authorization': 'Bearer $token'},
      );
      print('[RecordApiService] Status: ${response.statusCode}');
      print('[RecordApiService] Body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[RecordApiService] Decoded data: ${data.runtimeType}');
        if (data is List) {
          print('[RecordApiService] Records count: ${data.length}');
          return List<Map<String, dynamic>>.from(data);
        } else {
          print('[RecordApiService] Data is not a List');
        }
      } else {
        print('[RecordApiService] Error: Status code not 200');
      }
    } catch (e) {
      print('[RecordApiService] Exception: $e');
    }
    return [];
  }
}
