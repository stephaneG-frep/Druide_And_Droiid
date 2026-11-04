import 'package:drift/native.dart';
import 'package:druide_and_droiid/core/persistence/app_database.dart';
import 'package:druide_and_droiid/features/accueil/domain/flash_questions.dart';
import 'package:druide_and_droiid/features/progression/data/progress_repository.dart';
import 'package:druide_and_droiid/features/progression/domain/progression.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late ProgressRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = ProgressRepository(database, () => DateTime(2026, 11, 4));
  });
  tearDown(() => database.close());

  Future<ProgressSnapshot> snapshot() => repository.watch().first;

  Future<QuizOutcome> attempt({
    String quizId = 'quiz',
    bool passed = true,
    bool onlyFirstAttempt = false,
  }) {
    return repository.recordQuizAttempt(
      quizId: quizId,
      score: passed ? 1 : 0,
      maxScore: 1,
      passed: passed,
      xp: 10,
      onlyFirstAttempt: onlyFirstAttempt,
    );
  }

  test('une base neuve démarre à zéro', () async {
    final progress = await snapshot();

    expect(progress.xp, 0);
    expect(progress.lessonsCompleted, 0);
    expect(progress.quizzesPassed, 0);
    expect(progress.rank, Rank.apprenti);
  });

  group('leçons', () {
    test('terminer une leçon la compte et crédite l\'expérience', () async {
      final earned = await repository.completeLesson(
        lessonId: 'kotlin-1',
        moduleId: 'kotlin',
        xp: 20,
      );

      expect(earned, 20);
      final progress = await snapshot();
      expect(progress.lessonsCompleted, 1);
      expect(progress.xp, 20);
    });

    test('refaire une leçon ne rapporte rien', () async {
      await repository.completeLesson(
        lessonId: 'kotlin-1',
        moduleId: 'kotlin',
        xp: 20,
      );
      final earned = await repository.completeLesson(
        lessonId: 'kotlin-1',
        moduleId: 'kotlin',
        xp: 20,
      );

      expect(earned, 0);
      final progress = await snapshot();
      expect(progress.lessonsCompleted, 1);
      expect(progress.xp, 20);
    });
  });

  group('quiz', () {
    test('un échec est enregistré sans expérience', () async {
      final outcome = await attempt(passed: false);

      expect(outcome.recorded, isTrue);
      expect(outcome.xpEarned, 0);
      expect((await snapshot()).quizzesPassed, 0);
    });

    test('seule la première réussite rapporte de l\'expérience', () async {
      expect((await attempt()).xpEarned, 10);
      expect((await attempt()).xpEarned, 0);

      final progress = await snapshot();
      expect(progress.xp, 10);
      expect(progress.quizzesPassed, 1);
    });

    test('réussir après un échec rapporte l\'expérience', () async {
      await attempt(passed: false);

      expect((await attempt()).xpEarned, 10);
    });

    test('onlyFirstAttempt ignore toute tentative suivante', () async {
      await attempt(passed: false, onlyFirstAttempt: true);
      final retry = await attempt(onlyFirstAttempt: true);

      expect(retry.recorded, isFalse);
      expect(retry.xpEarned, 0);
      expect((await snapshot()).xp, 0);
    });

    test('des tentatives simultanées ne créditent qu\'une fois', () async {
      await Future.wait([
        attempt(onlyFirstAttempt: true),
        attempt(onlyFirstAttempt: true),
        attempt(onlyFirstAttempt: true),
      ]);

      expect((await snapshot()).xp, 10);
    });
  });

  test('la progression réagit aux écritures', () async {
    final values = <int>[];
    final subscription = repository.watch().listen((p) => values.add(p.xp));
    await pumpEventQueue();

    await attempt();
    await pumpEventQueue();

    expect(values, [0, 10]);
    await subscription.cancel();
  });

  test('atteindre un seuil change le grade', () async {
    await repository.completeLesson(
      lessonId: 'grosse-leçon',
      moduleId: 'kotlin',
      xp: 100,
    );

    expect((await snapshot()).rank, Rank.initie);
  });

  test('l\'identifiant de la question flash change chaque jour', () {
    expect(flashQuizId(DateTime(2026, 1, 5, 23, 59)), 'flash:2026-01-05');
    expect(flashQuizId(DateTime(2026, 1, 6)), 'flash:2026-01-06');
  });
}
