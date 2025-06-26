import 'package:flutter/material.dart';
import 'package:dopply_app/core/utils/date_utils.dart';
import 'package:dopply_app/features/doctor/data/models/patient_history_record.dart';

/// Halaman detail riwayat monitoring pasien
class PatientHistoryDetailPage extends StatelessWidget {
  /// Data record monitoring yang akan ditampilkan
  final PatientHistoryRecord record;
  const PatientHistoryDetailPage({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar menampilkan ID record
      appBar: AppBar(title: Text('Detail Riwayat Pasien #${record.id}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: PatientHistoryDetailContent(record: record),
      ),
    );
  }
}

/// Widget isi detail riwayat monitoring pasien
class PatientHistoryDetailContent extends StatelessWidget {
  final PatientHistoryRecord record;
  const PatientHistoryDetailContent({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nama pasien
        Text(
          'Nama Pasien: ${record.patientName}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // ID record monitoring
        Text('ID Record: ${record.id}'),
        const SizedBox(height: 8),
        // ID pasien
        Text('ID Pasien: ${record.patientId}'),
        const SizedBox(height: 8),
        // Klasifikasi hasil monitoring
        Text('Klasifikasi: ${record.classification ?? '-'}'),
        const SizedBox(height: 8),
        // Catatan dokter
        Text('Catatan: ${record.notes ?? '-'}'),
        const SizedBox(height: 8),
        // Tanggal monitoring diformat Indonesia
        Text('Tanggal: ${formatTanggalIndo(record.startTime)}'),
        // Tambahkan field lain dari table records jika ada
      ],
    );
  }
}
