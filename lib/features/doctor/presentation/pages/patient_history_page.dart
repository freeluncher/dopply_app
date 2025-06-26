import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dopply_app/features/doctor/data/services/record_api_service.dart';
import 'package:dopply_app/features/doctor/data/models/patient_history_record.dart';

// Halaman daftar riwayat monitoring pasien
class PatientHistoryPage extends StatefulWidget {
  const PatientHistoryPage({super.key});

  @override
  State<PatientHistoryPage> createState() => _PatientHistoryPageState();
}

class _PatientHistoryPageState extends State<PatientHistoryPage> {
  // Controller untuk input pencarian
  final TextEditingController _searchController = TextEditingController();
  // List semua record monitoring dari backend (pakai model)
  List<PatientHistoryRecord> allRecords = [];
  // List hasil filter pencarian
  List<PatientHistoryRecord> filteredRecords = [];
  // Status loading data
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Ambil data riwayat saat halaman pertama kali dibuka
    _fetchRecords();
    // Tambahkan listener untuk pencarian
    _searchController.addListener(_onSearch);
  }

  // Mengambil data riwayat monitoring dari backend
  Future<void> _fetchRecords() async {
    setState(() => isLoading = true);
    final api = RecordApiService();
    final records = await api.fetchRecords();
    allRecords =
        records
            .map<PatientHistoryRecord>((r) => PatientHistoryRecord.fromMap(r))
            .toList();
    filteredRecords = allRecords;
    setState(() => isLoading = false);
  }

  // Melakukan filter pencarian berdasarkan nama atau ID
  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredRecords =
          allRecords.where((record) {
            return record.patientName.toLowerCase().contains(query) ||
                record.id.toString().contains(query);
          }).toList();
    });
  }

  @override
  void dispose() {
    // Bersihkan controller saat widget dispose
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar judul halaman
      appBar: AppBar(title: const Text('Riwayat Pasien')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input pencarian pasien
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Cari pasien (nama atau ID)',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            // Daftar riwayat monitoring
            Expanded(
              child:
                  isLoading
                      // Tampilkan loading spinner jika data masih diambil
                      ? const Center(child: CircularProgressIndicator())
                      // Tampilkan pesan jika tidak ada data
                      : filteredRecords.isEmpty
                      ? const Center(child: Text('Tidak ada riwayat ditemukan'))
                      // Tampilkan list data jika ada
                      : ListView.builder(
                        itemCount: filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = filteredRecords[index];
                          return Card(
                            child: ListTile(
                              // Menampilkan ID pasien sebagai judul
                              title: Text('Pasien #${record.patientId}'),
                              // Menampilkan klasifikasi atau catatan sebagai subtitle
                              subtitle: Text(
                                record.classification ?? record.notes ?? '-',
                              ),
                              // Menampilkan ID record di sebelah kanan
                              trailing: Text('#${record.id}'),
                              // Navigasi ke halaman detail riwayat saat item diklik
                              onTap: () {
                                context.push(
                                  '/doctor/patient-history/${record.id}',
                                  extra:
                                      record
                                          .toMap(), // Kirim map agar router bisa fromMap
                                );
                              },
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
