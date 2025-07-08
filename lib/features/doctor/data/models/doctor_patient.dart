/// Model data pasien untuk dokter
class DoctorPatient {
  final int patientId;
  final String name;
  final String email;
  final String? birthDate;
  final String? address;
  final String? medicalNote;
  final int? age;
  final String? gender;
  final String? phone;
  final String? status;
  final String? notes;

  DoctorPatient({
    required this.patientId,
    required this.name,
    required this.email,
    this.birthDate,
    this.address,
    this.medicalNote,
    this.age,
    this.gender,
    this.phone,
    this.status,
    this.notes,
  });

  factory DoctorPatient.fromMap(Map<String, dynamic> map) {
    return DoctorPatient(
      patientId: map['patient_id'] ?? map['id'] ?? 0,
      name: map['name'] ?? map['patient_name'] ?? '-',
      email: map['email'] ?? map['patient_email'] ?? '-',
      // Handle both direct fields and nested patient object
      birthDate:
          map['birth_date'] ??
          map['patient_birth_date'] ??
          map['patient']?['birth_date'],
      address:
          map['address'] ??
          map['patient_address'] ??
          map['patient']?['address'],
      medicalNote:
          map['medical_note'] ??
          map['notes'] ??
          map['patient']?['medical_note'],
      age: map['age'] ?? map['patient']?['age'],
      gender: map['gender'] ?? map['patient']?['gender'],
      phone: map['phone'] ?? map['patient']?['phone'],
      status: map['status'] ?? map['patient_status'] ?? 'active',
      notes: map['notes'] ?? map['patient_notes'],
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
      'age': age,
      'gender': gender,
      'phone': phone,
      'status': status,
      'notes': notes,
    };
  }
}
