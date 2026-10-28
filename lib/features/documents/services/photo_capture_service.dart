import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/local/secure_image_store.dart';
import 'date_ocr_service.dart';

/// A saved photo plus any expiry date read from it during capture.
class PhotoCaptureResult {
  const PhotoCaptureResult({required this.storedPath, this.suggestedExpiry});

  /// Encrypted file name inside the vault.
  final String storedPath;

  /// Latest future date detected in the photo, if any.
  final DateTime? suggestedExpiry;
}

/// Captures a document photo from the camera or gallery, runs the native cropper
/// (so users can straighten and trim ID edges), encrypts the result via
/// [SecureImageStore], and cleans up temporary unencrypted files.
class PhotoCaptureService {
  PhotoCaptureService({
    required SecureImageStore imageStore,
    ImagePicker? picker,
    ImageCropper? cropper,
    DateOcrService? dateOcr,
  })  : _imageStore = imageStore,
        _picker = picker ?? ImagePicker(),
        _cropper = cropper ?? ImageCropper(),
        _dateOcr = dateOcr ?? DateOcrService();

  final SecureImageStore _imageStore;
  final ImagePicker _picker;
  final ImageCropper _cropper;
  final DateOcrService _dateOcr;

  /// Picks, crops, reads an expiry date from, and encrypts a single photo.
  /// Returns `null` if the user cancelled at any step.
  Future<PhotoCaptureResult?> pickCropAndSave({
    required ImageSource source,
    Color? toolbarColor,
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 92,
      maxWidth: 2400,
      maxHeight: 2400,
    );
    if (picked == null) return null;

    final pickedFile = File(picked.path);
    File? croppedFile;
    try {
      final cropped = await _cropper.cropImage(
        sourcePath: picked.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop & Rotate Document',
            toolbarColor: toolbarColor ?? AppColors.seed,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: toolbarColor ?? AppColors.seed,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop & Rotate Document',
            aspectRatioLockEnabled: false,
          ),
        ],
      );
      if (cropped == null) {
        return null;
      }
      croppedFile = File(cropped.path);

      // Read the expiry date while the bytes are still plaintext; the file is
      // encrypted immediately afterwards and never written unencrypted again.
      final suggestedExpiry = await _dateOcr.suggestExpiryFromImage(croppedFile);
      final storedPath = await _imageStore.saveFile(
        croppedFile,
        deleteSource: true,
      );
      return PhotoCaptureResult(
        storedPath: storedPath,
        suggestedExpiry: suggestedExpiry,
      );
    } finally {
      try {
        if (await pickedFile.exists()) {
          await pickedFile.delete();
        }
      } catch (_) {}
      if (croppedFile != null) {
        try {
          if (await croppedFile.exists()) {
            await croppedFile.delete();
          }
        } catch (_) {}
      }
    }
  }
}
