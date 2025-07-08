import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/features/doctor/presentation/utils/add_patient_dialog.dart';
import 'package:dopply_app/features/auth/presentation/providers/user_provider.dart';
import 'package:dopply_app/features/doctor/data/services/patient_api_service.dart';
import '../models/monitoring_patient.dart';

// Provider for patient API service
final patientApiServiceProvider = Provider((ref) => PatientApiService());

// Provider for patients by doctor using real API
final patientsByDoctorProvider = FutureProvider<List<MonitoringPatient>>((
  ref,
) async {
  final user = ref.read(userProvider);
  if (user == null || user.role != 'doctor') {
    return [];
  }

  final apiService = ref.read(patientApiServiceProvider);

  try {
    final doctorId = user.id;
    final patientsData = await apiService.getPatientsByDoctorId(doctorId);

    // Convert API response to MonitoringPatient objects
    final patients =
        patientsData.map((data) {
          // Try to use enhanced format first, then fall back to basic user format
          try {
            return MonitoringPatient.fromMap(data);
          } catch (e) {
            // If enhanced format fails, try basic format
            return MonitoringPatient.fromBasicUser(data);
          }
        }).toList();

    return patients;
  } catch (e) {
    print('Error fetching patients: $e');

    // Fallback to demo data if API fails
    return [
      MonitoringPatient(
        id: '1',
        name: 'Jane Doe (Demo)',
        email: 'jane.doe@demo.com',
        age: 28,
        gender: 'female',
        status: 'active',
      ),
      MonitoringPatient(
        id: '2',
        name: 'Mary Smith (Demo)',
        email: 'mary.smith@demo.com',
        age: 32,
        gender: 'female',
        status: 'active',
      ),
      MonitoringPatient(
        id: '3',
        name: 'Sarah Johnson (Demo)',
        email: 'sarah.johnson@demo.com',
        age: 25,
        gender: 'female',
        status: 'active',
      ),
    ];
  }
});

// Simple search state provider
final patientSearchProvider = StateProvider<String>((ref) => '');

class PatientPickerDialog extends ConsumerWidget {
  const PatientPickerDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(patientsByDoctorProvider);
    final searchQuery = ref.watch(patientSearchProvider);

    return AlertDialog(
      title: Row(
        children: [
          const Text('Pilih Pasien'),
          const Spacer(),
          IconButton(
            onPressed: () {
              ref.invalidate(patientsByDoctorProvider);
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Cari Pasien',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                ref.read(patientSearchProvider.notifier).state = value;
              },
            ),
            const SizedBox(height: 16),
            patientsAsync.when(
              data: (patients) {
                final filteredPatients =
                    searchQuery.isEmpty
                        ? patients
                        : patients
                            .where(
                              (p) => p.name.toLowerCase().contains(
                                searchQuery.toLowerCase(),
                              ),
                            )
                            .toList();

                final isDemoData = patients.any(
                  (p) => p.name.contains('(Demo)'),
                );

                return Column(
                  children: [
                    if (isDemoData)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Menggunakan data demo. Periksa koneksi internet.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(
                      height: isDemoData ? 260 : 300,
                      child: ListView.builder(
                        itemCount: filteredPatients.length,
                        itemBuilder: (context, index) {
                          final patient = filteredPatients[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Text(
                                  patient.name.isNotEmpty
                                      ? patient.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                patient.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Email: ${patient.email}'),
                                  if (patient.age != null)
                                    Text('Umur: ${patient.age} tahun'),
                                  if (patient.phone != null)
                                    Text('Telepon: ${patient.phone}'),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              patient.status == 'active'
                                                  ? Colors.green.withOpacity(
                                                    0.2,
                                                  )
                                                  : Colors.orange.withOpacity(
                                                    0.2,
                                                  ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          patient.status.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color:
                                                patient.status == 'active'
                                                    ? Colors.green.shade700
                                                    : Colors.orange.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (patient.totalRecords != null) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '${patient.totalRecords} rekam medis',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.of(context).pop(patient);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading:
                  () => const SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Memuat daftar pasien...'),
                        ],
                      ),
                    ),
                  ),
              error:
                  (error, stack) => SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Gagal memuat daftar pasien',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Menggunakan data demo',
                            style: TextStyle(color: Colors.grey),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              ref.invalidate(patientsByDoctorProvider);
                            },
                            child: Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () async {
            final result = await showAddNewPatientDialog(context, ref);
            if (result == true) {
              // Refresh the patient list and close dialog
              ref.invalidate(patientsByDoctorProvider);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Tambah Pasien Baru'),
        ),
      ],
    );
  }
}
