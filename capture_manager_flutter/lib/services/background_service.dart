import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'capture_task_handler.dart';

/// Manages the Android foreground service lifecycle.
/// All methods are no-ops on non-Android platforms.
class BackgroundService {
  static bool get _isAndroid => Platform.isAndroid;

  static void init() {
    if (!_isAndroid) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'capture_manager_monitoring',
        channelName: 'Screenshot Monitoring',
        channelDescription: '스크린샷을 감지하고 자동으로 분류합니다.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        showWhen: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: true,
        allowWakeLock: false,
      ),
    );
  }

  static Future<void> start() async {
    if (!_isAndroid) return;
    await FlutterForegroundTask.startService(
      serviceId: 1001,
      notificationTitle: 'CaptureManager',
      notificationText: '스크린샷 모니터링 중',
      callback: _backgroundEntryPoint,
    );
  }

  static Future<void> stop() async {
    if (!_isAndroid) return;
    await FlutterForegroundTask.stopService();
  }

  static Future<bool> get isRunning async {
    if (!_isAndroid) return false;
    return FlutterForegroundTask.isRunningService;
  }

  static void addDataCallback(DataCallback callback) {
    if (!_isAndroid) return;
    FlutterForegroundTask.addTaskDataCallback(callback);
  }

  static void removeDataCallback(DataCallback callback) {
    if (!_isAndroid) return;
    FlutterForegroundTask.removeTaskDataCallback(callback);
  }
}

@pragma('vm:entry-point')
void _backgroundEntryPoint() {
  FlutterForegroundTask.setTaskHandler(CaptureTaskHandler());
}
