import 'package:flutter/material.dart';

class PatientSummaryCard extends StatelessWidget {
  final String selectedPatient;
  const PatientSummaryCard({Key? key, required this.selectedPatient})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedPatient,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Data singkat: ...'),
          ],
        ),
      ),
    );
  }
}
