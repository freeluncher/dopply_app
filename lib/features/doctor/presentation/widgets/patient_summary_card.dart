import 'package:flutter/material.dart';

class PatientSummaryCard extends StatelessWidget {
  final String patientName;
  final String patientId;
  const PatientSummaryCard({
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
              patientName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('ID Pasien: $patientId', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            const Text('Data singkat: ...'),
          ],
        ),
      ),
    );
  }
}
