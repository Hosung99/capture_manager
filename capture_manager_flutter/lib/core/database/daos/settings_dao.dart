import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/app_settings_table.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<AppSetting?> get() =>
      (select(appSettings)..where((t) => t.id.equals(1)))
          .getSingleOrNull();

  Stream<AppSetting?> watch() =>
      (select(appSettings)..where((t) => t.id.equals(1))).watchSingleOrNull();

  Future<void> upsert(AppSettingsCompanion entry) =>
      into(appSettings).insertOnConflictUpdate(
        entry.copyWith(id: const Value(1)),
      );
}
