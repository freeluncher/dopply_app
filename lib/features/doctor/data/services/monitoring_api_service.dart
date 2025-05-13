import 'package:dio/dio.dart';

class MonitoringApiService {
  final Dio _dio = Dio();

  Future<Map<String, dynamic>?> sendMonitoringResult({
    required String patientId,
    required List<int> bpmData,
    required String doctorNote,
  }) async {
    try {
      final response = await _dio.post(
        'https://dopply.my.id/v1/monitoring',
        data: {
          'patient_id': patientId,
          'bpm_data': bpmData,
          'doctor_note': doctorNote,
        },
      );
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Handle error/logging
      rethrow;
    }
    return null;
  }
}
