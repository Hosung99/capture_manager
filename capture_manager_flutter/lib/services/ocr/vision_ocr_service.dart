import 'package:flutter/services.dart';

import 'ocr_service.dart';

/// macOS: delegates OCR to Apple Vision.framework via MethodChannel.
/// The native counterpart is VisionOCRPlugin.swift in macos/Runner/.
class VisionOcrService implements OcrService {
  static const _channel = MethodChannel('com.capturemanager/ocr');

  @override
  Future<String> recognizeText(String filePath) async {
    try {
      final result = await _channel.invokeMethod<String>(
        'recognizeText',
        {'filePath': filePath},
      );
      return result ?? '';
    } on PlatformException {
      return '';
    }
  }

  @override
  void dispose() {}
}
