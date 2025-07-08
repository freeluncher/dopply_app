import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/services/image_picker_service.dart';
import '../../../../shared/services/photo_upload_service.dart';
import '../../../../features/auth/data/repositories/auth_repository.dart';
import 'user_provider.dart';
import 'auth_repository_provider.dart';

/// State for profile photo upload process
class ProfilePhotoState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const ProfilePhotoState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  ProfilePhotoState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return ProfilePhotoState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

/// Profile photo upload provider
///
/// Manages the complete flow of profile photo selection, cropping, and upload
class ProfilePhotoNotifier extends StateNotifier<ProfilePhotoState> {
  final PhotoUploadService _photoUploadService;
  final AuthRepository _authRepository;
  final Ref _ref;

  ProfilePhotoNotifier(
    this._photoUploadService,
    this._authRepository,
    this._ref,
  ) : super(const ProfilePhotoState());

  /// Select and upload photo using image picker dialog
  Future<void> selectAndUploadPhoto(BuildContext context) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        successMessage: null,
      );

      // Step 1: Show image source selection dialog and get processed image
      final File? processedFile =
          await ImagePickerService.showImageSourceDialog(context);

      if (processedFile == null) {
        state = state.copyWith(isLoading: false);
        return; // User cancelled
      }

      // Step 2: Upload the processed image (already cropped by ImagePickerService)
      final uploadResult = await _photoUploadService.uploadPhoto(processedFile);

      if (uploadResult == null || uploadResult['success'] != true) {
        throw Exception(uploadResult?['message'] ?? 'Upload gagal');
      }

      // Step 3: Refresh user data to reflect the change
      await _refreshUserData();

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Foto profil berhasil diubah',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal mengubah foto profil: $e',
      );
    }
  }

  /// Delete current profile photo
  Future<void> deletePhoto() async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        successMessage: null,
      );

      final deleteResult = await _photoUploadService.deletePhoto();

      if (deleteResult == null || deleteResult['success'] != true) {
        throw Exception(deleteResult?['message'] ?? 'Hapus foto gagal');
      }

      // Refresh user data to reflect the change
      await _refreshUserData();

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Foto profil berhasil dihapus',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal menghapus foto profil: $e',
      );
    }
  }

  /// Refresh user data after successful photo operation
  Future<void> _refreshUserData() async {
    try {
      // Use auth repository to get updated user data
      final updatedUser = await _authRepository.getCurrentUserFromToken();
      if (updatedUser != null) {
        _ref.read(userProvider.notifier).state = updatedUser;
      }
    } catch (e) {
      // Log error but don't fail the whole operation
      print('Warning: Failed to refresh user data after photo operation: $e');
    }
  }

  /// Clear error or success messages
  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

/// Provider for profile photo upload functionality
final profilePhotoProvider =
    StateNotifierProvider<ProfilePhotoNotifier, ProfilePhotoState>((ref) {
      return ProfilePhotoNotifier(
        PhotoUploadService(),
        ref.watch(authRepositoryProvider),
        ref,
      );
    });
