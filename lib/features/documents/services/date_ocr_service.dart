import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'expiry_date_parser.dart';

/// Reads a captured photo with on-device ML Kit text recognition and suggests
/// an expiry date. Fully offline: the recognition model ships inside the APK.
///
/// OCR is best-effort — any failure returns `null` so saving a photo never
/// breaks because a device lacks the model or the text is unreadable.
class DateOcrService {
  DateOcrService({TextRecognizer? recognizer})
      : _recognizer = recognizer ??
            TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  /// Returns the latest future date found in [image], or `null`.
  Future<DateTime?> suggestExpiryFromImage(File image) async {
    try {
      final result = await _recognizer.processImage(
        InputImage.fromFilePath(image.path),
      );
      final text = result.text;
      if (text.isEmpty) return null;
      return suggestExpiryDate(text);
    } catch (_) {
      // Best-effort only: an unreadable photo must not block the capture flow.
      return null;
    }
  }

  Future<void> close() => _recognizer.close();
}
