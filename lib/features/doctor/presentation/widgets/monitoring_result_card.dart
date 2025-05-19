import 'package:flutter/material.dart';

class MonitoringResultCard extends StatelessWidget {
  final String? monitoringResult;
  final String? classification;
  final String doctorNote;
  final ValueChanged<String> onNoteChanged;
  final VoidCallback? onSave; // now optional
  final bool monitoringDone;
  const MonitoringResultCard({
    Key? key,
    required this.monitoringResult,
    required this.classification,
    required this.doctorNote,
    required this.onNoteChanged,
    this.onSave,
    required this.monitoringDone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (monitoringResult == null) return const SizedBox.shrink();
    final controller = TextEditingController(text: doctorNote);
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
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
              controller: controller,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 8),
            if (monitoringDone && onSave != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Simpan Hasil Pemeriksaan'),
                onPressed: onSave,
              ),
            if (!monitoringDone)
              Text(
                'Data hasil monitoring akan otomatis tersimpan setelah Anda menekan Simpan.',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
          ],
        ),
      ),
    );
  }
}
