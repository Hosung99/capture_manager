abstract interface class OcrService {
  Future<String> recognizeText(String filePath);

  void dispose() {}
}
