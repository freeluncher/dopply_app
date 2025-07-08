import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';

/// Utility service untuk memilih dan memproses gambar
/// Menyediakan fungsi untuk pick dari gallery/camera, crop, dan compress
class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// Tampilkan dialog pilihan sumber gambar (Gallery atau Camera)
  ///
  /// [context] - BuildContext untuk menampilkan dialog
  /// Returns: File gambar yang sudah diproses atau null jika dibatalkan
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    final service = ImagePickerService();

    return await showDialog<File?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Sumber Foto'),
          content: const Text('Pilih sumber foto untuk profil Anda'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final file = await service.pickFromCamera(context);
                if (context.mounted && file != null) {
                  Navigator.pop(context, file);
                }
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt),
                  SizedBox(width: 8),
                  Text('Kamera'),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final file = await service.pickFromGallery(context);
                if (context.mounted && file != null) {
                  Navigator.pop(context, file);
                }
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library),
                  SizedBox(width: 8),
                  Text('Galeri'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Ambil gambar dari kamera
  ///
  /// [context] - BuildContext untuk navigasi setelah crop
  /// Returns: File gambar yang sudah di-crop atau null
  Future<File?> pickFromCamera(BuildContext context) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Crop gambar setelah diambil
      return await _cropImage(context, image.path);
    } catch (e) {
      print('[IMAGE_PICKER] Error picking from camera: $e');
      return null;
    }
  }

  /// Ambil gambar dari galeri
  ///
  /// [context] - BuildContext untuk navigasi setelah crop
  /// Returns: File gambar yang sudah di-crop atau null
  Future<File?> pickFromGallery(BuildContext context) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Crop gambar setelah dipilih
      return await _cropImage(context, image.path);
    } catch (e) {
      print('[IMAGE_PICKER] Error picking from gallery: $e');
      return null;
    }
  }

  /// Crop gambar dengan ratio 1:1 untuk foto profil
  ///
  /// [context] - BuildContext untuk tema aplikasi
  /// [imagePath] - Path ke file gambar yang akan di-crop
  /// Returns: File gambar yang sudah di-crop atau null
  Future<File?> _cropImage(BuildContext context, String imagePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Foto Profil',
            toolbarColor: const Color(0xFF2E86AB),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            aspectRatioPresets: [CropAspectRatioPreset.square],
          ),
          IOSUiSettings(
            title: 'Crop Foto Profil',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPresets: [CropAspectRatioPreset.square],
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(width: 520, height: 520),
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;
    } catch (e) {
      print('[IMAGE_PICKER] Error cropping image: $e');
      return null;
    }
  }

  /// Compress dan simpan gambar ke direktori temporary
  ///
  /// [originalFile] - File gambar asli
  /// [quality] - Kualitas kompresi (0-100, default 85)
  /// Returns: File gambar yang sudah dikompres
  static Future<File> compressImage(
    File originalFile, {
    int quality = 85,
  }) async {
    try {
      final directory = await getTemporaryDirectory();
      final fileName =
          'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressedPath = '${directory.path}/$fileName';

      // Untuk sekarang, hanya copy file karena sudah dikompres saat pick
      // Di masa depan bisa tambahkan kompresi tambahan jika diperlukan
      await originalFile.copy(compressedPath);

      return File(compressedPath);
    } catch (e) {
      print('[IMAGE_PICKER] Error compressing image: $e');
      return originalFile; // Return original jika kompresi gagal
    }
  }
}
