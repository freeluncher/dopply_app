/// Model data record monitoring pasien
class PatientHistoryRecord {
  final int id;
  final String patientName;
  final String patientId;
  final String? classification;
  final String? notes;
  final String? startTime;

  PatientHistoryRecord({
    required this.id,
    required this.patientName,
    required this.patientId,
    this.classification,
    this.notes,
    this.startTime,
  });

  factory PatientHistoryRecord.fromMap(Map<String, dynamic> map) {
    return PatientHistoryRecord(
      id:
          map['id'] is int
              ? map['id']
              : int.tryParse(map['id'].toString()) ?? 0,
      patientName: map['patient_name'] ?? '-',
      patientId: map['patient_id']?.toString() ?? '-',
      classification: map['classification'],
      notes: map['notes'],
      startTime: map['start_time']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_name': patientName,
      'patient_id': patientId,
      'classification': classification,
      'notes': notes,
      'start_time': startTime,
    };
  }
}
