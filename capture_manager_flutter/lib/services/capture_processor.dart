import 'dart:io';

import 'package:drift/drift.dart';

import '../core/database/app_database.dart';
import '../core/database/daos/categories_dao.dart';
import '../core/utils/thumbnail_utils.dart';
import 'classification/classification_pipeline.dart';
import 'file_organizer_service.dart';

/// Port of MenuBarViewModel.processScreenshot.
/// Orchestrates: OCR → classify → thumbnail → optional move → DB insert.
class CaptureProcessor {
  final AppDatabase _db;
  final ClassificationPipeline _pipeline;
  final FileOrganizerService _organizer = FileOrganizerService();

  CaptureProcessor({
    required AppDatabase db,
    required ClassificationPipeline pipeline,
  })  : _db = db,
        _pipeline = pipeline;

  Future<void> process(String filePath) async {
    final categories = await _db.categoriesDao.getAll();
    final settings = await _db.settingsDao.get();
    if (settings == null) return;

    final categoryTuples = categories
        .map((c) => (name: c.name, keywords: c.keywordList))
        .toList();

    final result = await _pipeline.classify(
      filePath: filePath,
      categories: categoryTuples,
      confidenceThreshold: settings.confidenceThreshold,
    );

    final thumbnailData = await generateThumbnail(filePath);

    final fileSize = () {
      try {
        return File(filePath).statSync().size;
      } catch (_) {
        return 0;
      }
    }();

    final matchedCategory = categories
        .where((c) => c.name == result.categoryName)
        .firstOrNull;

    var currentPath = filePath;
    var isMoved = false;

    if (settings.autoMoveEnabled &&
        result.confidence >= settings.confidenceThreshold) {
      try {
        final categoryDir = await _organizer.ensureCategoryDirectory(
          outputDir: settings.outputDirectoryPath,
          categoryName: result.categoryName,
        );
        currentPath = await _organizer.moveFile(
          sourcePath: filePath,
          categoryDir: categoryDir,
        );
        isMoved = true;
      } catch (e) {
        // File move failed; keep original path
      }
    }

    final entry = CaptureItemsCompanion.insert(
      originalPath: filePath,
      currentPath: currentPath,
      fileName: filePath.split('/').last,
      categoryId: Value(matchedCategory?.id),
      confidenceScore: Value(result.confidence),
      ocrText: Value(result.ocrText.isNotEmpty ? result.ocrText : null),
      thumbnailData: Value(thumbnailData),
      fileSize: Value(fileSize),
      classifiedAt: Value(DateTime.now()),
      createdAt: DateTime.now(),
      isMoved: Value(isMoved),
    );

    await _db.captureItemsDao.insertItem(entry);
  }
}
