import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/features/doctor/data/models/doctor_patient.dart';
import 'package:dopply_app/features/doctor/data/services/patient_api_service.dart';
import 'package:dopply_app/features/auth/presentation/providers/user_provider.dart';
import '../../../../services/api/doctor_api_service.dart';

/// State untuk daftar pasien dokter, termasuk loading, error, dan pencarian
class DoctorPatientsState {
  final List<DoctorPatient> patients; // Daftar pasien
  final bool isLoading; // Status loading
  final String searchQuery; // Query pencarian
  final String? error; // Pesan error jika ada

  DoctorPatientsState({
    required this.patients,
    this.isLoading = false,
    this.searchQuery = '',
    this.error,
  });

  DoctorPatientsState copyWith({
    List<DoctorPatient>? patients,
    bool? isLoading,
    String? searchQuery,
    String? error,
  }) {
    return DoctorPatientsState(
      patients: patients ?? this.patients,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      error: error,
    );
  }
}

/// StateNotifier untuk mengelola daftar pasien dokter
class DoctorPatientsNotifier extends StateNotifier<DoctorPatientsState> {
  final Ref ref;
  DoctorPatientsNotifier(this.ref)
    : super(DoctorPatientsState(patients: [], isLoading: true));

  /// Ambil daftar pasien dari backend/storage
  Future<void> fetchPatients() async {
    state = state.copyWith(isLoading: true, error: null); // Set loading
    final user = ref.read(userProvider); // Ambil user login
    final doctorId = user?.doctorId ?? user?.id;
    if (doctorId == null) {
      state = state.copyWith(
        patients: [],
        isLoading: false,
        error: 'doctorId tidak ditemukan',
      );
      return;
    }

    try {
      print('[DOCTOR_PATIENTS_PAGE] Loading patients for doctor ID: $doctorId');
      final api = DoctorApiService();
      final response = await api.getPatientsForDoctor(
        doctorId: int.parse(doctorId.toString()),
        limit: 100, // Ensure we get all patients
      );

      print('[DOCTOR_PATIENTS_PAGE] API response: $response');

      // Extract patients array from the response
      final patientsData = List<Map<String, dynamic>>.from(
        response['patients'] ?? [],
      );

      print('[DOCTOR_PATIENTS_PAGE] Parsed ${patientsData.length} patients');

      // Debug: Log each patient data structure
      for (var i = 0; i < patientsData.length && i < 2; i++) {
        print('[DOCTOR_PATIENTS_PAGE] Patient $i raw data: ${patientsData[i]}');
      }

      // Convert to DoctorPatient model
      final patients =
          patientsData
              .map<DoctorPatient>((p) => DoctorPatient.fromMap(p))
              .toList();

      // Always fetch full patient details for every patient
      final enhancedPatients = <DoctorPatient>[];
      for (final patient in patients) {
        try {
          final patientDetails = await api.getPatientDetails(
            patientId: patient.patientId,
          );
          final enhancedPatient = DoctorPatient(
            patientId: patient.patientId,
            name: patientDetails['name'] ?? patient.name,
            email: patientDetails['email'] ?? patient.email,
            birthDate: patientDetails['birth_date'] ?? patient.birthDate,
            address: patientDetails['address'] ?? patient.address,
            medicalNote: patientDetails['medical_note'] ?? patient.medicalNote,
            age: patientDetails['age'] ?? patient.age,
            gender: patientDetails['gender'] ?? patient.gender,
            phone: patientDetails['phone'] ?? patient.phone,
            // Get status and notes from the latest API response (could be from either source)
            status: patientDetails['status'] ?? patient.status ?? 'active',
            notes:
                patientDetails['notes'] ??
                patientDetails['patient_notes'] ??
                patient.notes,
          );
          print(
            '[DOCTOR_PATIENTS_PAGE] Enhanced patient ${enhancedPatient.name}: status=${enhancedPatient.status}, notes=${enhancedPatient.notes}',
          );
          enhancedPatients.add(enhancedPatient);
        } catch (e) {
          print(
            '[DOCTOR_PATIENTS_PAGE] Failed to enhance patient ${patient.name}, using original data: $e',
          );
          enhancedPatients.add(patient);
        }
      }
      state = state.copyWith(
        patients: enhancedPatients,
        isLoading: false,
        error: null,
      ); // Update state
    } catch (e) {
      print('[DOCTOR_PATIENTS_PAGE] Error loading patients: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      ); // Error handling
    }
  }

  /// Update query pencarian
  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Hapus (unassign) pasien dari dokter
  Future<bool> deletePatient(DoctorPatient patient) async {
    final user = ref.read(userProvider);
    final doctorId = user?.doctorId ?? user?.id;
    if (doctorId == null) return false;
    final api = PatientApiService();
    final success = await api.unassignPatientFromDoctor(
      int.parse(doctorId.toString()),
      patient.patientId,
    );
    if (success) {
      await fetchPatients(); // Refresh daftar pasien
    }
    return success;
  }

  /// Tambah pasien ke dokter berdasarkan email
  Future<bool> addPatientByEmail({
    required String email,
    String? note,
    void Function(String)? onError,
  }) async {
    final user = ref.read(userProvider);
    final doctorId = user?.doctorId ?? user?.id;
    if (doctorId == null) {
      onError?.call('doctorId tidak ditemukan!');
      return false;
    }

    try {
      final api = DoctorApiService();
      await api.assignPatientByEmail(
        doctorId: int.parse(doctorId.toString()),
        patientEmail: email,
        note: note,
      );

      await fetchPatients(); // Refresh daftar pasien
      return true;
    } catch (e) {
      print('[DOCTOR_PATIENTS_PAGE] Error adding patient: $e');
      onError?.call(e.toString());
      return false;
    }
  }

  /// Force refresh patients data and invalidate cache
  /// Force refresh the patient list from server
  Future<void> forceRefresh() async {
    print('[DOCTOR_PATIENTS_PAGE] Force refreshing patients...');
    // Clear current state and force reload
    state = state.copyWith(isLoading: true, error: null);
    await fetchPatients();
  }

  /// Update single patient status in local state
  void updatePatientStatus(int patientId, String newStatus, String? newNotes) {
    print(
      '[DoctorPatientsNotifier] Updating patient $patientId status from local state',
    );
    print(
      '[DoctorPatientsNotifier] New status: $newStatus, New notes: $newNotes',
    );

    final updatedPatients =
        state.patients.map((patient) {
          if (patient.patientId == patientId) {
            print(
              '[DoctorPatientsNotifier] Found patient ${patient.name}, updating status',
            );
            return DoctorPatient(
              patientId: patient.patientId,
              name: patient.name,
              email: patient.email,
              birthDate: patient.birthDate,
              address: patient.address,
              medicalNote: patient.medicalNote,
              age: patient.age,
              gender: patient.gender,
              phone: patient.phone,
              status: newStatus,
              notes: newNotes,
            );
          }
          return patient;
        }).toList();

    print(
      '[DoctorPatientsNotifier] Setting new state with ${updatedPatients.length} patients',
    );
    state = state.copyWith(patients: updatedPatients);
    print('[DoctorPatientsNotifier] State updated successfully');
  }
}

/// Provider global untuk daftar pasien dokter
final doctorPatientsProvider =
    StateNotifierProvider<DoctorPatientsNotifier, DoctorPatientsState>((ref) {
      return DoctorPatientsNotifier(ref);
    });
