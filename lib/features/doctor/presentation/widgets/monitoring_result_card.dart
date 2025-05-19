import 'package:flutter/material.dart';

class MonitoringResultCard extends StatelessWidget {
  final String? monitoringResult;
  final String? classification;
  final String doctorNote;
  final ValueChanged<String> onNoteChanged;
  final VoidCallback onSave;
  const MonitoringResultCard({
    Key? key,
    required this.monitoringResult,
    required this.classification,
    required this.doctorNote,
    required this.onNoteChanged,
    required this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (monitoringResult == null) return const SizedBox.shrink();
    return Card(
      color: monitoringResult == 'Normal' ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hasil Monitoring: $monitoringResult',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: monitoringResult == 'Normal' ? Colors.green : Colors.red,
              ),
            ),
            if (classification != null) Text('Klasifikasi: $classification'),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Catatan Dokter'),
              minLines: 2,
              maxLines: 4,
              onChanged: onNoteChanged,
              controller: TextEditingController(text: doctorNote),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Simpan Hasil Pemeriksaan'),
              onPressed: onSave,
            ),
          ],
        ),
      ),
    );
  }
}
