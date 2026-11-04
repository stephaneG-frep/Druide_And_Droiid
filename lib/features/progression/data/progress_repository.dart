import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/persistence/app_database.dart';
import '../domain/progression.dart';

class ProgressRepository {
  const ProgressRepository(this._database, this._now);

  final AppDatabase _database;
  final DateTime Function() _now;

  /// Suit la progression : toute écriture dans ces tables réémet un instantané.
  Stream<ProgressSnapshot> watch() {
    return _database
        .customSelect(
          'SELECT '
          '(SELECT COALESCE(SUM(amount), 0) FROM xp_events) AS xp, '
          '(SELECT COUNT(*) FROM lesson_progress) AS lessons, '
          '(SELECT COUNT(DISTINCT quiz_id) FROM quiz_attempts '
          'WHERE passed = 1) AS quizzes',
          readsFrom: {
            _database.xpEvents,
            _database.lessonProgress,
            _database.quizAttempts,
          },
        )
        .watchSingle()
        .map(
          (row) => ProgressSnapshot(
            xp: row.read<int>('xp'),
            lessonsCompleted: row.read<int>('lessons'),
            quizzesPassed: row.read<int>('quizzes'),
          ),
        );
  }

  Stream<bool> watchAttempted(String quizId) {
    final query = _database.selectOnly(_database.quizAttempts)
      ..addColumns([_database.quizAttempts.id])
      ..where(_database.quizAttempts.quizId.equals(quizId))
      ..limit(1);
    return query.watch().map((rows) => rows.isNotEmpty);
  }

  /// Marque une leçon terminée. Refaire une leçon ne rapporte rien de plus.
  /// Renvoie l'expérience réellement gagnée.
  Future<int> completeLesson({
    required String lessonId,
    required String moduleId,
    required int xp,
  }) {
    return _database.transaction(() async {
      final now = _now();
      await _database
          .into(_database.lessonProgress)
          .insert(
            LessonProgressCompanion.insert(
              lessonId: lessonId,
              moduleId: moduleId,
              completedAt: now,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      return _award('lesson:$lessonId', xp, now);
    });
  }

  /// Enregistre une tentative. L'expérience n'est gagnée qu'à la première
  /// réussite. Avec [onlyFirstAttempt], seule la première tentative compte.
  Future<QuizOutcome> recordQuizAttempt({
    required String quizId,
    required int score,
    required int maxScore,
    required bool passed,
    required int xp,
    bool onlyFirstAttempt = false,
  }) {
    return _database.transaction(() async {
      if (onlyFirstAttempt && await _hasAttempt(quizId)) {
        return const QuizOutcome(recorded: false, xpEarned: 0);
      }

      final now = _now();
      await _database
          .into(_database.quizAttempts)
          .insert(
            QuizAttemptsCompanion.insert(
              quizId: quizId,
              score: score,
              maxScore: maxScore,
              passed: passed,
              attemptedAt: now,
            ),
          );

      final earned = passed ? await _award('quiz:$quizId', xp, now) : 0;
      return QuizOutcome(recorded: true, xpEarned: earned);
    });
  }

  Future<bool> _hasAttempt(String quizId) async {
    final query = _database.select(_database.quizAttempts)
      ..where((row) => row.quizId.equals(quizId))
      ..limit(1);
    return (await query.get()).isNotEmpty;
  }

  /// Crédite [amount] une seule fois pour [source]. À appeler en transaction.
  Future<int> _award(String source, int amount, DateTime at) async {
    final existing = _database.select(_database.xpEvents)
      ..where((row) => row.source.equals(source));
    if (await existing.getSingleOrNull() != null) return 0;

    await _database
        .into(_database.xpEvents)
        .insert(
          XpEventsCompanion.insert(
            source: source,
            amount: amount,
            earnedAt: at,
          ),
        );
    return amount;
  }
}

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
  ),
);

final progressProvider = StreamProvider<ProgressSnapshot>(
  (ref) => ref.watch(progressRepositoryProvider).watch(),
);

final quizAttemptedProvider = StreamProvider.family<bool, String>(
  (ref, quizId) => ref.watch(progressRepositoryProvider).watchAttempted(quizId),
);
