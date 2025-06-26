/// Model pasien ringkas untuk monitoring (bisa dikembangkan sesuai kebutuhan)
class MonitoringPatient {
  final String id;
  final String name;

  MonitoringPatient({required this.id, required this.name});

  factory MonitoringPatient.fromMap(Map<String, dynamic> map) {
    return MonitoringPatient(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '-',
    );
  }
}
