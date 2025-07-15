import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/models/patient.dart';
import 'package:dopply_app/core/api_client.dart';

final patientServiceProvider = Provider<PatientService>((ref) {
  return PatientService();
});

class PatientService {
  final ApiClient _apiClient = ApiClient();

  // Get patients for doctor
  Future<List<Patient>> getPatients() async {
    // TODO: Implement API call to https://dopply.my.id/api/v1/monitoring/patients
    throw UnimplementedError('Patient service not implemented yet');
  }

  // Add patient by email
  Future<bool> addPatient(String email) async {
    // TODO: Implement API call to https://dopply.my.id/api/v1/monitoring/patients/add
    throw UnimplementedError('Add patient not implemented yet');
  }
}
