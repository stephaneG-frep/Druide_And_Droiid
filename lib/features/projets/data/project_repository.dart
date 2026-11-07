import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/persistence/app_database.dart';
import '../../academie/data/course_repository.dart';
import '../domain/final_grid.dart';
import '../domain/project.dart';

ProjectState _decode(ProjectProgressData row) {
  Set<int> indices(String text) =>
      (jsonDecode(text) as List<Object?>).cast<int>().toSet();

  return ProjectState(
    doneSteps: indices(row.doneSteps),
    doneCriteria: indices(row.doneCriteria),
    quizPassed: row.quizPassed,
    proof: row.proof,
    completed: row.completedAt != null,
  );
}

String _encode(Set<int> indices) => jsonEncode(indices.toList()..sort());

class ProjectRepository {
  const ProjectRepository(this._database, this._clock);

  final AppDatabase _database;
  final DateTime Function() _clock;

  Stream<Map<String, ProjectState>> watchAll() {
    return _database
        .select(_database.projectProgress)
        .watch()
        .map((rows) => {for (final row in rows) row.projectId: _decode(row)});
  }

  Future<ProjectState> read(String id) async {
    final query = _database.select(_database.projectProgress)
      ..where((row) => row.projectId.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? const ProjectState() : _decode(row);
  }

  /// Modifier un élément annule la validation : elle doit rester vraie.
  Future<void> _write(String id, ProjectProgressCompanion changes) {
    return _database
        .into(_database.projectProgress)
        .insert(
          changes.copyWith(
            projectId: Value(id),
            updatedAt: Value(_clock()),
            completedAt: const Value(null),
          ),
          onConflict: DoUpdate(
            (_) => changes.copyWith(
              updatedAt: Value(_clock()),
              completedAt: const Value(null),
            ),
          ),
        );
  }

  Future<void> toggleStep(String id, int index) async {
    final state = await read(id);
    final steps = {...state.doneSteps};
    if (!steps.remove(index)) steps.add(index);
    await _write(
      id,
      ProjectProgressCompanion(doneSteps: Value(_encode(steps))),
    );
  }

  Future<void> toggleCriterion(String id, int index) async {
    final state = await read(id);
    final criteria = {...state.doneCriteria};
    if (!criteria.remove(index)) criteria.add(index);
    await _write(
      id,
      ProjectProgressCompanion(doneCriteria: Value(_encode(criteria))),
    );
  }

  Future<void> setQuizPassed(String id, {required bool passed}) =>
      _write(id, ProjectProgressCompanion(quizPassed: Value(passed)));

  Future<void> saveProof(String id, String proof) =>
      _write(id, ProjectProgressCompanion(proof: Value(proof)));

  /// Refuse de terminer un projet incomplet.
  Future<void> complete(Project project) async {
    final state = await read(project.id);
    final missing = state.missing(project);
    if (missing.isNotEmpty) {
      throw StateError('Projet incomplet : ${missing.join(', ')}');
    }
    await (_database.update(_database.projectProgress)
          ..where((row) => row.projectId.equals(project.id)))
        .write(ProjectProgressCompanion(completedAt: Value(_clock())));
  }

  Stream<Map<String, FinalEntry>> watchFinal() {
    return _database
        .select(_database.finalProjectScores)
        .watch()
        .map(
          (rows) => {
            for (final row in rows)
              row.criterion: FinalEntry(row.score, row.proof),
          },
        );
  }

  Future<void> saveFinal(String criterion, int score, String proof) {
    return _database
        .into(_database.finalProjectScores)
        .insertOnConflictUpdate(
          FinalProjectScoresCompanion.insert(
            criterion: criterion,
            score: score,
            proof: proof,
            updatedAt: _clock(),
          ),
        );
  }
}

final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => ProjectRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
  ),
);

final projectsProvider = FutureProvider<List<Project>>((ref) async {
  final source = await ref
      .watch(assetBundleProvider)
      .loadString('assets/projects/projects.json');
  return parseProjects(jsonDecode(source) as Map<String, Object?>);
}, retry: (_, _) => null);

final projectStatesProvider = StreamProvider<Map<String, ProjectState>>(
  (ref) => ref.watch(projectRepositoryProvider).watchAll(),
  retry: (_, _) => null,
);

final finalEntriesProvider = StreamProvider<Map<String, FinalEntry>>(
  (ref) => ref.watch(projectRepositoryProvider).watchFinal(),
  retry: (_, _) => null,
);
