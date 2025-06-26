import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/features/doctor/data/models/doctor_patient.dart';
import 'package:dopply_app/features/doctor/data/services/monitoring_api_service.dart';
import 'package:dopply_app/features/doctor/data/services/patient_api_service.dart';
import 'package:dopply_app/features/auth/presentation/viewmodels/user_provider.dart';

class DoctorPatientsState {
  final List<DoctorPatient> patients;
  final bool isLoading;
  final String searchQuery;
  final String? error;

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

class DoctorPatientsNotifier extends StateNotifier<DoctorPatientsState> {
  final Ref ref;
  DoctorPatientsNotifier(this.ref)
    : super(DoctorPatientsState(patients: [], isLoading: true));

  Future<void> fetchPatients() async {
    state = state.copyWith(isLoading: true, error: null);
    final user = ref.read(userProvider);
    final doctorId = user?.doctorId ?? user?.id;
    if (doctorId == null) {
      state = state.copyWith(
        patients: [],
        isLoading: false,
        error: 'doctorId tidak ditemukan',
      );
      return;
    }
    final api = MonitoringApiService();
    try {
      final data = await api.getPatientsByDoctorIdWithStorage(
        doctorId: int.parse(doctorId.toString()),
      );
      final patients =
          data.map<DoctorPatient>((p) => DoctorPatient.fromMap(p)).toList();
      state = state.copyWith(patients: patients, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

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
      await fetchPatients();
    }
    return success;
  }

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
    final api = PatientApiService();
    final success = await api.assignPatientToDoctorByEmail(
      doctorId: int.parse(doctorId.toString()),
      email: email,
      note: note,
      status: 'active',
      onError: onError == null ? null : (err) => onError(err ?? ''),
    );
    if (success) {
      await fetchPatients();
    }
    return success;
  }
}

final doctorPatientsProvider =
    StateNotifierProvider<DoctorPatientsNotifier, DoctorPatientsState>((ref) {
      return DoctorPatientsNotifier(ref);
    });
