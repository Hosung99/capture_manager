import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/categories_table.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  Stream<List<Category>> watchAll() =>
      (select(categories)..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
          .watch();

  Future<List<Category>> getAll() =>
      (select(categories)..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
          .get();

  Future<int> count() => categories.count().getSingle();

  Future<void> insertCategory(CategoriesCompanion entry) =>
      into(categories).insert(entry);

  Future<void> updateCategory(CategoriesCompanion entry) =>
      (update(categories)..where((t) => t.id.equals(entry.id.value)))
          .write(entry);

  Future<void> deleteCategory(int id) =>
      (delete(categories)..where((t) => t.id.equals(id))).go();
}

// Keywords are stored as comma-joined strings. These helpers handle conversion.
extension CategoryKeywords on Category {
  List<String> get keywordList =>
      keywords.isEmpty ? [] : keywords.split(',');
}

extension CategoriesCompanionKeywords on CategoriesCompanion {
  static CategoriesCompanion fromKeywordList(
    CategoriesCompanion base,
    List<String> keywords,
  ) =>
      base.copyWith(keywords: Value(keywords.join(',')));
}
