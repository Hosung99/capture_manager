import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'ocr_service.dart';

/// Android: uses Google ML Kit Text Recognition.
/// Two recognizers are used (Latin + Korean) and their results are merged
/// to match Apple Vision's multi-language quality on Korean screenshots.
class MlKitOcrService implements OcrService {
  final _latinRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  final _koreanRecognizer =
      TextRecognizer(script: TextRecognitionScript.korean);

  @override
  Future<String> recognizeText(String filePath) async {
    final inputImage = InputImage.fromFilePath(filePath);

    final results = await Future.wait([
      _latinRecognizer.processImage(inputImage),
      _koreanRecognizer.processImage(inputImage),
    ]);

    final latinText =
        results[0].blocks.map((b) => b.text).join('\n');
    final koreanText =
        results[1].blocks.map((b) => b.text).join('\n');

    // Merge: prefer whichever recognizer produced more text
    if (koreanText.length > latinText.length) {
      return '$koreanText\n$latinText';
    }
    return '$latinText\n$koreanText';
  }

  @override
  void dispose() {
    _latinRecognizer.close();
    _koreanRecognizer.close();
  }
}
