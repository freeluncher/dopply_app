import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/features/doctor/data/services/patient_api_service.dart';
import 'package:dopply_app/features/auth/presentation/viewmodels/user_provider.dart';

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
  required void Function() onSuccess,
}) async {
  if (!(formKey.currentState?.validate() ?? false)) return;
  setLoading(true);
  setError(null);
  try {
    // Gunakan PatientApiService langsung, bukan monitoringViewModelProvider
    final user = ref.read(userProvider);
    final doctorId = int.parse((user?.doctorId ?? user?.id).toString());
    final api = PatientApiService();
    final addResult = await api.addPatient({
      'name': nameController.text,
      'email': emailController.text,
      if (birthDateController.text.isNotEmpty)
        'birth_date': birthDateController.text,
      if (addressController.text.isNotEmpty) 'address': addressController.text,
      if (medicalNoteController.text.isNotEmpty)
        'medical_note': medicalNoteController.text,
    });
    if (!addResult) {
      setLoading(false);
      setError('Gagal menambah pasien baru.');
      return;
    }
    // Assign ke dokter
    final assignResult = await api.assignPatientToDoctorByEmail(
      doctorId: doctorId,
      email: emailController.text,
      onError: (err) => setError(err),
    );
    setLoading(false);
    if (assignResult) {
      onSuccess();
    } else {
      setError('Gagal assign pasien ke dokter.');
    }
  } catch (e) {
    setLoading(false);
    setError(e.toString());
  }
}
