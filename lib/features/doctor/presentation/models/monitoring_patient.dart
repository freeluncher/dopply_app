/// Patient status enum for type safety
enum PatientStatus {
  active('active', 'Aktif', 'Pasien sedang dalam perawatan aktif'),
  inactive('inactive', 'Tidak Aktif', 'Pasien tidak aktif sementara'),
  discharged('discharged', 'Selesai', 'Pasien sudah selesai perawatan');

  const PatientStatus(this.value, this.displayName, this.description);

  final String value;
  final String displayName;
  final String description;

  static PatientStatus fromString(String status) {
    return PatientStatus.values.firstWhere(
      (s) => s.value == status,
      orElse: () => PatientStatus.active,
    );
  }
}

/// Model pasien untuk monitoring dengan data lengkap dari API
class MonitoringPatient {
  final String id;
  final String name;
  final String email;
  final int? age;
  final String? gender;
  final String? phone;
  final String? photoUrl;
  final String? assignmentDate;
  final String status;
  final String? notes;
  final String? lastRecordDate;
  final int? totalRecords;

  MonitoringPatient({
    required this.id,
    required this.name,
    required this.email,
    this.age,
    this.gender,
    this.phone,
    this.photoUrl,
    this.assignmentDate,
    this.status = 'active',
    this.notes,
    this.lastRecordDate,
    this.totalRecords,
  });

  factory MonitoringPatient.fromMap(Map<String, dynamic> map) {
    return MonitoringPatient(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '-',
      email: map['email'] ?? '',
      age: map['age'],
      gender: map['gender'],
      phone: map['phone'],
      photoUrl: map['photo_url'],
      assignmentDate: map['assignment_date'],
      status: map['status'] ?? 'active',
      notes: map['notes'],
      lastRecordDate: map['last_record_date'],
      totalRecords: map['total_records'],
    );
  }

  /// Create a simple patient from basic user info (for backward compatibility)
  factory MonitoringPatient.fromBasicUser(Map<String, dynamic> map) {
    return MonitoringPatient(
      id: map['user_id']?.toString() ?? map['id']?.toString() ?? '',
      name: map['name'] ?? '-',
      email: map['email'] ?? '',
      age: map['age'],
      gender: map['gender'],
      phone: map['phone'],
      status: map['status'] ?? 'active',
      notes: map['note'] ?? map['notes'],
    );
  }

  /// Get patient status as enum
  PatientStatus get statusEnum => PatientStatus.fromString(status);

  /// Check if status can be changed
  bool get canChangeStatus => status != 'discharged';

  /// Get available status transitions
  List<PatientStatus> get availableStatusTransitions {
    switch (statusEnum) {
      case PatientStatus.active:
        return [
          PatientStatus.active,
          PatientStatus.inactive,
          PatientStatus.discharged,
        ];
      case PatientStatus.inactive:
        return [
          PatientStatus.inactive,
          PatientStatus.active,
          PatientStatus.discharged,
        ];
      case PatientStatus.discharged:
        return [PatientStatus.discharged]; // Cannot change from discharged
    }
  }

  /// Copy with new status and notes
  MonitoringPatient copyWithStatus({
    required String newStatus,
    String? newNotes,
  }) {
    return MonitoringPatient(
      id: id,
      name: name,
      email: email,
      age: age,
      gender: gender,
      phone: phone,
      photoUrl: photoUrl,
      assignmentDate: assignmentDate,
      status: newStatus,
      notes: newNotes ?? notes,
      lastRecordDate: lastRecordDate,
      totalRecords: totalRecords,
    );
  }
}
