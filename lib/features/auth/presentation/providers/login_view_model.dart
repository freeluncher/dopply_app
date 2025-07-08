import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/user.dart';
import '../../../../services/api/auth_api_service.dart';
import '../../../../shared/services/token_storage_service.dart';
import 'auth_repository_provider.dart';

/// Login ViewModel using new API service architecture
///
/// Handles login business logic with improved error handling and state management
class LoginViewModel extends ChangeNotifier {
  final AuthApiService _authApiService;

  // State properties
  bool _isLoading = false;
  String? _error;
  String? _success;

  LoginViewModel(this._authApiService);

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get success => _success;

  /// Reset all messages and state
  void resetMessage() {
    _error = null;
    _success = null;
    notifyListeners();
  }

  /// Login with email and password
  /// Returns User object if successful, null if failed
  Future<User?> login(String email, String password) async {
    print('[AUTH][VM] LoginViewModel login called');
    print('[AUTH][VM] Request: {email: $email, password: [HIDDEN]}');

    _isLoading = true;
    _error = null;
    _success = null;
    notifyListeners();

    try {
      // Call new API service
      final result = await _authApiService.login(
        email: email,
        password: password,
      );

      _isLoading = false;

      if (result['success'] == true && result['access_token'] != null) {
        // Parse user from response - API returns user data directly, not nested under 'user'
        final user = User.fromJson(result);

        // Store access token for future API calls
        if (result['access_token'] != null) {
          await TokenStorageService().saveToken(result['access_token']);
        }

        print('[AUTH][VM] Login successful: ${user.email}, role: ${user.role}');
        _success = 'Login berhasil!';
        notifyListeners();
        return user;
      } else {
        final errorMessage = result['message'] ?? 'Login gagal';
        print('[AUTH][VM] Login failed: $errorMessage');
        _error = errorMessage;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _isLoading = false;

      // Enhanced error handling for specific backend issues
      String errorMessage = 'Login failed';

      if (e.toString().contains('Could not determine join condition') ||
          e.toString().contains('foreign keys linking') ||
          e.toString().contains('doctor_patient_associations')) {
        errorMessage =
            'Server configuration error. Please contact support or try again later.';
        print(
          '[AUTH][VM] Backend database relationship error detected: ${e.toString()}',
        );
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection') ||
          e.toString().contains('timeout')) {
        errorMessage =
            'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('401') ||
          e.toString().contains('unauthorized')) {
        errorMessage = 'Invalid email or password.';
      } else if (e.toString().contains('500') ||
          e.toString().contains('internal server')) {
        errorMessage = 'Server error. Please try again later.';
      } else {
        errorMessage = 'Login error: ${e.toString()}';
      }

      _error = errorMessage;
      print('[AUTH][VM] Login exception: $_error');
      notifyListeners();
      return null;
    }
  }
}

/// Provider for LoginViewModel
final loginViewModelProvider = ChangeNotifierProvider<LoginViewModel>((ref) {
  return LoginViewModel(ref.read(authApiServiceProvider));
});
