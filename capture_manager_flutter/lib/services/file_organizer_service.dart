import 'dart:io';
import 'package:path/path.dart' as p;

import '../core/utils/file_conflict_resolver.dart';

class FileOrganizerError implements Exception {
  final String message;
  const FileOrganizerError(this.message);
  @override
  String toString() => message;
}

/// Port of FileOrganizer.swift using dart:io.
class FileOrganizerService {
  /// Creates the category subdirectory under [outputDir] if it does not exist.
  Future<String> ensureCategoryDirectory({
    required String outputDir,
    required String categoryName,
  }) async {
    final categoryDir = p.join(outputDir, categoryName);
    await Directory(categoryDir).create(recursive: true);
    return categoryDir;
  }

  /// Moves [sourcePath] into [categoryDir], returning the new path.
  Future<String> moveFile({
    required String sourcePath,
    required String categoryDir,
  }) async {
    if (!File(sourcePath).existsSync()) {
      throw const FileOrganizerError('Source file not found.');
    }

    final destination = resolveNameConflict(
      p.join(categoryDir, p.basename(sourcePath)),
    );

    try {
      await File(sourcePath).rename(destination);
      return destination;
    } on FileSystemException catch (e) {
      // rename fails across volumes; fall back to copy + delete
      try {
        await File(sourcePath).copy(destination);
        await File(sourcePath).delete();
        return destination;
      } on FileSystemException {
        throw FileOrganizerError('Failed to move file: ${e.message}');
      }
    }
  }

  /// Moves a previously classified file to a new category directory.
  Future<String> reclassifyFile({
    required String currentPath,
    required String outputDir,
    required String newCategoryName,
  }) async {
    final newCategoryDir = await ensureCategoryDirectory(
      outputDir: outputDir,
      categoryName: newCategoryName,
    );
    return moveFile(sourcePath: currentPath, categoryDir: newCategoryDir);
  }
}
