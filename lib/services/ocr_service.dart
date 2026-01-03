import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class FDATextExtractor {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extract FDA number from image file
  Future<String?> extractFDANumber(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      return _findFDANumber(recognizedText.text);
    } catch (e) {
      await Sentry.captureException(e);
      return null;
    }
  }

  /// Extract FDA number from camera image
  Future<String?> extractFDANumberFromCamera(InputImage inputImage) async {
    try {
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      return _findFDANumber(recognizedText.text);
    } catch (e) {
      await Sentry.captureException(e);
      return null;
    }
  }

  /// Search for FDA/ pattern and extract the following alphanumeric sequence
  String? _findFDANumber(String text) {
    // Pattern to match FDA/ followed by alphanumeric characters
    // This handles various formats like FDA/123456, FDA/ABC123, etc.
    final RegExp fdaPattern = RegExp(
      r'FDA/([A-Za-z0-9]+)',
      caseSensitive: false,
    );

    final match = fdaPattern.firstMatch(text);

    if (match != null && match.groupCount >= 1) {
      return match.group(1); // Returns the alphanumeric part after FDA/
    }

    return null;
  }

  /// Dispose the text recognizer
  void dispose() {
    _textRecognizer.close();
  }
}