import 'package:flutter/material.dart';
import 'package:dopply_app/features/doctor/data/services/monitoring_api_service.dart';

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

  void _onEdit(Map<String, dynamic> patient) {
    // TODO: Implement edit patient
  }

  void _onDelete(Map<String, dynamic> patient) {
    // TODO: Implement delete patient
  }

  void _onAdd() {
    // TODO: Implement add patient
  }

  void _onDetail(Map<String, dynamic> patient) {
    // TODO: Show patient detail page
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Detail Pasien'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nama: \\${patient['name'] ?? '-'}'),
                  Text('Email: \\${patient['email'] ?? '-'}'),
                  Text('Alamat: \\${patient['address'] ?? '-'}'),
                  Text('Tanggal Lahir: \\${patient['birth_date'] ?? '-'}'),
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
