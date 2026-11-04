import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/persistence/app_database.dart';
import '../../progression/data/progress_repository.dart';
import '../domain/rewards.dart';

enum ExerciseStatus { draft, success, retry }

class ExerciseAnswer {
  const ExerciseAnswer({required this.text, required this.status});

  final String text;
  final ExerciseStatus status;
}

class ExerciseRepository {
  const ExerciseRepository(this._database, this._progress, this._now);

  final AppDatabase _database;
  final ProgressRepository _progress;
  final DateTime Function() _now;

  Future<ExerciseAnswer?> find(String exerciseId) async {
    final query = _database.select(_database.exerciseAnswers)
      ..where((row) => row.exerciseId.equals(exerciseId));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return ExerciseAnswer(
      text: row.answer,
      status:
          ExerciseStatus.values.asNameMap()[row.status] ?? ExerciseStatus.draft,
    );
  }

  /// Enregistre le texte saisi sans toucher au résultat déjà obtenu.
  Future<void> saveText({
    required String exerciseId,
    required String moduleId,
    required String text,
  }) async {
    final existing = await find(exerciseId);
    await _write(
      exerciseId,
      moduleId,
      text,
      existing?.status ?? ExerciseStatus.draft,
    );
  }

  /// Enregistre le résultat. Renvoie l'expérience réellement gagnée : seule la
  /// première réussite en rapporte.
  Future<int> saveResult({
    required String exerciseId,
    required String moduleId,
    required String text,
    required bool success,
  }) {
    return _database.transaction(() async {
      await _write(
        exerciseId,
        moduleId,
        text,
        success ? ExerciseStatus.success : ExerciseStatus.retry,
      );
      if (!success) return 0;
      return _progress.award('exercise:$exerciseId', Rewards.exercise, _now());
    });
  }

  Future<void> _write(
    String exerciseId,
    String moduleId,
    String text,
    ExerciseStatus status,
  ) {
    return _database
        .into(_database.exerciseAnswers)
        .insertOnConflictUpdate(
          ExerciseAnswersCompanion.insert(
            exerciseId: exerciseId,
            moduleId: moduleId,
            answer: text,
            status: status.name,
            updatedAt: _now(),
          ),
        );
  }
}

final exerciseRepositoryProvider = Provider<ExerciseRepository>(
  (ref) => ExerciseRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(progressRepositoryProvider),
    ref.watch(clockProvider),
  ),
);
