import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource_impl.dart';
import 'package:dopply_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:dopply_app/core/utils/jwt_decoder.dart';
import '../../domain/entities/user.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  AuthRepositoryImpl(this.remoteDataSource, this.localDataSource);

  @override
  Future<User?> login(String email, String password) async {
    final data = await remoteDataSource.login(email, password);
    if (data != null && data['access_token'] != null) {
      await localDataSource.saveToken(data['access_token']);
      return User(
        id: data['id']?.toString() ?? '',
        email: data['email'] ?? '',
        role: data['role'] ?? '',
        // name: data['name'] ?? '', // tambahkan jika User punya field name
      );
    }
    return null;
  }

  @override
  Future<String?> register(String name, String email, String password) async {
    return await remoteDataSource.register(name, email, password);
  }

  @override
  Future<User?> getCurrentUserFromToken() async {
    final token = await localDataSource.getToken();
    if (token == null) return null;
    if (JwtDecoder.isExpired(token)) {
      await localDataSource.clearToken();
      return null;
    }
    try {
      final payload = JwtDecoder.decode(token);
      return User(
        id: payload['id']?.toString() ?? '',
        email: payload['email'] ?? '',
        role: payload['role'] ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    await localDataSource.clearToken();
  }
}
