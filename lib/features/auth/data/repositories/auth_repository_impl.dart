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
    // Clear storage sebelum login baru
    await localDataSource.clearToken();
    final data = await remoteDataSource.login(email, password);
    if (data != null && data['access_token'] != null) {
      print('Token login (access_token): ${data['access_token']}'); // Debug log
      await localDataSource.saveToken(data['access_token']);
      final cekToken = await localDataSource.getToken();
      print('Token yang disimpan di storage: $cekToken'); // Debug log
      return User(
        id: data['id']?.toString() ?? '',
        email: data['email'] ?? '',
        role: data['role'] ?? '',
        isValid: data['is_valid'] == true,
        // name: data['name'] ?? '', // tambahkan jika User punya field name
      );
    }
    return null;
  }

  @override
  Future<String> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    final result = await remoteDataSource.register(name, email, password, role);
    return result ?? 'Register failed';
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
        isValid: payload['is_valid'] == true,
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
