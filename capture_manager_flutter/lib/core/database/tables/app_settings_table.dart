import 'package:drift/drift.dart';

class AppSettings extends Table {
  // Singleton row — always id = 1
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get sourceDirectoryPath => text().withDefault(const Constant(''))();
  TextColumn get outputDirectoryPath => text().withDefault(const Constant(''))();
  BoolColumn get autoMoveEnabled =>
      boolean().withDefault(const Constant(true))();
  RealColumn get confidenceThreshold =>
      real().withDefault(const Constant(0.6))();
  BoolColumn get launchAtLogin =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isMonitoringEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get hasCompletedSetup =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
