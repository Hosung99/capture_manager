import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/capture_items_table.dart';

part 'capture_items_dao.g.dart';

@DriftAccessor(tables: [CaptureItems])
class CaptureItemsDao extends DatabaseAccessor<AppDatabase>
    with _$CaptureItemsDaoMixin {
  CaptureItemsDao(super.db);

  Stream<List<CaptureItem>> watchRecent({int limit = 20}) =>
      (select(captureItems)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .watch();

  Stream<List<CaptureItem>> watchByCategory(int categoryId) =>
      (select(captureItems)
            ..where((t) => t.categoryId.equals(categoryId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Stream<List<CaptureItem>> watchAll() =>
      (select(captureItems)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<void> insertItem(CaptureItemsCompanion entry) =>
      into(captureItems).insert(entry);

  Future<void> updateItem(CaptureItemsCompanion entry) =>
      (update(captureItems)..where((t) => t.id.equals(entry.id.value)))
          .write(entry);

  Future<void> deleteItem(int id) =>
      (delete(captureItems)..where((t) => t.id.equals(id))).go();
}
