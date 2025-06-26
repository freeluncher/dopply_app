/// Model data pasien untuk dokter
class DoctorPatient {
  final int patientId;
  final String name;
  final String email;
  final String? birthDate;
  final String? address;
  final String? medicalNote;

  DoctorPatient({
    required this.patientId,
    required this.name,
    required this.email,
    this.birthDate,
    this.address,
    this.medicalNote,
  });

  factory DoctorPatient.fromMap(Map<String, dynamic> map) {
    return DoctorPatient(
      patientId: map['patient_id'] ?? map['id'],
      name: map['name'] ?? '-',
      email: map['email'] ?? '-',
      birthDate: map['birth_date'],
      address: map['address'],
      medicalNote: map['medical_note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patient_id': patientId,
      'name': name,
      'email': email,
      'birth_date': birthDate,
      'address': address,
      'medical_note': medicalNote,
    };
  }
}
