import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/monitoring_view_model.dart';
import '../viewmodels/monitoring_notifier.dart';
import 'package:dopply_app/features/doctor/presentation/utils/add_patient_dialog.dart';
import 'package:dopply_app/features/doctor/data/services/patient_api_service.dart';
import 'package:dopply_app/features/auth/presentation/viewmodels/user_provider.dart';
import '../models/monitoring_patient.dart';

class PatientPickerDialog extends ConsumerWidget {
  const PatientPickerDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(patientsByDoctorProvider);
    final state = ref.watch(monitoringNotifierProvider);
    final notifier = ref.read(monitoringNotifierProvider.notifier);
    // Pastikan filteredPatients selalu up-to-date jika searchQuery kosong
    final filteredPatients =
        state.searchQuery.isEmpty
            ? (patientsAsync.value ?? [])
            : state.filteredPatients;
    return AlertDialog(
      title: const Text('Pilih Pasien'),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Cari pasien',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (q) {
                final patients = patientsAsync.value ?? [];
                ref
                    .read(monitoringNotifierProvider.notifier)
                    .filterPatientsModel(patients, q);
              },
            ),
            const SizedBox(height: 12),
            patientsAsync.when(
              data: (patients) {
                final filtered = filteredPatients;
                if (filtered.isEmpty) {
                  return const Text('Tidak ada pasien ditemukan.');
                }
                return SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final p = filtered[idx];
                      return ListTile(
                        title: Text(p['name'] ?? '-'),
                        subtitle: Text('ID: ${p['patient_id'] ?? '-'}'),
                        onTap: () {
                          notifier.selectPatientModel(
                            MonitoringPatient.fromMap(p),
                          );
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Gagal memuat pasien: $e'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Tambah Pasien'),
              onPressed: () async {
                final menu = await showModalBottomSheet<String>(
                  context: context,
                  builder:
                      (context) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.person_add_alt_1),
                              title: const Text('Tambah Pasien Baru'),
                              onTap: () => Navigator.pop(context, 'baru'),
                            ),
                            ListTile(
                              leading: const Icon(Icons.person_search),
                              title: const Text(
                                'Tambah Pasien yang Sudah Terdaftar',
                              ),
                              onTap: () => Navigator.pop(context, 'terdaftar'),
                            ),
                          ],
                        ),
                      ),
                );
                if (menu == 'baru') {
                  final result = await showAddNewPatientDialog(context, ref);
                  if (result == true) {
                    // ignore: unused_result
                    ref.refresh(patientsByDoctorProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pasien baru berhasil didaftarkan!'),
                      ),
                    );
                  }
                } else if (menu == 'terdaftar') {
                  final emailController = TextEditingController();
                  final noteController = TextEditingController();
                  final formKey = GlobalKey<FormState>();
                  String? backendError;
                  final result = await showDialog<bool>(
                    context: context,
                    builder:
                        (_) => StatefulBuilder(
                          builder:
                              (context, setState) => AlertDialog(
                                title: const Text(
                                  'Tambah Pasien ke Daftar Dokter',
                                ),
                                content: Form(
                                  key: formKey,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextFormField(
                                          controller: emailController,
                                          decoration: const InputDecoration(
                                            labelText: 'Email Pasien',
                                          ),
                                          validator:
                                              (v) =>
                                                  v == null || v.isEmpty
                                                      ? 'Wajib diisi'
                                                      : null,
                                        ),
                                        TextFormField(
                                          controller: noteController,
                                          decoration: const InputDecoration(
                                            labelText: 'Catatan (opsional)',
                                          ),
                                        ),
                                        if (backendError != null) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            backendError!,
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, false),
                                    child: const Text('Batal'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (!(formKey.currentState?.validate() ??
                                          false))
                                        return;
                                      final user = ref.read(userProvider);
                                      final doctorId =
                                          user?.doctorId ?? user?.id;
                                      if (doctorId == null) {
                                        setState(() {
                                          backendError =
                                              'Gagal: doctorId tidak ditemukan!';
                                        });
                                        return;
                                      }
                                      final api = PatientApiService();
                                      bool success = false;
                                      await api
                                          .assignPatientToDoctorByEmail(
                                            doctorId: int.parse(
                                              doctorId.toString(),
                                            ),
                                            email: emailController.text,
                                            note:
                                                noteController.text.isNotEmpty
                                                    ? noteController.text
                                                    : null,
                                            status: 'active',
                                            onError:
                                                (err) => backendError = err,
                                          )
                                          .then((v) => success = v);
                                      if (success) {
                                        Navigator.pop(context, true);
                                      } else {
                                        setState(() {
                                          if (backendError != null &&
                                              backendError!.isNotEmpty) {
                                            // error already set
                                          } else {
                                            backendError =
                                                'Gagal menambahkan pasien!';
                                          }
                                        });
                                      }
                                    },
                                    child: const Text('Tambah'),
                                  ),
                                ],
                              ),
                        ),
                  );
                  if (result == true) {
                    // ignore: unused_result
                    ref.refresh(patientsByDoctorProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Pasien berhasil ditambahkan ke daftar Anda!',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}
