import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/app/theme.dart';
import 'package:dopply_app/shared/services/image_picker_service.dart';
import 'package:dopply_app/shared/services/photo_upload_service.dart';

/// State provider untuk photo upload
class PhotoUploadState {
  final bool isLoading;
  final String? error;
  final String? photoUrl;

  const PhotoUploadState({this.isLoading = false, this.error, this.photoUrl});

  PhotoUploadState copyWith({
    bool? isLoading,
    String? error,
    String? photoUrl,
  }) {
    return PhotoUploadState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

/// ViewModel untuk menangani upload foto
class PhotoUploadViewModel extends StateNotifier<PhotoUploadState> {
  final PhotoUploadService _uploadService;

  PhotoUploadViewModel({PhotoUploadService? uploadService})
    : _uploadService = uploadService ?? PhotoUploadService(),
      super(const PhotoUploadState());

  /// Upload foto yang dipilih user
  Future<bool> uploadPhoto(File imageFile) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _uploadService.uploadPhoto(imageFile);

      if (result != null && result['success'] == true) {
        final photoUrl = result['photo_url'] as String?;
        state = state.copyWith(isLoading: false, photoUrl: photoUrl);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result?['message'] ?? 'Upload gagal',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Upload gagal: ${e.toString()}',
      );
      return false;
    }
  }

  /// Hapus foto user
  Future<bool> deletePhoto() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _uploadService.deletePhoto();

      if (result != null && result['success'] == true) {
        state = state.copyWith(isLoading: false, photoUrl: null);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result?['message'] ?? 'Hapus foto gagal',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Hapus foto gagal: ${e.toString()}',
      );
      return false;
    }
  }

  /// Reset error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Set initial photo URL dari user data
  void setInitialPhotoUrl(String? photoUrl) {
    state = state.copyWith(photoUrl: photoUrl);
  }
}

/// Provider untuk PhotoUploadViewModel
final photoUploadProvider =
    StateNotifierProvider<PhotoUploadViewModel, PhotoUploadState>(
      (ref) => PhotoUploadViewModel(),
    );

/// Widget untuk menampilkan dan mengedit foto profil user
class ProfilePhotoWidget extends ConsumerWidget {
  final String? initialPhotoUrl;
  final double size;
  final bool editable;
  final VoidCallback? onPhotoChanged;

  const ProfilePhotoWidget({
    Key? key,
    this.initialPhotoUrl,
    this.size = 120,
    this.editable = true,
    this.onPhotoChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoState = ref.watch(photoUploadProvider);
    final photoViewModel = ref.read(photoUploadProvider.notifier);

    // Set initial photo URL jika belum ada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (photoState.photoUrl != initialPhotoUrl && initialPhotoUrl != null) {
        photoViewModel.setInitialPhotoUrl(initialPhotoUrl);
      }
    });

    return Column(
      children: [
        // Photo display dengan overlay loading
        Stack(
          children: [
            // Photo container
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.medicalGray,
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  width: 2,
                ),
                boxShadow: [AppColors.mediumShadow],
              ),
              child: ClipOval(child: _buildPhotoContent(photoState.photoUrl)),
            ),

            // Loading overlay
            if (photoState.isLoading)
              Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black54,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.medicalWhite,
                    strokeWidth: 3,
                  ),
                ),
              ),

            // Edit button
            if (editable && !photoState.isLoading)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _showPhotoOptions(context, ref),
                  child: Container(
                    width: size * 0.25,
                    height: size * 0.25,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.medicalWhite,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: AppColors.medicalWhite,
                      size: size * 0.12,
                    ),
                  ),
                ),
              ),
          ],
        ),

        // Error message
        if (photoState.error != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.medicalRedLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              photoState.error!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.medicalRed,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  /// Build konten foto (image atau placeholder)
  Widget _buildPhotoContent(String? photoUrl) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Image.network(
        photoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
              color: AppColors.primaryBlue,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }
    return _buildPlaceholder();
  }

  /// Build placeholder icon
  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      color: AppColors.medicalGray,
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: AppColors.textTertiary,
      ),
    );
  }

  /// Tampilkan opsi foto (upload/hapus)
  void _showPhotoOptions(BuildContext context, WidgetRef ref) {
    final photoState = ref.read(photoUploadProvider);

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Foto Profil', style: AppTextStyles.titleMedium),
                const SizedBox(height: 16),

                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: AppColors.primaryBlue,
                  ),
                  title: const Text('Ubah Foto'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadPhoto(context, ref);
                  },
                ),

                if (photoState.photoUrl != null)
                  ListTile(
                    leading: const Icon(
                      Icons.delete,
                      color: AppColors.medicalRed,
                    ),
                    title: const Text('Hapus Foto'),
                    onTap: () {
                      Navigator.pop(context);
                      _deletePhoto(context, ref);
                    },
                  ),

                ListTile(
                  leading: const Icon(
                    Icons.cancel,
                    color: AppColors.textSecondary,
                  ),
                  title: const Text('Batal'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
    );
  }

  /// Pilih dan upload foto
  Future<void> _pickAndUploadPhoto(BuildContext context, WidgetRef ref) async {
    try {
      // Clear any previous errors
      ref.read(photoUploadProvider.notifier).clearError();

      // Pick image
      final imageFile = await ImagePickerService.showImageSourceDialog(context);
      if (imageFile == null) return;

      // Upload image
      final success = await ref
          .read(photoUploadProvider.notifier)
          .uploadPhoto(imageFile);

      if (success && context.mounted) {
        // Callback untuk notify parent widget
        onPhotoChanged?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui'),
            backgroundColor: AppColors.medicalGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah foto: ${e.toString()}'),
            backgroundColor: AppColors.medicalRed,
          ),
        );
      }
    }
  }

  /// Hapus foto
  Future<void> _deletePhoto(BuildContext context, WidgetRef ref) async {
    try {
      // Clear any previous errors
      ref.read(photoUploadProvider.notifier).clearError();

      final success =
          await ref.read(photoUploadProvider.notifier).deletePhoto();

      if (success && context.mounted) {
        // Callback untuk notify parent widget
        onPhotoChanged?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil dihapus'),
            backgroundColor: AppColors.medicalGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus foto: ${e.toString()}'),
            backgroundColor: AppColors.medicalRed,
          ),
        );
      }
    }
  }
}
