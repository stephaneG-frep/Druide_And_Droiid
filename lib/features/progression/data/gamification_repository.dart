import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/persistence/app_database.dart';
import '../../academie/data/course_repository.dart';
import '../../academie/data/exercise_repository.dart';
import '../../academie/domain/rewards.dart';
import '../../chaudron/domain/log_tools.dart';
import '../../projets/data/project_repository.dart';
import '../../projets/domain/final_grid.dart';
import '../domain/badges.dart';
import '../domain/challenges.dart';
import '../domain/learner_stats.dart';
import '../domain/learning_paths.dart';
import '../domain/progression.dart';
import 'progress_repository.dart';

const _pathKey = 'progress.path';
const _goalKey = 'progress.weekly_goal';
const _nameKey = 'progress.name';
const defaultWeeklyGoal = 3;

class RewardReport {
  const RewardReport({this.xp = 0, this.badges = const [], this.rank});

  final int xp;
  final List<Badge> badges;

  /// Nouveau grade, s'il vient d'être atteint.
  final Rank? rank;

  bool get isEmpty => xp == 0 && badges.isEmpty;
}

class GamificationRepository {
  const GamificationRepository(this._database, this._progress, this._clock);

  final AppDatabase _database;
  final ProgressRepository _progress;
  final DateTime Function() _clock;

  Stream<LearnerStats> watch() async* {
    yield await read();
    yield* _database
        .tableUpdates(
          TableUpdateQuery.onAllTables([
            _database.xpEvents,
            _database.lessonProgress,
            _database.quizAttempts,
            _database.exerciseAnswers,
            _database.labDrafts,
            _database.projectProgress,
            _database.finalProjectScores,
            _database.bugCases,
            _database.aiConversations,
            _database.badgeUnlocks,
          ]),
        )
        .asyncMap((_) => read());
  }

  Future<LearnerStats> read() async {
    final attempts = await _database.select(_database.quizAttempts).get();
    final passed = <String>{};
    final evaluations = <String, DateTime>{};
    var perfect = 0;
    for (final attempt in attempts) {
      if (attempt.passed) passed.add(attempt.quizId);
      if (attempt.quizId.startsWith('lesson:') &&
          attempt.maxScore > 0 &&
          attempt.score == attempt.maxScore) {
        perfect++;
      }
      if (attempt.passed && attempt.quizId.startsWith('eval:')) {
        final module = attempt.quizId.substring(5);
        final known = evaluations[module];
        if (known == null || attempt.attemptedAt.isBefore(known)) {
          evaluations[module] = attempt.attemptedAt;
        }
      }
    }

    final answers = await _database.select(_database.exerciseAnswers).get();
    final drafts = await _database.select(_database.labDrafts).get();
    final projects = await _database.select(_database.projectProgress).get();
    final finals = await _database.select(_database.finalProjectScores).get();
    final bugs = await _database.select(_database.bugCases).get();
    final conversations = await _database
        .select(_database.aiConversations)
        .get();
    final events = await _database.select(_database.xpEvents).get();
    final unlocks = await _database.select(_database.badgeUnlocks).get();
    final lessons = await _database.select(_database.lessonProgress).get();

    return LearnerStats(
      completedLessons: {for (final row in lessons) row.lessonId},
      passedQuizzes: passed,
      perfectQuizzes: perfect,
      evaluationDates: evaluations,
      exercisesDone: answers
          .where((row) => row.status == ExerciseStatus.success.name)
          .length,
      labSolved: {
        for (final draft in drafts)
          if (draft.solved) draft.exerciseId,
      },
      projectsDone: {
        for (final row in projects)
          if (row.completedAt != null) row.projectId,
      },
      finalValidated: evaluateFinal({
        for (final row in finals)
          row.criterion: FinalEntry(row.score, row.proof),
      }).validated,
      bugsVerified: [
        for (final bug in bugs)
          if (BugStatus.byName(bug.status) == BugStatus.verified) bug.id,
      ],
      conversations: conversations.length,
      xpEvents: [
        for (final event in events)
          XpEntry(event.source, event.amount, event.earnedAt),
      ],
      badges: {for (final row in unlocks) row.badgeId: row.unlockedAt},
    );
  }

  /// Attribue ce qui est dû, sans rien retirer. Peut s'appeler à tout moment :
  /// chaque récompense est unique.
  Future<RewardReport> reconcile(LearningCatalog catalog) {
    return _database.transaction(() async {
      final before = await read();
      final now = _clock();
      var xp = 0;

      for (final id in before.labSolved) {
        if (!id.startsWith('libre-')) {
          xp += await _progress.award('lab:$id', Rewards.labExercise, now);
        }
      }
      for (final id in before.projectsDone) {
        final level = catalog.projectLevels[id];
        if (level != null) {
          xp += await _progress.award(
            'project:$id',
            Rewards.project(level),
            now,
          );
        }
      }
      if (before.finalValidated) {
        xp += await _progress.award('final:expert', Rewards.finalProject, now);
      }
      var bugsPaid = before.xpEvents
          .where((event) => event.source.startsWith('bug:'))
          .length;
      for (final id in before.bugsVerified) {
        if (bugsPaid >= Rewards.bugVerifiedLimit) break;
        final earned = await _progress.award(
          'bug:$id',
          Rewards.bugVerified,
          now,
        );
        if (earned > 0) bugsPaid++;
        xp += earned;
      }

      final after = await read();
      final fresh = [
        for (final badge in badges)
          if (!after.badges.containsKey(badge.id) &&
              badge.earned(after, catalog))
            badge,
      ];
      for (final badge in fresh) {
        await _database
            .into(_database.badgeUnlocks)
            .insert(
              BadgeUnlocksCompanion.insert(badgeId: badge.id, unlockedAt: now),
              mode: InsertMode.insertOrIgnore,
            );
      }

      final oldRank = Rank.forXp(before.xp);
      final newRank = Rank.forXp(after.xp);
      return RewardReport(
        xp: xp,
        badges: fresh,
        rank: newRank == oldRank ? null : newRank,
      );
    });
  }

  /// Réclame un défi accompli. Renvoie l'expérience gagnée.
  Future<int> claim(Challenge challenge) {
    return _database.transaction(() async {
      final now = _clock();
      final stats = await read();
      if (challengeProgress(challenge, stats, now) < challenge.count) return 0;
      return _progress.award(
        challengeSource(challenge, now),
        challenge.xp,
        now,
      );
    });
  }

  Future<LearningPath?> path() async =>
      LearningPath.byName(await _database.readMeta(_pathKey));

  Future<void> setPath(LearningPath path) =>
      _database.writeMeta(_pathKey, path.name);

  Future<int> weeklyGoal() async =>
      int.tryParse(await _database.readMeta(_goalKey) ?? '') ??
      defaultWeeklyGoal;

  Future<void> setWeeklyGoal(int goal) =>
      _database.writeMeta(_goalKey, '$goal');

  Future<String> learnerName() async =>
      await _database.readMeta(_nameKey) ?? '';

  Future<void> setLearnerName(String name) =>
      _database.writeMeta(_nameKey, name.trim());
}

final gamificationRepositoryProvider = Provider<GamificationRepository>(
  (ref) => GamificationRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(progressRepositoryProvider),
    ref.watch(clockProvider),
  ),
);

final learningCatalogProvider = FutureProvider<LearningCatalog>((ref) async {
  final courses = ref.watch(courseRepositoryProvider);
  final lessonsByModule = <String, List<String>>{};
  final titles = <String, String>{};
  for (final module in await courses.availableModules()) {
    final course = await courses.load(module);
    lessonsByModule[module] = [for (final lesson in course.lessons) lesson.id];
    for (final lesson in course.lessons) {
      titles[lesson.id] = lesson.title;
    }
  }
  final projects = await ref.watch(projectsProvider.future);
  return LearningCatalog(
    lessonsByModule: lessonsByModule,
    lessonTitles: titles,
    projectLevels: {for (final project in projects) project.id: project.level},
  );
}, retry: (_, _) => null);

final learnerStatsProvider = StreamProvider<LearnerStats>(
  (ref) => ref.watch(gamificationRepositoryProvider).watch(),
  retry: (_, _) => null,
);

/// Récompenses dues : à appeler après une action qui peut en donner.
Future<RewardReport> settleRewards(WidgetRef ref) async {
  final catalog = await ref.read(learningCatalogProvider.future);
  return ref.read(gamificationRepositoryProvider).reconcile(catalog);
}
