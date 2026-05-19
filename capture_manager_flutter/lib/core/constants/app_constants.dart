class AppConstants {
  static const String appName = 'CaptureManager';
  static const String defaultOutputDirectoryName = 'CaptureManager';

  static const List<String> screenshotPatterns = [
    r'^Screenshot \d{4}-\d{2}-\d{2} at \d+\.\d+\.\d+',
    r'^스크린샷 \d{4}-\d{2}-\d{2} \d+\.\d+\.\d+',
    r'^Screen Shot \d{4}-\d{2}-\d{2} at \d+\.\d+\.\d+',
    r'^CleanShot',
  ];

  static const Duration fileEventDebounceInterval = Duration(milliseconds: 500);
  static const double thumbnailMaxDimension = 200;
  static const double defaultConfidenceThreshold = 0.6;

  static const List<String> screenshotExtensions = [
    'png', 'jpg', 'jpeg', 'tiff', 'heic',
  ];
}
