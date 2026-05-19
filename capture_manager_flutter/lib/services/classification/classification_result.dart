class ClassificationResult {
  final String categoryName;
  final double confidence;
  final String ocrText;

  const ClassificationResult({
    required this.categoryName,
    required this.confidence,
    required this.ocrText,
  });
}
