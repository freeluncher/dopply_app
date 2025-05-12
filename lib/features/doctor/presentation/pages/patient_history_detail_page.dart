import 'package:flutter/material.dart';

class PatientHistoryDetailPage extends StatelessWidget {
  final String id;
  final String name;
  final String summary;
  const PatientHistoryDetailPage({
    Key? key,
    required this.id,
    required this.name,
    required this.summary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detail Riwayat Pasien #$id')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nama: $name',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('ID: $id'),
            const SizedBox(height: 8),
            Text('Ringkasan: $summary'),
            const SizedBox(height: 16),
            // Tambahkan data detail lain di sini (misal: tanggal, hasil pemeriksaan, dsb)
            const Text('Data lengkap riwayat akan ditampilkan di sini.'),
          ],
        ),
      ),
    );
  }
}
