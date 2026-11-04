import 'dart:io';

import 'package:drift/native.dart';
import 'package:druide_and_droiid/core/persistence/app_database.dart';
import 'package:druide_and_droiid/features/notes/data/notes_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Schéma exact de la version 1, livrée aux phases 1 et 2.
const _schemaV1 =
    'CREATE TABLE IF NOT EXISTS "app_meta" ("key" TEXT NOT NULL, '
    '"value" TEXT NOT NULL, PRIMARY KEY ("key"));';

Map<String, String> schemaOf(String path) {
  final database = sqlite3.open(path);
  final rows = database.select(
    "SELECT name, sql FROM sqlite_master "
    "WHERE sql IS NOT NULL AND name NOT LIKE 'sqlite_%'",
  );
  final schema = {
    for (final row in rows) row['name'] as String: row['sql'] as String,
  };
  database.close();
  return schema;
}

void main() {
  late Directory directory;
  late File file;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('druide_migration');
    file = File(p.join(directory.path, 'base.sqlite'));
  });
  tearDown(() => directory.deleteSync(recursive: true));

  void createV1Database() {
    final database = sqlite3.open(file.path);
    database
      ..execute(_schemaV1)
      ..execute(
        "INSERT INTO app_meta VALUES ('appearance.theme', 'light'), "
        "('appearance.motion', 'reduced')",
      )
      ..execute('PRAGMA user_version = 1');
    database.close();
  }

  test('la version 1 passe en version 2 sans perdre les réglages', () async {
    createV1Database();

    final database = AppDatabase(NativeDatabase(file));
    expect(await database.readMeta('appearance.theme'), 'light');
    expect(await database.readMeta('appearance.motion'), 'reduced');

    final id = await NotesRepository(
      database,
      DateTime.now,
    ).create(title: 'Après migration', body: '');
    expect(id, greaterThan(0));
    await database.close();

    final raw = sqlite3.open(file.path);
    expect(raw.select('PRAGMA user_version').first.values.first, 2);
    raw.close();
  });

  test('une base migrée a le même schéma qu\'une base neuve', () async {
    createV1Database();
    final migrated = AppDatabase(NativeDatabase(file));
    await migrated.readMeta('x');
    await migrated.close();

    final freshFile = File(p.join(directory.path, 'neuve.sqlite'));
    final fresh = AppDatabase(NativeDatabase(freshFile));
    await fresh.readMeta('x');
    await fresh.close();

    expect(schemaOf(file.path), schemaOf(freshFile.path));
  });

  test('rouvrir une base à jour ne modifie rien', () async {
    final first = AppDatabase(NativeDatabase(file));
    await first.writeMeta('clé', 'valeur');
    await first.close();

    final second = AppDatabase(NativeDatabase(file));
    expect(await second.readMeta('clé'), 'valeur');
    await second.close();
  });
}
