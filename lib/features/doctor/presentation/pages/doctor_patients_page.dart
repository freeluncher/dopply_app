import 'package:flutter/material.dart';
import 'package:dopply_app/features/doctor/data/services/monitoring_api_service.dart';
import 'package:dopply_app/features/doctor/data/services/patient_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/features/auth/presentation/viewmodels/user_provider.dart';

class DoctorPatientsPage extends StatefulWidget {
  const DoctorPatientsPage({Key? key}) : super(key: key);

  @override
  State<DoctorPatientsPage> createState() => _DoctorPatientsPageState();
}

class _DoctorPatientsPageState extends State<DoctorPatientsPage> {
  List<Map<String, dynamic>> patients = [];
  List<Map<String, dynamic>> filteredPatients = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    setState(() => isLoading = true);
    final container = ProviderScope.containerOf(context, listen: false);
    final user = container.read(userProvider);
    final doctorId = user?.doctorId ?? user?.id;
    if (doctorId == null) {
      setState(() {
        patients = [];
        filteredPatients = [];
        isLoading = false;
      });
      return;
    }
    final api = MonitoringApiService();
    print('[DoctorPatientsPage] Fetching patients...');
    final data = await api.getPatientsByDoctorIdWithStorage(
      doctorId: int.parse(doctorId.toString()),
    );
    print('[DoctorPatientsPage] Data from API: $data');
    // Mapping: pastikan setiap pasien punya patient_id (FK ke users.id)
    patients = data.map((p) {
      if (p['patient_id'] == null && p['id'] != null) {
        return {...p, 'patient_id': p['id']};
      }
      return p;
    }).toList();
    filteredPatients = patients;
    setState(() => isLoading = false);
  }

  void _onSearch(String query) {
    setState(() {
      searchQuery = query;
      filteredPatients =
          patients.where((p) {
            final name = (p['name'] ?? '').toLowerCase();
            final email = (p['email'] ?? '').toLowerCase();
            return name.contains(query.toLowerCase()) ||
                email.contains(query.toLowerCase());
          }).toList();
    });
  }

  void _onDelete(Map<String, dynamic> patient) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Hapus Pasien'),
            content: Text('Yakin ingin menghapus pasien ini?'),
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
          ),
    );
    if (confirm == true) {
      final container = ProviderScope.containerOf(context, listen: false);
      final user = container.read(userProvider);
      final doctorId = user?.doctorId ?? user?.id;
      if (doctorId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus pasien: doctorId tidak ditemukan!'),
          ),
        );
        return;
      }
      final api = PatientApiService();
      final success = await api.unassignPatientFromDoctor(
        int.parse(doctorId.toString()),
        patient['patient_id'] ?? patient['id'], // pastikan selalu pakai patient_id (FK ke users.id)
      );
      if (success) {
        await _fetchPatients();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pasien berhasil dihapus dari daftar Anda!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus pasien!')),
        );
      }
    }
  }

  void _onAdd() async {
    final emailController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? backendError;
    final result = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Tambah Pasien ke Daftar Dokter'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Pasien',
                      ),
                      validator:
                          (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    TextFormField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (opsional)',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    final container = ProviderScope.containerOf(
                      context,
                      listen: false,
                    );
                    final user = container.read(userProvider);
                    final doctorId = user?.doctorId ?? user?.id;
                    if (doctorId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gagal: doctorId tidak ditemukan!'),
                        ),
                      );
                      return;
                    }
                    final api = PatientApiService();
                    final success = await api.assignPatientToDoctorByEmail(
                      doctorId: int.parse(doctorId.toString()),
                      email: emailController.text,
                      note:
                          noteController.text.isNotEmpty
                              ? noteController.text
                              : null,
                      status: 'active',
                      onError: (err) => backendError = err,
                    );
                    if (success) {
                      Navigator.pop(context, true);
                    } else {
                      if (backendError != null && backendError!.isNotEmpty) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(backendError!)));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gagal menambahkan pasien!'),
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text('Tambah'),
              ),
            ],
          ),
    );
    if (result == true) {
      await _fetchPatients();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pasien berhasil ditambahkan ke daftar Anda!'),
        ),
      );
    }
  }

  void _onDetail(Map<String, dynamic> patient) async {
    // Tampilkan detail langsung dari objek patient (table patients), tanpa fetch ulang ke API
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Detail Pasien'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nama: \\${patient['name'] ?? '-'}'),
                  Text('Email: \\${patient['email'] ?? '-'}'),
                  Text('Tanggal Lahir: \\${patient['birth_date'] ?? '-'}'),
                  Text('Alamat: \\${patient['address'] ?? '-'}'),
                  Text('Catatan Medis: \\${patient['medical_note'] ?? '-'}'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Pasien'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _onAdd,
            tooltip: 'Tambah Pasien',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Cari pasien',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onSearch,
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredPatients.isEmpty
                      ? const Center(child: Text('Tidak ada pasien ditemukan'))
                      : ListView.builder(
                        itemCount: filteredPatients.length,
                        itemBuilder: (context, index) {
                          final patient = filteredPatients[index];
                          return Card(
                            child: ListTile(
                              title: Text(patient['name'] ?? '-'),
                              subtitle: Text(patient['email'] ?? '-'),
                              onTap: () => _onDetail(patient),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _onDelete(patient),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
