import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dopply_app/features/auth/data/datasources/auth_local_datasource.dart';

class MonitoringHistoryApiServicePatient {
  final String _baseUrl = 'https://dopply.my.id/api/v1';

  /// Ambil riwayat monitoring milik pasien yang sedang login
  /// Endpoint: GET /patient/monitoring/history
  Future<List<Map<String, dynamic>>> fetchMonitoringHistoryPatient() async {
    final token = await AuthLocalDataSource().getToken();
    if (token == null) return [];
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/patient/monitoring/history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print(
        '[MonitoringHistoryApiServicePatient] Status: \\${response.statusCode}',
      );
      print('[MonitoringHistoryApiServicePatient] Body: \\${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(
          '[MonitoringHistoryApiServicePatient] Decoded data: \\${data.runtimeType}',
        );
        print(
          '[MonitoringHistoryApiServicePatient] Decoded data value: \\${data}',
        );
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      print('[MonitoringHistoryApiServicePatient] Exception: $e');
    }
    return [];
  }
}
