abstract interface class ScreenshotMonitor {
  Stream<String> get screenshotPaths;

  void startMonitoring(String directoryPath);

  void stopMonitoring();

  bool get isMonitoring;
}
