import '../entities/user.dart';

abstract class AuthRepository {
  Future<User?> login(
    String email,
    String password, {
    void Function(String?)? onError,
  });
  Future<String> register(
    String name,
    String email,
    String password,
    String role,
  );
  Future<User?> getCurrentUserFromToken();
  Future<void> logout();
}
