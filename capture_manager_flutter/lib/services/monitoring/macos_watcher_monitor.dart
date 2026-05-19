import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import '../../core/constants/app_constants.dart';
import 'screenshot_monitor.dart';

/// macOS: monitors a directory for new screenshots using FSEvents (via watcher package).
/// Port of ScreenshotMonitor.swift — same debounce and filename pattern logic.
class MacOsWatcherMonitor implements ScreenshotMonitor {
  static final List<RegExp> _patterns = AppConstants.screenshotPatterns
      .map((s) => RegExp(s))
      .toList();

  final _controller = StreamController<String>.broadcast();
  StreamSubscription<WatchEvent>? _subscription;
  DirectoryWatcher? _watcher;
  Timer? _debounceTimer;
  bool _isMonitoring = false;

  @override
  Stream<String> get screenshotPaths => _controller.stream;

  @override
  bool get isMonitoring => _isMonitoring;

  @override
  void startMonitoring(String directoryPath) {
    stopMonitoring();

    _watcher = DirectoryWatcher(directoryPath);
    _subscription = _watcher!.events.listen((event) {
      if (event.type == ChangeType.ADD) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(
          AppConstants.fileEventDebounceInterval,
          () => _handleNewFile(event.path),
        );
      }
    });
    _isMonitoring = true;
  }

  @override
  void stopMonitoring() {
    _debounceTimer?.cancel();
    _subscription?.cancel();
    _watcher = null;
    _isMonitoring = false;
  }

  void _handleNewFile(String filePath) {
    final ext = p.extension(filePath).toLowerCase().replaceFirst('.', '');
    if (!AppConstants.screenshotExtensions.contains(ext)) return;

    final name = p.basenameWithoutExtension(filePath);
    final isScreenshot = _patterns.any((re) => re.hasMatch(name));
    if (!isScreenshot) return;

    if (!File(filePath).existsSync()) return;

    _controller.add(filePath);
  }

  void dispose() {
    stopMonitoring();
    _controller.close();
  }
}
