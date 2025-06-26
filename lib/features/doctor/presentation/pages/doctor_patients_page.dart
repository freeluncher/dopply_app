import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/features/doctor/data/models/doctor_patient.dart';
import 'package:dopply_app/features/doctor/presentation/viewmodels/doctor_patients_notifier.dart';

/// Helper untuk menampilkan snackbar notifikasi/error di seluruh halaman
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : null,
    ),
  );
}

/// Halaman daftar pasien yang ditangani dokter (CRUD relasi dokter-pasien)
/// Menggunakan Riverpod StateNotifier untuk state dan aksi CRUD.
class DoctorPatientsPage extends ConsumerStatefulWidget {
  const DoctorPatientsPage({super.key});

  @override
  ConsumerState<DoctorPatientsPage> createState() => _DoctorPatientsPageState();
}

class _DoctorPatientsPageState extends ConsumerState<DoctorPatientsPage> {
  @override
  void initState() {
    super.initState();
    // Fetch data pasien saat halaman dibuka
    Future.microtask(
      () => ref.read(doctorPatientsProvider.notifier).fetchPatients(),
    );
  }

  /// Filter pasien berdasarkan input pencarian
  void _onSearch(String query) {
    ref.read(doctorPatientsProvider.notifier).search(query);
  }

  /// Hapus pasien dengan konfirmasi dialog
  void _onDelete(DoctorPatient patient) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => const DeletePatientDialog(),
    );
    if (confirm == true) {
      final success = await ref
          .read(doctorPatientsProvider.notifier)
          .deletePatient(patient);
      if (success) {
        showAppSnackBar(context, 'Pasien berhasil dihapus dari daftar Anda!');
      } else {
        showAppSnackBar(context, 'Gagal menghapus pasien!', isError: true);
      }
    }
  }

  /// Tambah pasien ke daftar dokter
  void _onAdd() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const AddPatientDialog(),
    );
    if (result == true) {
      showAppSnackBar(context, 'Pasien berhasil ditambahkan ke daftar Anda!');
    }
  }

  /// Tampilkan detail pasien dalam dialog
  void _onDetail(DoctorPatient patient) {
    showDialog(
      context: context,
      builder: (_) => PatientDetailDialog(patient: patient),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(doctorPatientsProvider);
    final filteredPatients =
        state.searchQuery.isEmpty
            ? state.patients
            : state.patients.where((p) {
              final name = p.name.toLowerCase();
              final email = p.email.toLowerCase();
              return name.contains(state.searchQuery.toLowerCase()) ||
                  email.contains(state.searchQuery.toLowerCase());
            }).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Pasien'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _onAdd, // Tambah pasien
            tooltip: 'Tambah Pasien',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input pencarian pasien
            TextField(
              decoration: const InputDecoration(
                labelText: 'Cari pasien',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onSearch, // Filter pasien
            ),
            const SizedBox(height: 16),
            // Daftar pasien dengan paginasi/lazy loading jika data banyak
            Expanded(
              child:
                  state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : PatientList(
                        patients: filteredPatients,
                        onDetail: _onDetail,
                        onDelete: _onDelete,
                      ),
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  state.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget daftar pasien dengan ListView.builder (mendukung lazy loading)
class PatientList extends StatelessWidget {
  final List<DoctorPatient> patients;
  final void Function(DoctorPatient) onDetail;
  final void Function(DoctorPatient) onDelete;
  const PatientList({
    super.key,
    required this.patients,
    required this.onDetail,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (patients.isEmpty) {
      return const Center(child: Text('Tidak ada pasien ditemukan'));
    }
    // ListView.builder otomatis lazy loading, cocok untuk data banyak
    return ListView.builder(
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final patient = patients[index];
        return Card(
          child: ListTile(
            title: Text(patient.name),
            subtitle: Text(patient.email),
            onTap: () => onDetail(patient),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => onDelete(patient),
            ),
          ),
        );
      },
    );
  }
}

/// Dialog konfirmasi hapus pasien
class DeletePatientDialog extends StatelessWidget {
  const DeletePatientDialog({super.key});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hapus Pasien'),
      content: const Text('Yakin ingin menghapus pasien ini?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Hapus'),
        ),
      ],
    );
  }
}

/// Dialog tambah pasien ke daftar dokter
/// Menggunakan ConsumerStatefulWidget agar bisa akses provider dan setState
class AddPatientDialog extends ConsumerStatefulWidget {
  const AddPatientDialog({super.key});
  @override
  ConsumerState<AddPatientDialog> createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends ConsumerState<AddPatientDialog> {
  final emailController = TextEditingController();
  final noteController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String? backendError;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Pasien ke Daftar Dokter'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email Pasien'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                ),
              ),
              if (backendError != null && backendError!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    backendError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed:
              isLoading
                  ? null
                  : () async {
                    if (formKey.currentState?.validate() ?? false) {
                      setState(() => isLoading = true);
                      backendError = null;
                      final notifier = ref.read(
                        doctorPatientsProvider.notifier,
                      );
                      final success = await notifier.addPatientByEmail(
                        email: emailController.text,
                        note:
                            noteController.text.isNotEmpty
                                ? noteController.text
                                : null,
                        onError: (err) => setState(() => backendError = err),
                      );
                      setState(() => isLoading = false);
                      if (success) {
                        Navigator.pop(context, true);
                      }
                    }
                  },
          child:
              isLoading
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Tambah'),
        ),
      ],
    );
  }
}

/// Dialog detail pasien
class PatientDetailDialog extends StatelessWidget {
  final DoctorPatient patient;
  const PatientDetailDialog({super.key, required this.patient});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Detail Pasien'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama: ${patient.name}'),
            Text('Email: ${patient.email}'),
            Text('Tanggal Lahir: ${patient.birthDate ?? '-'}'),
            Text('Alamat: ${patient.address ?? '-'}'),
            Text('Catatan Medis: ${patient.medicalNote ?? '-'}'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}
