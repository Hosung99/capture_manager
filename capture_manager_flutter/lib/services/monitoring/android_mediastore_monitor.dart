import 'dart:async';
import 'package:flutter/services.dart';

import 'screenshot_monitor.dart';

/// Android: receives new screenshot paths from a native ContentObserver
/// watching MediaStore.Images.Media via an EventChannel.
/// The native counterpart is ScreenshotObserverPlugin.kt.
class AndroidMediastoreMonitor implements ScreenshotMonitor {
  static const _eventChannel =
      EventChannel('com.capturemanager/screenshot_stream');

  final _controller = StreamController<String>.broadcast();
  StreamSubscription? _subscription;
  bool _isMonitoring = false;

  @override
  Stream<String> get screenshotPaths => _controller.stream;

  @override
  bool get isMonitoring => _isMonitoring;

  @override
  void startMonitoring(String directoryPath) {
    // directoryPath is ignored on Android — MediaStore monitors system-wide
    stopMonitoring();
    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (path) {
        if (path is String && path.isNotEmpty) _controller.add(path);
      },
      onError: (_) {},
    );
    _isMonitoring = true;
  }

  @override
  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
    _isMonitoring = false;
  }

  void dispose() {
    stopMonitoring();
    _controller.close();
  }
}
