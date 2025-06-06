import 'package:flutter/material.dart';

class PatientSummaryCardPatient extends StatelessWidget {
  final String patientName;
  final String patientId;
  const PatientSummaryCardPatient({
    Key? key,
    required this.patientName,
    required this.patientId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              patientName.isEmpty ? 'Nama Anda' : patientName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'ID Pasien: ${patientId.isEmpty ? '-' : patientId}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
