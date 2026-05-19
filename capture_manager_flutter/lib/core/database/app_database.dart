import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/app_settings_table.dart';
import 'tables/capture_items_table.dart';
import 'tables/categories_table.dart';
import 'daos/categories_dao.dart';
import 'daos/capture_items_dao.dart';
import 'daos/settings_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Categories, CaptureItems, AppSettings],
  daos: [CategoriesDao, CaptureItemsDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
      );
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'capture_manager');
}
