import 'package:flutter/material.dart';

class PatientHistoryDetailPage extends StatefulWidget {
  final Map<String, dynamic> record;
  const PatientHistoryDetailPage({
    Key? key,
    required this.record,
  }) : super(key: key);

  @override
  State<PatientHistoryDetailPage> createState() => _PatientHistoryDetailPageState();
}

class _PatientHistoryDetailPageState extends State<PatientHistoryDetailPage> {
  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    return Scaffold(
      appBar: AppBar(title: Text('Detail Riwayat Pasien #${record['id']}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nama Pasien: ${record['patient_name'] ?? '-'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('ID Record: ${record['id'] ?? '-'}'),
            const SizedBox(height: 8),
            Text('ID Pasien: ${record['patient_id'] ?? '-'}'),
            const SizedBox(height: 8),
            Text('Klasifikasi: ${record['classification'] ?? '-'}'),
            const SizedBox(height: 8),
            Text('Catatan: ${record['notes'] ?? '-'}'),
            const SizedBox(height: 8),
            Text('Tanggal: ${_formatTanggal(record['start_time'])}'),
            // Tambahkan field lain dari table records jika ada
          ],
        ),
      ),
    );
  }
}

String _formatTanggal(dynamic startTime) {
  if (startTime == null) return '-';
  try {
    final dt = DateTime.parse(startTime.toString());
    final bulan = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${dt.day} ${bulan[dt.month]} ${dt.year}';
  } catch (_) {
    return startTime.toString();
  }
}
