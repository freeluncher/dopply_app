// =============================================================================
// Simplified Patient Model
// =============================================================================

class Patient {
  final int id;
  final String name;
  final String email;
  final DateTime? hpht; // Last menstrual period
  final int? gestationalAge; // Calculated from HPHT
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final int? age;

  const Patient({
    required this.id,
    required this.name,
    required this.email,
    this.hpht,
    this.gestationalAge,
    this.phoneNumber,
    this.dateOfBirth,
    this.age,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      hpht: json['hpht'] != null ? DateTime.parse(json['hpht']) : null,
      gestationalAge: json['gestational_age'],
      phoneNumber: json['phone_number'],
      dateOfBirth:
          json['date_of_birth'] != null
              ? DateTime.parse(json['date_of_birth'])
              : null,
      age: json['age'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'hpht': hpht?.toIso8601String(),
      'gestational_age': gestationalAge,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'age': age,
    };
  }

  Patient copyWith({
    int? id,
    String? name,
    String? email,
    DateTime? hpht,
    int? gestationalAge,
    String? phoneNumber,
    DateTime? dateOfBirth,
    int? age,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      hpht: hpht ?? this.hpht,
      gestationalAge: gestationalAge ?? this.gestationalAge,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age ?? this.age,
    );
  }

  // Calculate gestational age from HPHT
  int? get calculatedGestationalAge {
    if (hpht == null) return gestationalAge;

    final now = DateTime.now();
    final difference = now.difference(hpht!);
    final weeks = (difference.inDays / 7).floor();

    return weeks > 0 && weeks <= 42 ? weeks : gestationalAge;
  }
}
