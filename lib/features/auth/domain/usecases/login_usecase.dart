import '../repositories/auth_repository.dart';
import '../entities/user.dart';

class LoginUseCase {
  final AuthRepository repository;
  LoginUseCase(this.repository);

  Future<User?> execute(
    String email,
    String password, {
    void Function(String?)? onError,
  }) {
    return repository.login(email, password, onError: onError);
  }
}
