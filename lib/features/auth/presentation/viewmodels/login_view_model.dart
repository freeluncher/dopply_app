import 'package:dopply_app/features/auth/data/datasources/auth_remote_datasource_impl.dart';
import 'package:dopply_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:dopply_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import 'package:dopply_app/features/auth/data/datasources/auth_local_datasource.dart';

// Provider untuk AuthRemoteDataSource
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSourceImpl(),
);

// Provider untuk AuthLocalDataSource
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>(
  (ref) => AuthLocalDataSource(),
);

// Provider untuk AuthRepository
final authRepositoryProvider = Provider<AuthRepositoryImpl>(
  (ref) => AuthRepositoryImpl(
    ref.read(authRemoteDataSourceProvider),
    ref.read(authLocalDataSourceProvider),
  ),
);

// Provider untuk LoginUseCase
final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.read(authRepositoryProvider)),
);

// ViewModel Provider
final loginViewModelProvider = ChangeNotifierProvider<LoginViewModel>((ref) {
  return LoginViewModel(ref.read(loginUseCaseProvider));
});

class LoginViewModel extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  bool isLoading = false;
  String? error;

  LoginViewModel(this._loginUseCase);

  Future<User?> login(String email, String password) async {
    print('[Login] Request: {email: $email, password: [HIDDEN]}');
    isLoading = true;
    error = null;
    notifyListeners();

    String? backendError;
    final user = await _loginUseCase.execute(
      email,
      password,
      onError: (err) {
        backendError = err;
      },
    );
    isLoading = false;
    if (user != null) {
      print('[Login] Result: success, user: ${user.email}, role: ${user.role}');
      error = null;
      notifyListeners();
      return user;
    } else {
      print(
        '[Login] Result: failed, error: ${backendError ?? 'Invalid credentials'}',
      );
      error = backendError ?? 'Invalid credentials';
      notifyListeners();
      return null;
    }
  }
}
