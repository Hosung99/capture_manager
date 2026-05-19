import 'package:drift/drift.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get localizedName => text()();
  TextColumn get icon => text()();
  // Stored as comma-joined string; DAO handles split/join
  TextColumn get keywords => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  TextColumn get directoryName => text()();
  DateTimeColumn get createdAt => dateTime()();
}
