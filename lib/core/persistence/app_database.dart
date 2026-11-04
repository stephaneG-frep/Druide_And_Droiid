import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

/// Paires clé/valeur techniques ; les tables métier arrivent en phase 3.
class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [AppMeta])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  Future<void> writeMeta(String key, String value) {
    return into(
      appMeta,
    ).insertOnConflictUpdate(AppMetaCompanion.insert(key: key, value: value));
  }

  Future<String?> readMeta(String key) async {
    final query = select(appMeta)..where((row) => row.key.equals(key));
    return (await query.getSingleOrNull())?.value;
  }
}

const databaseName = 'druide_and_droiid';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(driftDatabase(name: databaseName));
  ref.onDispose(database.close);
  return database;
});
