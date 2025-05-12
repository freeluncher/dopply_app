import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource_impl.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<String?> login(String email, String password) async {
    return await remoteDataSource.login(email, password);
  }
}
