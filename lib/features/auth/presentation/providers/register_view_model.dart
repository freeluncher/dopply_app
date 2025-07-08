import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/api/auth_api_service.dart';
import 'auth_repository_provider.dart';

/// Register ViewModel using new API service architecture
///
/// Handles registration business logic with improved error handling and state management
class RegisterViewModel extends ChangeNotifier {
  final AuthApiService _authApiService;

  // State properties
  bool _isLoading = false;
  String? _error;
  String? _success;

  RegisterViewModel(this._authApiService);

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

  /// Register new user with name, email, password, and role
  /// Returns user role if successful, null if failed
  Future<String?> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    print('[AUTH][VM] RegisterViewModel register called');
    print(
      '[AUTH][VM] Request: {name: $name, email: $email, password: [HIDDEN], role: $role}',
    );

    _isLoading = true;
    _error = null;
    _success = null;
    notifyListeners();

    try {
      // Call new API service
      final result = await _authApiService.register(
        name: name,
        email: email,
        password: password,
        role: role,
      );

      _isLoading = false;

      if (result['success'] == true && result['access_token'] != null) {
        print('[AUTH][VM] Registration successful for role: $role');
        _success = 'Registrasi berhasil! Silakan login.';
        notifyListeners();
        return role; // Return role as success indicator
      } else {
        final errorMessage = result['message'] ?? 'Registrasi gagal';
        print('[AUTH][VM] Registration failed: $errorMessage');
        _error = errorMessage;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Registrasi error: ${e.toString()}';
      print('[AUTH][VM] Registration exception: $_error');
      notifyListeners();
      return null;
    }
  }

  /// Register patient with additional medical information
  Future<String?> registerPatient(
    String name,
    String email,
    String password, {
    String? birthDate,
    String? address,
    String? medicalNote,
  }) async {
    print('[AUTH][VM] RegisterViewModel registerPatient called');

    _isLoading = true;
    _error = null;
    _success = null;
    notifyListeners();

    try {
      // Call API service with patient-specific data
      final result = await _authApiService.register(
        name: name,
        email: email,
        password: password,
        role: 'patient',
        birthDate: birthDate,
        address: address,
        medicalNote: medicalNote,
      );

      _isLoading = false;

      if (result['success'] == true && result['access_token'] != null) {
        print('[AUTH][VM] Patient registration successful');
        _success = 'Registrasi pasien berhasil! Silakan login.';
        notifyListeners();
        return 'patient';
      } else {
        final errorMessage = result['message'] ?? 'Registrasi pasien gagal';
        print('[AUTH][VM] Patient registration failed: $errorMessage');
        _error = errorMessage;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Registrasi pasien error: ${e.toString()}';
      print('[AUTH][VM] Patient registration exception: $_error');
      notifyListeners();
      return null;
    }
  }

  /// Register doctor
  Future<String?> registerDoctor(
    String name,
    String email,
    String password,
  ) async {
    print('[AUTH][VM] RegisterViewModel registerDoctor called');

    _isLoading = true;
    _error = null;
    _success = null;
    notifyListeners();

    try {
      // Call API service for doctor registration
      final result = await _authApiService.register(
        name: name,
        email: email,
        password: password,
        role: 'doctor',
      );

      _isLoading = false;

      if (result['success'] == true && result['access_token'] != null) {
        print('[AUTH][VM] Doctor registration successful');
        _success = 'Registrasi dokter berhasil! Silakan login.';
        notifyListeners();
        return 'doctor';
      } else {
        final errorMessage = result['message'] ?? 'Registrasi dokter gagal';
        print('[AUTH][VM] Doctor registration failed: $errorMessage');
        _error = errorMessage;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Registrasi dokter error: ${e.toString()}';
      print('[AUTH][VM] Doctor registration exception: $_error');
      notifyListeners();
      return null;
    }
  }
}

/// Provider for RegisterViewModel
final registerViewModelProvider = ChangeNotifierProvider<RegisterViewModel>((
  ref,
) {
  return RegisterViewModel(ref.read(authApiServiceProvider));
});
