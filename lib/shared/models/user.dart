// User Model - Domain Entity
// Sesuai dengan response API dari endpoints authentication

class User {
  final int id;
  final String email;
  final String role; // 'admin', 'doctor', 'patient'
  final String name;
  final String? photoUrl;
  final bool isValid;
  final int? doctorId; // Untuk patient yang di-assign ke doctor
  final String? birthDate;
  final String? address;
  final String? medicalNote;

  const User({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    this.photoUrl,
    required this.isValid,
    this.doctorId,
    this.birthDate,
    this.address,
    this.medicalNote,
  });

  /// Factory constructor dari JSON response API
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      role: json['role'] as String,
      name: json['name'] as String,
      photoUrl: json['photo_url'] as String?,
      isValid: json['is_valid'] as bool? ?? true,
      doctorId: json['doctor_id'] as int?,
      birthDate: json['birth_date'] as String?,
      address: json['address'] as String?,
      medicalNote: json['medical_note'] as String?,
    );
  }

  /// Convert to JSON untuk API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'name': name,
      if (photoUrl != null) 'photo_url': photoUrl,
      'is_valid': isValid,
      if (doctorId != null) 'doctor_id': doctorId,
      if (birthDate != null) 'birth_date': birthDate,
      if (address != null) 'address': address,
      if (medicalNote != null) 'medical_note': medicalNote,
    };
  }

  /// Copy with new values
  User copyWith({
    int? id,
    String? email,
    String? role,
    String? name,
    String? photoUrl,
    bool? isValid,
    int? doctorId,
    String? birthDate,
    String? address,
    String? medicalNote,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      isValid: isValid ?? this.isValid,
      doctorId: doctorId ?? this.doctorId,
      birthDate: birthDate ?? this.birthDate,
      address: address ?? this.address,
      medicalNote: medicalNote ?? this.medicalNote,
    );
  }

  /// Check if user is admin
  bool get isAdmin => role == 'admin';

  /// Check if user is doctor
  bool get isDoctor => role == 'doctor';

  /// Check if user is patient
  bool get isPatient => role == 'patient';

  /// Get full photo URL
  String? get fullPhotoUrl {
    if (photoUrl == null) return null;
    return 'https://dopply.my.id$photoUrl';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;

  @override
  String toString() {
    return 'User{id: $id, email: $email, role: $role, name: $name, isValid: $isValid}';
  }
}
