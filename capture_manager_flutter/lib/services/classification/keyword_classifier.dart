import 'dart:math';

import 'classification_result.dart';

/// Port of VisionClassifier.swift keyword scoring algorithm.
/// Scoring formula is identical — do not change coefficients.
class KeywordClassifier {
  ClassificationResult classify({
    required String ocrText,
    required List<({String name, List<String> keywords})> categories,
  }) {
    if (ocrText.isEmpty) {
      return const ClassificationResult(
        categoryName: 'Other',
        confidence: 0.1,
        ocrText: '',
      );
    }

    final lowerText = ocrText.toLowerCase();
    var bestCategory = 'Other';
    var bestScore = 0.0;

    for (final category in categories) {
      if (category.keywords.isEmpty) continue;

      var matchCount = 0;
      for (final keyword in category.keywords) {
        if (lowerText.contains(keyword.toLowerCase())) matchCount++;
      }

      if (matchCount == 0) continue;

      final ratio = matchCount / category.keywords.length;
      final countBonus = min(matchCount * 0.1, 0.3);
      final score = min(ratio + countBonus, 1.0);

      if (score > bestScore) {
        bestScore = score;
        bestCategory = category.name;
      }
    }

    final confidence = bestScore > 0 ? min(bestScore * 1.5, 1.0) : 0.1;
    final truncatedText = ocrText.substring(0, min(2000, ocrText.length));

    return ClassificationResult(
      categoryName: bestCategory,
      confidence: confidence,
      ocrText: truncatedText,
    );
  }
}
