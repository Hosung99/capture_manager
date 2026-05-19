import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../core/constants/default_categories.dart';
import '../core/database/app_database.dart';
import '../core/database/daos/categories_dao.dart';
import '../core/database/daos/capture_items_dao.dart';
import '../core/database/daos/settings_dao.dart';
import '../core/database/tables/app_settings_table.dart' show AppSettingsCompanion;
import '../platform/platform_service_factory.dart';
import '../services/background_service.dart';
import '../services/capture_processor.dart';
import '../services/classification/classification_pipeline.dart';
import '../services/monitoring/screenshot_monitor.dart';
import 'database_provider.dart';

export 'database_provider.dart';

// ── Database DAOs ──────────────────────────────────────────────────────────

final categoriesDaoProvider = Provider<CategoriesDao>((ref) {
  return ref.watch(dbProvider).categoriesDao;
});

final captureItemsDaoProvider = Provider<CaptureItemsDao>((ref) {
  return ref.watch(dbProvider).captureItemsDao;
});

final settingsDaoProvider = Provider<SettingsDao>((ref) {
  return ref.watch(dbProvider).settingsDao;
});

// ── Reactive streams ───────────────────────────────────────────────────────

final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoriesDaoProvider).watchAll();
});

final recentCapturesProvider = StreamProvider((ref) {
  return ref.watch(captureItemsDaoProvider).watchRecent(limit: 20);
});

final settingsStreamProvider = StreamProvider<AppSetting?>((ref) {
  return ref.watch(settingsDaoProvider).watch();
});

// ── Services ───────────────────────────────────────────────────────────────

final ocrServiceProvider = Provider((ref) {
  return PlatformServiceFactory.createOcrService();
});

final classificationPipelineProvider = Provider((ref) {
  return ClassificationPipeline(ref.watch(ocrServiceProvider));
});

final captureProcessorProvider = Provider((ref) {
  return CaptureProcessor(
    db: ref.watch(dbProvider),
    pipeline: ref.watch(classificationPipelineProvider),
  );
});

final screenshotMonitorProvider = Provider<ScreenshotMonitor>((ref) {
  final monitor = PlatformServiceFactory.createScreenshotMonitor();
  ref.onDispose(monitor.stopMonitoring);
  return monitor;
});

// ── App initialisation ─────────────────────────────────────────────────────

final appInitProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(dbProvider);

  // Seed default categories on first launch
  final count = await db.categoriesDao.count();
  if (count == 0) {
    for (var i = 0; i < DefaultCategories.all.length; i++) {
      final def = DefaultCategories.all[i];
      await db.categoriesDao.insertCategory(
        CategoriesCompanion.insert(
          name: def.name,
          localizedName: def.localizedName,
          icon: def.icon,
          keywords: Value(def.keywords.join(',')),
          sortOrder: i,
          isDefault: const Value(true),
          directoryName: def.name,
          createdAt: DateTime.now(),
        ),
      );
    }

    final desktop = await _desktopPath();
    final outputDir = '$desktop${Platform.pathSeparator}CaptureManager';

    await db.settingsDao.upsert(
      AppSettingsCompanion(
        sourceDirectoryPath: Value(desktop),
        outputDirectoryPath: Value(outputDir),
        isMonitoringEnabled: const Value(true),
        hasCompletedSetup: const Value(false),
      ),
    );
  }

  final settings = await db.settingsDao.get();
  if (settings == null || !settings.isMonitoringEnabled) return;

  if (Platform.isAndroid) {
    // Android: foreground service handles monitoring in the background isolate
    BackgroundService.init();
    await BackgroundService.start();
  } else {
    // macOS: monitor directly in the main isolate
    final monitor = ref.read(screenshotMonitorProvider);
    final processor = ref.read(captureProcessorProvider);
    monitor.startMonitoring(settings.sourceDirectoryPath);
    monitor.screenshotPaths.listen((path) async {
      await processor.process(path);
    });
  }
});

// Called from app.dart to wire up background→main isolate messages on Android
void registerBackgroundDataCallback(WidgetRef ref) {
  if (!Platform.isAndroid) return;

  void callback(Object data) {
    if (data is Map && data['type'] == 'new_capture') {
      // Background isolate wrote a new row — invalidate the stream so UI updates
      ref.invalidate(recentCapturesProvider);
    }
  }

  BackgroundService.addDataCallback(callback);
}

Future<String> _desktopPath() async {
  if (Platform.isMacOS) {
    final home = Platform.environment['HOME'] ?? '';
    return '$home/Desktop';
  }
  final dir = await getExternalStorageDirectory();
  return dir?.path ?? '/storage/emulated/0';
}
