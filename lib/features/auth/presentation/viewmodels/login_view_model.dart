import 'package:dopply_app/features/auth/data/datasources/auth_remote_datasource_impl.dart';
import 'package:dopply_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:dopply_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider untuk AuthRemoteDataSource
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSourceImpl(),
);

// Provider untuk AuthRepository
final authRepositoryProvider = Provider<AuthRepositoryImpl>(
  (ref) => AuthRepositoryImpl(ref.read(authRemoteDataSourceProvider)),
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

  Future<String?> login(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await _loginUseCase.execute(email, password);
    isLoading = false;
    if (result != null) {
      error = null;
      notifyListeners();
      return result;
    } else {
      error = 'Invalid credentials';
      notifyListeners();
      return null;
    }
  }
}
