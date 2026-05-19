import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Requests Android runtime permissions needed for screenshot monitoring.
/// No-op on non-Android platforms.
class AppPermissionHandler {
  static Future<void> requestAll(BuildContext context) async {
    if (!Platform.isAndroid) return;

    // POST_NOTIFICATIONS (Android 13+)
    final notifStatus =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notifStatus != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    // READ_MEDIA_IMAGES is a normal permission on API 33+ — handled by OS
    // READ_EXTERNAL_STORAGE on API <= 32 — also handled by OS on first access
    // For MANAGE_EXTERNAL_STORAGE on API 30+ show rationale if needed
  }
}
