import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../core/constants/default_categories.dart';
import '../core/database/app_database.dart';
import '../core/database/daos/categories_dao.dart';
import '../core/database/tables/capture_items_table.dart' show CaptureItemsCompanion;
import 'classification/classification_pipeline.dart';
import 'file_organizer_service.dart';
import 'monitoring/android_mediastore_monitor.dart';
import 'ocr/mlkit_ocr_service.dart';

/// Runs in the Android ForegroundService background isolate.
/// Opens its own AppDatabase connection (SQLite WAL allows concurrent access).
class CaptureTaskHandler extends TaskHandler {
  AppDatabase? _db;
  AndroidMediastoreMonitor? _monitor;
  MlKitOcrService? _ocrService;
  ClassificationPipeline? _pipeline;
  StreamSubscription<String>? _sub;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _db = AppDatabase();
    _ocrService = MlKitOcrService();
    _pipeline = ClassificationPipeline(_ocrService!);

    await _seedIfNeeded();

    final settings = await _db!.settingsDao.get();
    _monitor = AndroidMediastoreMonitor()
      ..startMonitoring(settings?.sourceDirectoryPath ?? '');
    _sub = _monitor!.screenshotPaths.listen(_processScreenshot);

    _notify('스크린샷 모니터링 중');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _sub?.cancel();
    _monitor?.stopMonitoring();
    _ocrService?.dispose();
    await _db?.close();
  }

  @override
  void onReceiveData(Object data) {
    if (data is! Map) return;
    final cmd = data['cmd'] as String?;
    switch (cmd) {
      case 'stop':
        _monitor?.stopMonitoring();
      case 'updateSourcePath':
        final path = data['path'] as String?;
        if (path != null) {
          _monitor?.stopMonitoring();
          _monitor?.startMonitoring(path);
        }
    }
  }

  Future<void> _processScreenshot(String filePath) async {
    final db = _db;
    final pipeline = _pipeline;
    if (db == null || pipeline == null) return;

    try {
      final categories = await db.categoriesDao.getAll();
      final settings = await db.settingsDao.get();
      if (settings == null) return;

      final categoryTuples = categories
          .map((c) => (name: c.name, keywords: c.keywordList))
          .toList();

      final result = await pipeline.classify(
        filePath: filePath,
        categories: categoryTuples,
        confidenceThreshold: settings.confidenceThreshold,
      );

      final matchedCategory =
          categories.where((c) => c.name == result.categoryName).firstOrNull;

      var currentPath = filePath;
      var isMoved = false;

      if (settings.autoMoveEnabled &&
          result.confidence >= settings.confidenceThreshold) {
        try {
          final organizer = FileOrganizerService();
          final categoryDir = await organizer.ensureCategoryDirectory(
            outputDir: settings.outputDirectoryPath,
            categoryName: result.categoryName,
          );
          currentPath = await organizer.moveFile(
            sourcePath: filePath,
            categoryDir: categoryDir,
          );
          isMoved = true;
        } catch (_) {}
      }

      await db.captureItemsDao.insertItem(
        CaptureItemsCompanion.insert(
          originalPath: filePath,
          currentPath: currentPath,
          fileName: filePath.split('/').last,
          categoryId: drift.Value(matchedCategory?.id),
          confidenceScore: drift.Value(result.confidence),
          ocrText: drift.Value(
              result.ocrText.isNotEmpty ? result.ocrText : null),
          fileSize: drift.Value(_fileSize(filePath)),
          classifiedAt: drift.Value(DateTime.now()),
          createdAt: DateTime.now(),
          isMoved: drift.Value(isMoved),
        ),
      );

      // Signal the main UI isolate to refresh its capture list
      FlutterForegroundTask.sendDataToMain({
        'type': 'new_capture',
        'fileName': filePath.split('/').last,
        'category': result.categoryName,
      });

      _notify('새 캡처: ${filePath.split('/').last}');
    } catch (_) {}
  }

  Future<void> _seedIfNeeded() async {
    final db = _db!;
    if (await db.categoriesDao.count() > 0) return;

    for (var i = 0; i < DefaultCategories.all.length; i++) {
      final def = DefaultCategories.all[i];
      await db.categoriesDao.insertCategory(
        CategoriesCompanion.insert(
          name: def.name,
          localizedName: def.localizedName,
          icon: def.icon,
          keywords: drift.Value(def.keywords.join(',')),
          sortOrder: i,
          isDefault: const drift.Value(true),
          directoryName: def.name,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  void _notify(String text) {
    FlutterForegroundTask.updateService(
      notificationTitle: 'CaptureManager',
      notificationText: text,
    );
  }

  int _fileSize(String path) {
    try {
      return File(path).statSync().size;
    } catch (_) {
      return 0;
    }
  }
}
