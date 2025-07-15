import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/models/patient.dart';

final patientServiceProvider = Provider<PatientService>((ref) {
  return PatientService();
});

class PatientService {
  // Get patients for doctor
  Future<List<Patient>> getPatients() async {
    // TODO: Implement API call to /monitoring/patients
    throw UnimplementedError('Patient service not implemented yet');
  }

  // Add patient by email
  Future<bool> addPatient(String email) async {
    // TODO: Implement API call to /monitoring/patients/add
    throw UnimplementedError('Add patient not implemented yet');
  }
}
