import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/features/doctor/data/services/patient_api_service.dart';
import 'package:dopply_app/features/auth/presentation/viewmodels/user_provider.dart';
import 'package:dopply_app/features/doctor/data/models/doctor_patient.dart';

/// Submit form penambahan pasien baru dan assign ke dokter.
///
/// [context] - BuildContext untuk dialog/snackbar.
/// [ref] - WidgetRef untuk akses provider.
/// [formKey] - Key form validasi.
/// [nameController], [emailController], [birthDateController], [addressController], [medicalNoteController] - Controller input pasien.
/// [setLoading] - Callback untuk set loading state.
/// [setError] - Callback untuk set pesan error.
/// [onSuccess] - Callback jika sukses.
///
/// Menggunakan model [DoctorPatient] untuk representasi data pasien.
Future<void> submitAddNewPatient({
  required BuildContext context,
  required WidgetRef ref,
  required GlobalKey<FormState> formKey,
  required TextEditingController nameController,
  required TextEditingController emailController,
  required TextEditingController birthDateController,
  required TextEditingController addressController,
  required TextEditingController medicalNoteController,
  required void Function(bool) setLoading,
  required void Function(String?) setError,
  required void Function(DoctorPatient) onSuccess,
}) async {
  if (!(formKey.currentState?.validate() ?? false)) return;
  setLoading(true);
  setError(null);
  try {
    final user = ref.read(userProvider);
    final doctorId = int.parse((user?.doctorId ?? user?.id).toString());
    final api = PatientApiService();
    // Buat model pasien dari input
    final newPatient = DoctorPatient(
      patientId: 0, // id akan diisi backend
      name: nameController.text,
      email: emailController.text,
      birthDate:
          birthDateController.text.isNotEmpty ? birthDateController.text : null,
      address:
          addressController.text.isNotEmpty ? addressController.text : null,
      medicalNote:
          medicalNoteController.text.isNotEmpty
              ? medicalNoteController.text
              : null,
    );
    // Kirim ke backend
    final addResult = await api.addPatient(newPatient.toMap());
    if (!addResult) {
      setLoading(false);
      setError('Gagal menambah pasien baru.');
      return;
    }
    // Assign ke dokter
    final assignResult = await api.assignPatientToDoctorByEmail(
      doctorId: doctorId,
      email: newPatient.email,
      onError: (err) => setError(err),
    );
    setLoading(false);
    if (assignResult) {
      onSuccess(newPatient);
    } else {
      setError('Gagal assign pasien ke dokter.');
    }
  } catch (e) {
    setLoading(false);
    setError(e.toString());
  }
}
