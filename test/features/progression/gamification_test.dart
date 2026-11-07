import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:druide_and_droiid/app/sections.dart';
import 'package:druide_and_droiid/core/persistence/app_database.dart';
import 'package:druide_and_droiid/features/academie/domain/module_catalog.dart';
import 'package:druide_and_droiid/features/academie/domain/rewards.dart';
import 'package:druide_and_droiid/features/chaudron/data/bug_repository.dart';
import 'package:druide_and_droiid/features/chaudron/domain/log_tools.dart';
import 'package:druide_and_droiid/features/lab/data/lab_repository.dart';
import 'package:druide_and_droiid/features/progression/data/gamification_repository.dart';
import 'package:druide_and_droiid/features/progression/data/progress_repository.dart';
import 'package:druide_and_droiid/features/progression/domain/badges.dart';
import 'package:druide_and_droiid/features/progression/domain/certificates.dart';
import 'package:druide_and_droiid/features/progression/domain/challenges.dart';
import 'package:druide_and_droiid/features/progression/domain/learner_stats.dart';
import 'package:druide_and_droiid/features/progression/domain/learning_paths.dart';
import 'package:druide_and_droiid/features/progression/domain/progression.dart';
import 'package:druide_and_droiid/features/progression/presentation/progression_paths.dart';
import 'package:druide_and_droiid/features/projets/domain/project.dart';
import 'package:flutter/material.dart' show Scrollable, Size;
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_app.dart';

const catalog = LearningCatalog(
  lessonsByModule: {
    'kotlin': ['a', 'b'],
    'java': ['c'],
  },
  lessonTitles: {'a': 'Leçon A', 'b': 'Leçon B', 'c': 'Leçon C'},
  projectLevels: {'calculatrice': ModuleLevel.debutant},
);

void main() {
  test('Grand Druide reste atteignable, sans être offert', () {
    var reachable = Rewards.finalProject;
    var modules = 0;
    final index = jsonDecode(
      File('assets/courses/index.json').readAsStringSync(),
    ) as Map<String, Object?>;
    for (final module in (index['modules']! as List<Object?>).cast<String>()) {
      final course = jsonDecode(
        File('assets/courses/$module.json').readAsStringSync(),
      ) as Map<String, Object?>;
      modules++;
      for (final lesson
          in (course['lessons']! as List<Object?>)
              .cast<Map<String, Object?>>()) {
        reachable += Rewards.lesson + Rewards.quiz;
        reachable +=
            (lesson['exercises']! as List<Object?>).length * Rewards.exercise;
      }
    }
    reachable += modules * Rewards.evaluation;

    final lab = jsonDecode(
      File('assets/lab/exercises.json').readAsStringSync(),
    ) as Map<String, Object?>;
    reachable +=
        (lab['exercises']! as List<Object?>).length * Rewards.labExercise;

    final projects = parseProjects(
      jsonDecode(File('assets/projects/projects.json').readAsStringSync())
          as Map<String, Object?>,
    );
    for (final project in projects) {
      reachable += Rewards.project(project.level);
    }

    expect(reachable, greaterThanOrEqualTo(Rank.grandDruide.minXp));
    expect(reachable * 0.75, lessThan(Rank.grandDruide.minXp));
  });

  group('série de jours', () {
    final today = DateTime(2026, 3, 30);

    test('compte les jours consécutifs', () {
      expect(
        currentStreak({
          DateTime(2026, 3, 30),
          DateTime(2026, 3, 29),
          DateTime(2026, 3, 27),
        }, today),
        2,
      );
    });

    test('aujourd\'hui vide ne casse pas encore la série', () {
      expect(
        currentStreak({DateTime(2026, 3, 29), DateTime(2026, 3, 28)}, today),
        2,
      );
    });

    test('deux jours vides remettent à zéro', () {
      expect(currentStreak({DateTime(2026, 3, 28)}, today), 0);
    });

    test('le changement d\'heure ne casse pas la série', () {
      final stats = LearnerStats(
        xpEvents: [
          for (var day = 25; day <= 31; day++)
            XpEntry('a', 1, DateTime(2026, 3, day, 12)),
        ],
      );
      expect(stats.bestStreak(), 7);
    });
  });

  group('défis', () {
    test('restent identiques toute la journée', () {
      final morning = challengesFor(DateTime(2026, 11, 7, 8));
      final evening = challengesFor(DateTime(2026, 11, 7, 23));
      expect(morning.map((c) => c.id), evening.map((c) => c.id));
      expect(morning, hasLength(3));
      expect(morning[0].id, isNot(morning[1].id));
    });

    test('la semaine commence le lundi', () {
      expect(weekStart(DateTime(2026, 11, 8)), DateTime(2026, 11, 2));
      expect(weekStart(DateTime(2026, 11, 9)), DateTime(2026, 11, 9));
    });

    test('ne comptent que la période en cours', () {
      final challenge = challengesFor(DateTime(2026, 11, 7))
          .firstWhere((item) => item.period == ChallengePeriod.day);
      final stats = LearnerStats(
        xpEvents: [
          XpEntry('${challenge.prefix}x', 1, DateTime(2026, 11, 6, 23)),
          XpEntry('${challenge.prefix}y', 1, DateTime(2026, 11, 7, 1)),
        ],
      );
      expect(challengeProgress(challenge, stats, DateTime(2026, 11, 7, 9)), 1);
    });
  });

  test('un parcours mène à la première leçon non terminée', () {
    final next = nextLesson(LearningPath.natif, catalog.lessonsByModule, {'a'});
    expect(next!.lessonId, 'b');
    expect(next.moduleId, 'kotlin');

    expect(
      nextLesson(LearningPath.ia, catalog.lessonsByModule, {'a', 'b', 'c'}),
      isNull,
    );
  });

  test('chaque parcours renvoie à de vrais modules', () {
    for (final path in LearningPath.values) {
      for (final module in path.modules) {
        expect(moduleById(module), isNotNull, reason: module);
      }
    }
  });

  test('les badges ont des identifiants uniques', () {
    expect(badges.map((b) => b.id).toSet().length, badges.length);
  });

  group('certificats', () {
    test('un module exige ses leçons et son évaluation', () {
      expect(
        certificatesFor(
          const LearnerStats(completedLessons: {'a', 'b'}),
          catalog,
        ),
        isEmpty,
      );
      final certificates = certificatesFor(
        LearnerStats(
          completedLessons: const {'a', 'b'},
          evaluationDates: {'kotlin': DateTime(2026)},
        ),
        catalog,
      );
      expect(certificates.single.id, 'kotlin');
    });

    test(
      'le certificat de parcours exige tout, évaluation finale comprise',
      () {
        final stats = LearnerStats(
          completedLessons: const {'a', 'b', 'c'},
          evaluationDates: {
            'kotlin': DateTime(2026),
            'java': DateTime(2026, 2),
          },
        );
        bool hasGlobal(LearnerStats value) => certificatesFor(
          value,
          catalog,
        ).any((item) => item.id == grandDruideCertificate);

        expect(hasGlobal(stats), isFalse);
        expect(
          hasGlobal(
            LearnerStats(
              completedLessons: stats.completedLessons,
              evaluationDates: stats.evaluationDates,
              finalValidated: true,
            ),
          ),
          isTrue,
        );
      },
    );

    test('le texte écarte toute valeur officielle', () {
      expect(certificateDisclaimer, contains('ni un diplôme'));
      expect(certificateDisclaimer, contains('officielle'));
    });
  });

  group('récompenses', () {
    late AppDatabase database;
    late GamificationRepository repository;
    late ProgressRepository progress;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      progress = ProgressRepository(database, DateTime.now);
      repository = GamificationRepository(database, progress, DateTime.now);
    });

    tearDown(() => database.close());

    test('une leçon débloque son badge, une seule fois', () async {
      await progress.completeLesson(lessonId: 'a', moduleId: 'kotlin', xp: 20);

      final first = await repository.reconcile(catalog);
      expect(first.badges.map((b) => b.id), contains('premiere-lecon'));

      final second = await repository.reconcile(catalog);
      expect(second.isEmpty, isTrue);
    });

    test(
      'le Lab rapporte une fois, sans compter les feuilles libres',
      () async {
        final lab = LabRepository(database, DateTime.now);
        await lab.markSolved('kt-null', 'code');
        await lab.markSolved('libre-kotlin', 'code');

        expect((await repository.reconcile(catalog)).xp, Rewards.labExercise);
        expect((await repository.reconcile(catalog)).xp, 0);
      },
    );

    test('un badge gagné reste acquis', () async {
      final lab = LabRepository(database, DateTime.now);
      await lab.markSolved('kt-null', 'code');
      await repository.reconcile(catalog);

      await (database.delete(database.labDrafts)).go();
      await repository.reconcile(catalog);

      expect((await repository.read()).badges, contains('lab-kotlin'));
    });

    test('les bugs vérifiés rapportent, dans une limite', () async {
      final bugs = BugRepository(database, DateTime.now);
      for (var i = 0; i < Rewards.bugVerifiedLimit + 3; i++) {
        final id = await bugs.create(errorText: 'e', description: '', code: '');
        await bugs.recordVerification(id, BugStatus.verified, 'résultat');
      }

      expect(
        (await repository.reconcile(catalog)).xp,
        Rewards.bugVerified * Rewards.bugVerifiedLimit,
      );
    });

    test('un dossier non vérifié ne rapporte rien', () async {
      await BugRepository(
        database,
        DateTime.now,
      ).create(errorText: 'e', description: '', code: '');

      expect((await repository.reconcile(catalog)).xp, 0);
    });

    test('un grade atteint est annoncé', () async {
      await progress.completeLesson(
        lessonId: 'a',
        moduleId: 'kotlin',
        xp: Rank.initie.minXp - Rewards.labExercise,
      );
      await LabRepository(database, DateTime.now).markSolved('kt-null', 'code');

      expect((await repository.reconcile(catalog)).rank, Rank.initie);
    });

    test('un défi ne se réclame qu\'accompli, et une seule fois', () async {
      const challenge = Challenge(
        'lecon',
        'Terminer une leçon',
        'lesson:',
        1,
        15,
        ChallengePeriod.day,
      );
      expect(await repository.claim(challenge), 0);

      await progress.completeLesson(lessonId: 'a', moduleId: 'kotlin', xp: 20);
      expect(await repository.claim(challenge), 15);
      expect(await repository.claim(challenge), 0);
    });

    test('les statistiques suivent les modifications', () async {
      final values = <int>[];
      final subscription = repository.watch().listen(
        (stats) => values.add(stats.completedLessons.length),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await progress.completeLesson(lessonId: 'a', moduleId: 'kotlin', xp: 20);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(values.last, 1);
      await subscription.cancel();
    });

    test('le parcours, l\'objectif et le nom sont conservés', () async {
      await repository.setPath(LearningPath.flutter);
      await repository.setWeeklyGoal(5);
      await repository.setLearnerName('  Ana  ');

      expect(await repository.path(), LearningPath.flutter);
      expect(await repository.weeklyGoal(), 5);
      expect(await repository.learnerName(), 'Ana');
    });
  });

  group('écrans', () {
    testWidgets('la progression affiche ses rubriques', (tester) async {
      final container = await pumpApp(tester, size: const Size(420, 4200));
      await goTo(tester, container, AppSection.progression.path);

      for (final title in [
        'Objectif de la semaine',
        'Mon parcours',
        'Défis',
        'Statistiques',
        'Avancement par module',
        'Certificats internes',
        'Badges',
        'Les huit grades',
      ]) {
        await tester.scrollUntilVisible(
          find.text(title),
          400,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(title), findsOneWidget, reason: title);
      }
      expect(find.text(Rank.apprenti.title), findsWidgets);
    });

    testWidgets('l\'historique vide le dit', (tester) async {
      final container = await pumpApp(tester);
      await goTo(tester, container, progressionHistoryPath);

      expect(find.textContaining('aventure commence'), findsOneWidget);
    });

    testWidgets('un certificat non obtenu ne s\'affiche pas', (tester) async {
      final container = await pumpApp(tester);
      await goTo(tester, container, certificatePath('kotlin'));

      expect(find.textContaining('pas encore obtenu'), findsOneWidget);
    });

    testWidgets('la page tient sur un petit écran', (tester) async {
      final container = await pumpApp(tester, size: const Size(320, 568));
      await goTo(tester, container, AppSection.progression.path);

      expect(tester.takeException(), isNull);
    });
  });
}
