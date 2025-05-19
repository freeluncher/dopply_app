import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'add_patient_logic.dart';

Future<bool?> showAddNewPatientDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final birthDateController = TextEditingController();
  final addressController = TextEditingController();
  final medicalNoteController = TextEditingController();
  String? backendError;
  bool isLoading = false;
  return await showDialog<bool>(
    context: context,
    builder:
        (_) => StatefulBuilder(
          builder: (context, setState) {
            void setLoading(bool v) => setState(() => isLoading = v);
            void setError(String? err) => setState(() => backendError = err);
            return AlertDialog(
              title: const Text('Tambah Pasien Baru'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nama*'),
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Nama wajib diisi'
                                    : null,
                      ),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email*'),
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Email wajib diisi'
                                    : null,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      TextFormField(
                        controller: birthDateController,
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Lahir (YYYY-MM-DD)',
                        ),
                      ),
                      TextFormField(
                        controller: addressController,
                        decoration: const InputDecoration(labelText: 'Alamat'),
                      ),
                      TextFormField(
                        controller: medicalNoteController,
                        decoration: const InputDecoration(
                          labelText: 'Catatan Medis',
                        ),
                      ),
                      if (backendError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          backendError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isLoading ? null : () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : () async {
                            await submitAddNewPatient(
                              context: context,
                              ref: ref,
                              formKey: formKey,
                              nameController: nameController,
                              emailController: emailController,
                              birthDateController: birthDateController,
                              addressController: addressController,
                              medicalNoteController: medicalNoteController,
                              setLoading: setLoading,
                              setError: setError,
                              onSuccess: () {
                                Navigator.pop(context, true);
                              },
                            );
                          },
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Tambah'),
                ),
              ],
            );
          },
        ),
  );
}
