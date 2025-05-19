import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/monitoring_view_model.dart';

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
    await ref
        .read(monitoringViewModelProvider)
        .addNewPatientAndAssignToDoctor(
          name: nameController.text,
          email: emailController.text,
          birthDate:
              birthDateController.text.isNotEmpty
                  ? birthDateController.text
                  : null,
          address:
              addressController.text.isNotEmpty ? addressController.text : null,
          medicalNote:
              medicalNoteController.text.isNotEmpty
                  ? medicalNoteController.text
                  : null,
          onError: (err) => setError(err),
        );
    setLoading(false);
    onSuccess();
  } catch (e) {
    setLoading(false);
    setError(e.toString());
  }
}
