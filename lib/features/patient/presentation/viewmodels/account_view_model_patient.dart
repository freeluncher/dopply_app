import 'package:flutter/material.dart';
import '../../data/services/account_api_service_patient.dart';

class AccountViewModelPatient extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  String? success;

  Future<void> changeEmail(String newEmail, String password) async {
    isLoading = true;
    error = null;
    success = null;
    notifyListeners();
    final api = AccountApiServicePatient();
    final result = await api.changeEmail(
      newEmail: newEmail,
      password: password,
    );
    isLoading = false;
    if (result) {
      success = 'Email berhasil diubah';
    } else {
      error = 'Gagal mengubah email';
    }
    notifyListeners();
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    isLoading = true;
    error = null;
    success = null;
    notifyListeners();
    final api = AccountApiServicePatient();
    final result = await api.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    isLoading = false;
    if (result) {
      success = 'Password berhasil diubah';
    } else {
      error = 'Gagal mengubah password';
    }
    notifyListeners();
  }
}
