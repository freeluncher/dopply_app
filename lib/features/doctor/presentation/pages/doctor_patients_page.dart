import 'package:flutter/material.dart';
import 'package:dopply_app/features/doctor/data/services/monitoring_api_service.dart';
import 'package:dopply_app/features/doctor/data/services/patient_api_service.dart';

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
    final api = MonitoringApiService();
    print('[DoctorPatientsPage] Fetching patients...');
    final data = await api.getPatientsByDoctorIdWithStorage();
    print('[DoctorPatientsPage] Data from API: $data');
    patients = data;
    filteredPatients = data;
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

  void _onEdit(Map<String, dynamic> patient) async {
    final nameController = TextEditingController(text: patient['name'] ?? '');
    final emailController = TextEditingController(text: patient['email'] ?? '');
    final passwordController = TextEditingController();
    final addressController = TextEditingController(
      text: patient['address'] ?? '',
    );
    final birthDateController = TextEditingController(
      text: patient['birth_date'] ?? '',
    );
    final medicalNoteController = TextEditingController(
      text: patient['medical_note'] ?? '',
    );
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Edit Pasien'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nama'),
                      validator:
                          (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator:
                          (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password (opsional)',
                      ),
                      obscureText: true,
                    ),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Alamat'),
                    ),
                    TextFormField(
                      controller: birthDateController,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Lahir (YYYY-MM-DD)',
                      ),
                    ),
                    TextFormField(
                      controller: medicalNoteController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Medis',
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
                    final api = PatientApiService();
                    final updateData = {
                      'name': nameController.text,
                      'email': emailController.text,
                      'birth_date': birthDateController.text,
                      'address': addressController.text,
                      'medical_note': medicalNoteController.text,
                    };
                    if (passwordController.text.isNotEmpty) {
                      updateData['password'] = passwordController.text;
                    }
                    final success = await api.updatePatient(
                      patient['id'],
                      updateData,
                    );
                    Navigator.pop(context, success);
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
    );
    if (result == true) {
      _fetchPatients();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data pasien berhasil diupdate!')),
      );
    }
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
      final api = PatientApiService();
      final success = await api.deletePatient(
        patient['patient_id'] ?? patient['id'],
      );
      if (success) {
        _fetchPatients();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pasien berhasil dihapus!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus pasien!')),
        );
      }
    }
  }

  void _onAdd() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final roleController = TextEditingController(text: 'patient');
    final addressController = TextEditingController();
    final birthDateController = TextEditingController();
    final medicalNoteController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Tambah Pasien'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nama'),
                      validator:
                          (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator:
                          (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator:
                          (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    // Role hidden, default patient
                    TextFormField(
                      controller: roleController,
                      decoration: const InputDecoration(labelText: 'Role'),
                      readOnly: true,
                    ),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Alamat (opsional)',
                      ),
                    ),
                    TextFormField(
                      controller: birthDateController,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Lahir (YYYY-MM-DD, opsional)',
                      ),
                    ),
                    TextFormField(
                      controller: medicalNoteController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Medis (opsional)',
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
                    final api = PatientApiService();
                    final data = {
                      'name': nameController.text,
                      'email': emailController.text,
                      'password': passwordController.text,
                      'role': roleController.text,
                    };
                    if (birthDateController.text.isNotEmpty)
                      data['birth_date'] = birthDateController.text;
                    if (addressController.text.isNotEmpty)
                      data['address'] = addressController.text;
                    if (medicalNoteController.text.isNotEmpty)
                      data['medical_note'] = medicalNoteController.text;
                    print('[Register] Request: $data');
                    final success = await api.registerPatient(data);
                    print('[Register] Result: $success');
                    Navigator.pop(context, success);
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
    );
    if (result == true) {
      _fetchPatients();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pasien berhasil didaftarkan!')),
      );
    }
  }

  void _onDetail(Map<String, dynamic> patient) async {
    final api = PatientApiService();
    final detail = await api.getPatientDetail(patient['id']);
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Detail Pasien'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nama: \\${detail?['name'] ?? '-'}'),
                  Text('Email: \\${detail?['email'] ?? '-'}'),
                  Text('Tanggal Lahir: \\${detail?['birth_date'] ?? '-'}'),
                  Text('Alamat: \\${detail?['address'] ?? '-'}'),
                  Text('Catatan Medis: \\${detail?['medical_note'] ?? '-'}'),
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
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _onEdit(patient),
                                  ),
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
