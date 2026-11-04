import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    AppMeta,
    LessonProgress,
    QuizAttempts,
    XpEvents,
    Notes,
    Favorites,
    ExerciseAnswers,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Toute hausse de version exige une étape dans [migration] et un test sur
  /// une base réelle de l'ancienne version.
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(lessonProgress);
        await migrator.createTable(quizAttempts);
        await migrator.createTable(xpEvents);
        await migrator.createTable(notes);
        await migrator.createTable(favorites);
      }
      if (from < 3) {
        await migrator.createTable(exerciseAnswers);
      }
    },
  );

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
  final database = AppDatabase(
    driftDatabase(
      name: databaseName,
      native: DriftNativeOptions(
        // Par défaut, drift écrirait dans ~/Documents sur Linux. Sur Android, ce
        // dossier est déjà privé à l'application.
        databaseDirectory: Platform.isLinux
            ? getApplicationSupportDirectory
            : null,
      ),
    ),
  );
  ref.onDispose(database.close);
  return database;
});
