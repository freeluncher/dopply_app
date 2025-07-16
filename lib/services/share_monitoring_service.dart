import 'dart:convert';
import 'package:http/http.dart' as http;

class ShareMonitoringService {
  static Future<bool> shareMonitoring({
    required String jwt,
    required int recordId,
    required int doctorId,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('https://dopply.my.id/api/v1/monitoring/share'),
      headers: {
        'Authorization': 'Bearer $jwt',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'record_id': recordId,
        'doctor_id': doctorId,
        'notes': notes ?? '',
      }),
    );
    return response.statusCode == 200;
  }
}
