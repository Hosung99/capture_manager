import 'dart:io';

import '../services/monitoring/android_mediastore_monitor.dart';
import '../services/monitoring/macos_watcher_monitor.dart';
import '../services/monitoring/screenshot_monitor.dart';
import '../services/ocr/mlkit_ocr_service.dart';
import '../services/ocr/ocr_service.dart';
import '../services/ocr/vision_ocr_service.dart';

class PlatformServiceFactory {
  static OcrService createOcrService() {
    if (Platform.isMacOS) return VisionOcrService();
    return MlKitOcrService();
  }

  static ScreenshotMonitor createScreenshotMonitor() {
    if (Platform.isMacOS) return MacOsWatcherMonitor();
    return AndroidMediastoreMonitor();
  }
}
