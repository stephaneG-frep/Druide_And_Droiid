import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/persistence/app_database.dart';
import '../../academie/data/course_repository.dart';
import '../domain/lab_exercise.dart';

const maxRevisions = 50;
const _runAcknowledged = 'lab.run_acknowledged';

class LabRepository {
  const LabRepository(this._database, this._clock);

  final AppDatabase _database;
  final DateTime Function() _clock;

  Stream<Map<String, LabDraft>> watchDrafts() {
    return _database
        .select(_database.labDrafts)
        .watch()
        .map((rows) => {for (final row in rows) row.exerciseId: row});
  }

  Future<LabDraft?> draft(String exerciseId) {
    final query = _database.select(_database.labDrafts)
      ..where((row) => row.exerciseId.equals(exerciseId));
    return query.getSingleOrNull();
  }

  Future<void> saveDraft(String exerciseId, String code) {
    return _database
        .into(_database.labDrafts)
        .insert(
          LabDraftsCompanion.insert(
            exerciseId: exerciseId,
            code: code,
            updatedAt: _clock(),
          ),
          onConflict: DoUpdate(
            (_) => LabDraftsCompanion(
              code: Value(code),
              updatedAt: Value(_clock()),
            ),
          ),
        );
  }

  Future<void> markSolved(String exerciseId, String code) async {
    await saveDraft(exerciseId, code);
    await (_database.update(_database.labDrafts)
          ..where((row) => row.exerciseId.equals(exerciseId)))
        .write(const LabDraftsCompanion(solved: Value(true)));
  }

  Stream<List<LabRevisionRow>> watchRevisions(String exerciseId) {
    final query = _database.select(_database.labRevisions)
      ..where((row) => row.exerciseId.equals(exerciseId))
      ..orderBy([(row) => OrderingTerm.desc(row.id)]);
    return query.watch();
  }

  /// Ignore une version identique à la précédente, et oublie les plus anciennes.
  Future<void> addRevision(String exerciseId, String code, String label) {
    return _database.transaction(() async {
      final query = _database.select(_database.labRevisions)
        ..where((row) => row.exerciseId.equals(exerciseId))
        ..orderBy([(row) => OrderingTerm.desc(row.id)]);
      final revisions = await query.get();
      if (revisions.isNotEmpty && revisions.first.code == code) return;

      await _database
          .into(_database.labRevisions)
          .insert(
            LabRevisionsCompanion.insert(
              exerciseId: exerciseId,
              code: code,
              label: label,
              createdAt: _clock(),
            ),
          );
      for (final old in revisions.skip(maxRevisions - 1)) {
        await (_database.delete(
          _database.labRevisions,
        )..where((row) => row.id.equals(old.id))).go();
      }
    });
  }

  Future<bool> runAcknowledged() async =>
      await _database.readMeta(_runAcknowledged) != null;

  Future<void> acknowledgeRun() => _database.writeMeta(_runAcknowledged, '1');
}

final labRepositoryProvider = Provider<LabRepository>(
  (ref) =>
      LabRepository(ref.watch(appDatabaseProvider), ref.watch(clockProvider)),
);

final labExercisesProvider = FutureProvider<List<LabExercise>>((ref) async {
  final source = await ref
      .watch(assetBundleProvider)
      .loadString('assets/lab/exercises.json');
  return parseExercises(jsonDecode(source) as Map<String, Object?>);
}, retry: (_, _) => null);

final labDraftsProvider = StreamProvider<Map<String, LabDraft>>(
  (ref) => ref.watch(labRepositoryProvider).watchDrafts(),
  retry: (_, _) => null,
);

final labRevisionsProvider =
    StreamProvider.family<List<LabRevisionRow>, String>(
      (ref, id) => ref.watch(labRepositoryProvider).watchRevisions(id),
      retry: (_, _) => null,
    );
