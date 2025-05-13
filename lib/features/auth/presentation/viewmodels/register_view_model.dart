import 'package:dopply_app/features/auth/presentation/viewmodels/login_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/register_usecase.dart';

final registerUseCaseProvider = Provider<RegisterUseCase>(
  (ref) => RegisterUseCase(ref.read(authRepositoryProvider)),
);

final registerViewModelProvider = ChangeNotifierProvider<RegisterViewModel>((
  ref,
) {
  return RegisterViewModel(ref.read(registerUseCaseProvider));
});

class RegisterViewModel extends ChangeNotifier {
  final RegisterUseCase _registerUseCase;
  bool isLoading = false;
  String? error;
  String? success;

  RegisterViewModel(this._registerUseCase);

  void resetMessage() {
    error = null;
    success = null;
    notifyListeners();
  }

  Future<String?> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    isLoading = true;
    error = null;
    success = null;
    notifyListeners();
    final result = await _registerUseCase.execute(name, email, password, role);
    isLoading = false;
    if (result != null) {
      success = 'Register Success!';
      notifyListeners();
      return result;
    } else {
      error = 'Register failed';
      notifyListeners();
      return null;
    }
  }
}
