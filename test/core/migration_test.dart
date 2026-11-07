import 'dart:io';

import 'package:drift/native.dart';
import 'package:druide_and_droiid/core/persistence/app_database.dart';
import 'package:druide_and_droiid/features/notes/data/notes_repository.dart';
import 'package:druide_and_droiid/features/progression/data/progress_repository.dart';
import 'package:druide_and_droiid/features/projets/data/project_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Schéma exact de la version 1, livrée aux phases 1 et 2.
const _schemaV1 =
    'CREATE TABLE IF NOT EXISTS "app_meta" ("key" TEXT NOT NULL, '
    '"value" TEXT NOT NULL, PRIMARY KEY ("key"));';

/// Schéma exact de la version 2, livrée à la phase 3.
const _schemaV2 = [
  'CREATE TABLE "app_meta" ("key" TEXT NOT NULL, "value" TEXT NOT NULL, '
      'PRIMARY KEY ("key"))',
  'CREATE TABLE "lesson_progress" ("lesson_id" TEXT NOT NULL, "module_id" TEXT '
      'NOT NULL, "completed_at" INTEGER NOT NULL, PRIMARY KEY ("lesson_id"))',
  'CREATE TABLE "quiz_attempts" ("id" INTEGER NOT NULL PRIMARY KEY '
      'AUTOINCREMENT, "quiz_id" TEXT NOT NULL, "score" INTEGER NOT NULL, '
      '"max_score" INTEGER NOT NULL, "passed" INTEGER NOT NULL CHECK ("passed" '
      'IN (0, 1)), "attempted_at" INTEGER NOT NULL)',
  'CREATE TABLE "xp_events" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"source" TEXT NOT NULL UNIQUE, "amount" INTEGER NOT NULL, "earned_at" '
      'INTEGER NOT NULL)',
  'CREATE TABLE "notes" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"title" TEXT NOT NULL, "body" TEXT NOT NULL, "module_id" TEXT NULL, '
      '"created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL)',
  'CREATE TABLE "favorites" ("kind" TEXT NOT NULL, "target_id" TEXT NOT NULL, '
      '"created_at" INTEGER NOT NULL, PRIMARY KEY ("kind", "target_id"))',
];

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

  test('la version 1 passe à la dernière version sans perte', () async {
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
    expect(
      raw.select('PRAGMA user_version').first.values.first,
      database.schemaVersion,
    );
    raw.close();
  });

  void createV2Database() {
    final database = sqlite3.open(file.path);
    _schemaV2.forEach(database.execute);
    database
      ..execute("INSERT INTO app_meta VALUES ('appearance.theme', 'light')")
      ..execute(
        "INSERT INTO notes (title, body, created_at, updated_at) "
        "VALUES ('Ma note', 'Corps', 1, 1)",
      )
      ..execute("INSERT INTO lesson_progress VALUES ('leçon', 'kotlin', 1)")
      ..execute(
        "INSERT INTO quiz_attempts (quiz_id, score, max_score, passed, "
        "attempted_at) VALUES ('quiz', 1, 1, 1, 1)",
      )
      ..execute(
        "INSERT INTO xp_events (source, amount, earned_at) "
        "VALUES ('quiz:quiz', 10, 1)",
      )
      ..execute('PRAGMA user_version = 2');
    database.close();
  }

  test('la version 6 passe en version 7 sans perte', () async {
    createV2Database();
    final raw = sqlite3.open(file.path);
    raw
      ..execute(
        'CREATE TABLE "exercise_answers" ("exercise_id" TEXT NOT NULL, '
        '"module_id" TEXT NOT NULL, "answer" TEXT NOT NULL, "status" TEXT NOT '
        'NULL, "updated_at" INTEGER NOT NULL, PRIMARY KEY ("exercise_id"))',
      )
      ..execute(
        'CREATE TABLE "ai_conversations" ("id" INTEGER NOT NULL PRIMARY KEY '
        'AUTOINCREMENT, "title" TEXT NOT NULL, "provider_kind" TEXT NOT NULL, '
        '"model" TEXT NOT NULL, "mode" TEXT NOT NULL, "created_at" INTEGER NOT '
        'NULL, "updated_at" INTEGER NOT NULL)',
      )
      ..execute(
        'CREATE TABLE "ai_messages" ("id" INTEGER NOT NULL PRIMARY KEY '
        'AUTOINCREMENT, "conversation_id" INTEGER NOT NULL REFERENCES '
        'ai_conversations (id), "role" TEXT NOT NULL, "content" TEXT NOT NULL, '
        '"input_tokens" INTEGER NULL, "output_tokens" INTEGER NULL, '
        '"stop_reason" TEXT NULL, "created_at" INTEGER NOT NULL)',
      )
      ..execute(
        'CREATE TABLE "lab_drafts" ("exercise_id" TEXT NOT NULL, "code" TEXT '
        'NOT NULL, "solved" INTEGER NOT NULL DEFAULT 0 CHECK ("solved" IN (0, '
        '1)), "updated_at" INTEGER NOT NULL, PRIMARY KEY ("exercise_id"))',
      )
      ..execute(
        'CREATE TABLE "lab_revisions" ("id" INTEGER NOT NULL PRIMARY KEY '
        'AUTOINCREMENT, "exercise_id" TEXT NOT NULL, "code" TEXT NOT NULL, '
        '"label" TEXT NOT NULL, "created_at" INTEGER NOT NULL)',
      )
      ..execute(
        'CREATE TABLE "bug_cases" ("id" INTEGER NOT NULL PRIMARY KEY '
        'AUTOINCREMENT, "title" TEXT NOT NULL, "error_text" TEXT NOT NULL, '
        '"description" TEXT NOT NULL, "code" TEXT NOT NULL, "conversation_id" '
        'INTEGER NULL, "status" TEXT NOT NULL, "verification" TEXT NULL, '
        '"created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL)',
      )
      ..execute(
        "INSERT INTO bug_cases (title, error_text, description, code, status, "
        "created_at, updated_at) VALUES ('Dossier', 'e', '', '', 'open', 1, 1)",
      )
      ..execute('PRAGMA user_version = 6');
    raw.close();

    final database = AppDatabase(NativeDatabase(file));
    final cases = await database.select(database.bugCases).get();
    expect(cases.single.title, 'Dossier');

    await ProjectRepository(
      database,
      DateTime.now,
    ).toggleStep('calculatrice', 0);
    final rows = await database.select(database.projectProgress).get();
    expect(rows.single.doneSteps, '[0]');
    await database.close();
  });

  test('la version 5 passe en version 6 sans perte', () async {
    createV2Database();
    final raw = sqlite3.open(file.path);
    raw
      ..execute(
        'CREATE TABLE "exercise_answers" ("exercise_id" TEXT NOT NULL, '
        '"module_id" TEXT NOT NULL, "answer" TEXT NOT NULL, "status" TEXT NOT '
        'NULL, "updated_at" INTEGER NOT NULL, PRIMARY KEY ("exercise_id"))',
      )
      ..execute(
        'CREATE TABLE "ai_conversations" ("id" INTEGER NOT NULL PRIMARY KEY '
        'AUTOINCREMENT, "title" TEXT NOT NULL, "provider_kind" TEXT NOT NULL, '
        '"model" TEXT NOT NULL, "mode" TEXT NOT NULL, "created_at" INTEGER NOT '
        'NULL, "updated_at" INTEGER NOT NULL)',
      )
      ..execute(
        'CREATE TABLE "ai_messages" ("id" INTEGER NOT NULL PRIMARY KEY '
        'AUTOINCREMENT, "conversation_id" INTEGER NOT NULL REFERENCES '
        'ai_conversations (id), "role" TEXT NOT NULL, "content" TEXT NOT NULL, '
        '"input_tokens" INTEGER NULL, "output_tokens" INTEGER NULL, '
        '"stop_reason" TEXT NULL, "created_at" INTEGER NOT NULL)',
      )
      ..execute(
        'CREATE TABLE "lab_drafts" ("exercise_id" TEXT NOT NULL, "code" TEXT '
        'NOT NULL, "solved" INTEGER NOT NULL DEFAULT 0 CHECK ("solved" IN (0, '
        '1)), "updated_at" INTEGER NOT NULL, PRIMARY KEY ("exercise_id"))',
      )
      ..execute(
        'CREATE TABLE "lab_revisions" ("id" INTEGER NOT NULL PRIMARY KEY '
        'AUTOINCREMENT, "exercise_id" TEXT NOT NULL, "code" TEXT NOT NULL, '
        '"label" TEXT NOT NULL, "created_at" INTEGER NOT NULL)',
      )
      ..execute("INSERT INTO lab_drafts VALUES ('kt-null', 'mon code', 1, 1)")
      ..execute('PRAGMA user_version = 5');
    raw.close();

    final database = AppDatabase(NativeDatabase(file));
    final drafts = await database.select(database.labDrafts).get();
    expect(drafts.single.code, 'mon code');
    expect(drafts.single.solved, isTrue);

    final id = await database
        .into(database.bugCases)
        .insert(
          BugCasesCompanion.insert(
            title: 'Dossier',
            errorText: 'e',
            description: '',
            code: '',
            status: 'open',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        );
    expect(id, greaterThan(0));
    await database.close();
  });

  test('la version 4 passe en version 5 sans perte', () async {
    createV2Database();
    final raw = sqlite3.open(file.path);
    raw
      ..execute(
        'CREATE TABLE "exercise_answers" ("exercise_id" TEXT NOT NULL, '
        '"module_id" TEXT NOT NULL, "answer" TEXT NOT NULL, "status" TEXT NOT '
        'NULL, "updated_at" INTEGER NOT NULL, PRIMARY KEY ("exercise_id"))',
      )
      ..execute(
        'CREATE TABLE "ai_conversations" ("id" INTEGER NOT NULL PRIMARY KEY '
        'AUTOINCREMENT, "title" TEXT NOT NULL, "provider_kind" TEXT NOT NULL, '
        '"model" TEXT NOT NULL, "mode" TEXT NOT NULL, "created_at" INTEGER NOT '
        'NULL, "updated_at" INTEGER NOT NULL)',
      )
      ..execute(
        'CREATE TABLE "ai_messages" ("id" INTEGER NOT NULL PRIMARY KEY '
        'AUTOINCREMENT, "conversation_id" INTEGER NOT NULL REFERENCES '
        'ai_conversations (id), "role" TEXT NOT NULL, "content" TEXT NOT NULL, '
        '"input_tokens" INTEGER NULL, "output_tokens" INTEGER NULL, '
        '"stop_reason" TEXT NULL, "created_at" INTEGER NOT NULL)',
      )
      ..execute(
        "INSERT INTO ai_conversations (title, provider_kind, model, mode, "
        "created_at, updated_at) VALUES ('Ma conversation', 'ollama', 'm', "
        "'general', 1, 1)",
      )
      ..execute('PRAGMA user_version = 4');
    raw.close();

    final database = AppDatabase(NativeDatabase(file));
    final rows = await database.select(database.aiConversations).get();
    expect(rows.single.title, 'Ma conversation');

    await database
        .into(database.labDrafts)
        .insert(
          LabDraftsCompanion.insert(
            exerciseId: 'kt-niveau',
            code: 'code',
            updatedAt: DateTime(2026),
          ),
        );
    await database.close();

    expect(schemaOf(file.path), contains('lab_revisions'));
  });

  test('la version 3 passe en version 4 sans perte', () async {
    // Base réelle de la version 3 : version 2 migrée par le code précédent,
    // puis ramenée au schéma exact de la version 3.
    createV2Database();
    final raw = sqlite3.open(file.path);
    raw
      ..execute(
        'CREATE TABLE "exercise_answers" ("exercise_id" TEXT NOT NULL, '
        '"module_id" TEXT NOT NULL, "answer" TEXT NOT NULL, "status" TEXT NOT '
        'NULL, "updated_at" INTEGER NOT NULL, PRIMARY KEY ("exercise_id"))',
      )
      ..execute(
        "INSERT INTO exercise_answers VALUES ('ex', 'kotlin', 'Ma réponse', "
        "'success', 1)",
      )
      ..execute('PRAGMA user_version = 3');
    raw.close();

    final database = AppDatabase(NativeDatabase(file));
    final answers = await database.select(database.exerciseAnswers).get();
    expect(answers.single.answer, 'Ma réponse');
    expect(await database.readMeta('appearance.theme'), 'light');

    final id = await database
        .into(database.aiConversations)
        .insert(
          AiConversationsCompanion.insert(
            title: 'Après migration',
            providerKind: 'ollama',
            model: 'm',
            mode: 'general',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        );
    expect(id, greaterThan(0));
    await database.close();

    expect(schemaOf(file.path), contains('ai_messages'));
  });

  test('la version 2 passe en version 3 sans perte', () async {
    createV2Database();

    final database = AppDatabase(NativeDatabase(file));
    expect(await database.readMeta('appearance.theme'), 'light');
    final progress = await ProgressRepository(
      database,
      DateTime.now,
    ).watch().first;
    expect(progress.xp, 10);
    expect(progress.lessonsCompleted, 1);
    final notes = await NotesRepository(database, DateTime.now).watch().first;
    expect(notes.single.title, 'Ma note');
    await database.close();
  });

  test('une base v2 migrée a le même schéma qu\'une base neuve', () async {
    createV2Database();
    final migrated = AppDatabase(NativeDatabase(file));
    await migrated.readMeta('x');
    await migrated.close();

    final freshFile = File(p.join(directory.path, 'neuve.sqlite'));
    final fresh = AppDatabase(NativeDatabase(freshFile));
    await fresh.readMeta('x');
    await fresh.close();

    expect(schemaOf(file.path), schemaOf(freshFile.path));
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
