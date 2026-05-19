import 'package:drift/drift.dart';

import 'categories_table.dart';

class CaptureItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get originalPath => text()();
  TextColumn get currentPath => text()();
  TextColumn get fileName => text()();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  RealColumn get confidenceScore =>
      real().withDefault(const Constant(0.0))();
  TextColumn get ocrText => text().nullable()();
  BlobColumn get thumbnailData => blob().nullable()();
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  DateTimeColumn get classifiedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isMoved => boolean().withDefault(const Constant(false))();
}
