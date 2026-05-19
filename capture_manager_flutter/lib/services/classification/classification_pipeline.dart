import '../ocr/ocr_service.dart';
import 'classification_result.dart';
import 'keyword_classifier.dart';

/// Port of AIClassifier.swift.
/// Stage 1: OCR via injected OcrService → keyword heuristic via KeywordClassifier.
/// Stage 2 (v2 TODO): GPT-4o-mini fallback when confidence < threshold.
class ClassificationPipeline {
  final OcrService _ocrService;
  final KeywordClassifier _keywordClassifier = KeywordClassifier();

  ClassificationPipeline(this._ocrService);

  Future<ClassificationResult> classify({
    required String filePath,
    required List<({String name, List<String> keywords})> categories,
    double confidenceThreshold = 0.6,
  }) async {
    final ocrText = await _ocrService.recognizeText(filePath);
    // v2 TODO: if result.confidence < confidenceThreshold, call GPT-4o-mini fallback
    return _keywordClassifier.classify(ocrText: ocrText, categories: categories);
  }
}
