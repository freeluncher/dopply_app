import 'package:flutter/material.dart';
import 'package:dopply_app/features/doctor/presentation/models/monitoring_patient.dart';

class PatientSummaryCard extends StatelessWidget {
  final String patientName;
  final String patientId;
  final MonitoringPatient? patient;

  const PatientSummaryCard({
    Key? key,
    required this.patientName,
    required this.patientId,
    this.patient,
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
              patientName.isEmpty ? 'Belum ada pasien dipilih' : patientName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'ID Pasien: ${patientId.isEmpty ? '-' : patientId}',
              style: const TextStyle(fontSize: 14),
            ),
            if (patient != null) ...[
              const SizedBox(height: 8),
              if (patient!.email.isNotEmpty)
                Text(
                  'Email: ${patient!.email}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              if (patient!.age != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Umur: ${patient!.age} tahun',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
              if (patient!.gender != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Jenis Kelamin: ${patient!.gender}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          patient!.status == 'active'
                              ? Colors.green.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      patient!.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            patient!.status == 'active'
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (patient!.totalRecords != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${patient!.totalRecords} rekam medis',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              const Text(
                'Silakan pilih pasien untuk memulai monitoring',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
