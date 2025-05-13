class User {
  final String id;
  final String email;
  final String role; // e.g., 'admin', 'doctor', 'patient'
  final bool isValid;

  User({
    required this.id,
    required this.email,
    required this.role,
    required this.isValid,
  });
}
