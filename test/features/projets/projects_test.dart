import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:druide_and_droiid/app/sections.dart';
import 'package:druide_and_droiid/core/persistence/app_database.dart';
import 'package:druide_and_droiid/features/academie/domain/course.dart';
import 'package:druide_and_droiid/features/academie/domain/module_catalog.dart';
import 'package:druide_and_droiid/features/projets/data/project_repository.dart';
import 'package:druide_and_droiid/features/projets/domain/final_grid.dart';
import 'package:druide_and_droiid/features/projets/domain/project.dart';
import 'package:druide_and_droiid/features/projets/domain/project_catalog.dart';
import 'package:druide_and_droiid/features/projets/presentation/project_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_app.dart';

List<Project> projects() => parseProjects(
  jsonDecode(File('assets/projects/projects.json').readAsStringSync())
      as Map<String, Object?>,
);

const tall = Size(420, 9000);

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).first);
  await tester.pumpAndSettle();
}

void main() {
  group('catalogue', () {
    test('les vingt projets suivent les parcours du programme', () {
      final all = projects();
      expect(all, hasLength(20));
      for (final track in projectTracks) {
        expect(
          all.where((p) => p.level == track.level).map((p) => p.title),
          track.projects,
        );
      }
    });

    test('chaque projet a tout ce que demande le programme', () {
      for (final project in projects()) {
        expect(project.objective, isNotEmpty, reason: project.id);
        expect(project.prerequisites, isNotEmpty, reason: project.id);
        expect(
          project.steps.length,
          greaterThanOrEqualTo(4),
          reason: project.id,
        );
        expect(
          project.steps.where((step) => step.code != null),
          isNotEmpty,
          reason: project.id,
        );
        expect(project.test.output, isNotEmpty, reason: project.id);
        expect(project.criteria.length, greaterThanOrEqualTo(3));
        expect(project.quiz.length, greaterThanOrEqualTo(2));
        for (final step in project.steps) {
          expect(step.verify, isNotEmpty, reason: step.title);
        }
      }
    });

    test('les prérequis renvoient à de vrais modules', () {
      for (final project in projects()) {
        for (final module in project.modules) {
          expect(moduleById(module), isNotNull, reason: module);
        }
      }
    });

    test('les questions ont des réponses valides', () {
      for (final project in projects()) {
        for (final CourseQuestion question in project.quiz) {
          expect(question.answers, isNotEmpty);
          expect(
            question.answers.every((a) => a < question.options.length),
            isTrue,
          );
        }
      }
    });

    test('aucune clé ni donnée réelle dans le code des projets', () {
      final text = File('assets/projects/projects.json').readAsStringSync();
      expect(RegExp(r'sk-[A-Za-z0-9]{16}').hasMatch(text), isFalse);
      expect(RegExp(r'AIza[0-9A-Za-z_-]{20}').hasMatch(text), isFalse);
    });
  });

  group('suivi', () {
    late AppDatabase database;
    late ProjectRepository repository;
    final project = projects().first;

    Future<void> finishAll() async {
      for (var i = 0; i < project.steps.length; i++) {
        await repository.toggleStep(project.id, i);
      }
      for (var i = 0; i < project.criteria.length; i++) {
        await repository.toggleCriterion(project.id, i);
      }
      await repository.setQuizPassed(project.id, passed: true);
    }

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repository = ProjectRepository(database, DateTime.now);
    });

    tearDown(() => database.close());

    test('cocher puis décocher une étape', () async {
      await repository.toggleStep(project.id, 1);
      expect((await repository.read(project.id)).doneSteps, {1});

      await repository.toggleStep(project.id, 1);
      expect((await repository.read(project.id)).doneSteps, isEmpty);
    });

    test('un projet sans preuve ne se termine pas', () async {
      await finishAll();

      await expectLater(repository.complete(project), throwsStateError);
      expect((await repository.read(project.id)).completed, isFalse);
      expect((await repository.read(project.id)).missing(project), [
        'une preuve',
      ]);
    });

    test('tout rempli, le projet se termine', () async {
      await finishAll();
      await repository.saveProof(project.id, 'https://exemple.com/depot');
      await repository.complete(project);

      expect((await repository.read(project.id)).completed, isTrue);
    });

    test('décocher une étape annule la validation', () async {
      await finishAll();
      await repository.saveProof(project.id, 'preuve');
      await repository.complete(project);

      await repository.toggleStep(project.id, 0);

      expect((await repository.read(project.id)).completed, isFalse);
    });
  });

  group('grille finale', () {
    Map<String, FinalEntry> full(int score, {String proof = 'preuve'}) => {
      for (final criterion in finalCriteria)
        criterion.name: FinalEntry(score, proof),
    };

    test('le total maximal vaut cent', () {
      expect(finalCriteria.fold(0, (sum, c) => sum + c.maximum), 100);
      expect(evaluateFinal(full(100)).total, 100);
      expect(evaluateFinal(full(100)).validated, isTrue);
    });

    test('une note sans preuve compte pour zéro', () {
      expect(evaluateFinal(full(100, proof: '  ')).total, 0);
    });

    test('la sécurité et les tests sont obligatoires', () {
      final entries = full(100)..['Sécurité'] = const FinalEntry(9, 'preuve');
      final result = evaluateFinal(entries);
      expect(result.total, greaterThanOrEqualTo(finalPassMark));
      expect(result.validated, isFalse);
    });

    test('correspond à l\'exemple de la leçon', () {
      const notes = {
        'Utilité réelle': 12,
        'Architecture': 14,
        'Données et API': 11,
        'Sécurité': 10,
        'Tests': 8,
        'Optimisation': 6,
        'Livraison et documentation': 8,
      };
      final result = evaluateFinal({
        for (final MapEntry(:key, :value) in notes.entries)
          key: FinalEntry(value, 'preuve'),
      });
      expect(result.total, 69);
      expect(result.validated, isFalse);
    });

    test('une note ne dépasse pas son maximum', () {
      expect(
        countedScore(finalCriteria.first, const FinalEntry(500, 'preuve')),
        finalCriteria.first.maximum,
      );
    });
  });

  group('écrans', () {
    testWidgets('la liste montre les parcours et l\'évaluation finale', (
      tester,
    ) async {
      final container = await pumpApp(tester, size: const Size(420, 3000));
      await goTo(tester, container, AppSection.projets.path);

      expect(find.text('Calculatrice'), findsOneWidget);
      expect(find.text('Projet professionnel documenté'), findsOneWidget);
      expect(find.text('0 projets terminés sur 20'), findsOneWidget);
      expect(find.text('Ouvrir ma grille'), findsOneWidget);
    });

    testWidgets('une fiche se suit jusqu\'à la validation', (tester) async {
      final container = await pumpApp(tester, size: tall);
      final project = projects().first;
      await goTo(tester, container, projectPath(project.id));

      expect(find.text('Objectif'), findsOneWidget);
      expect(find.text('Critères de réussite'), findsOneWidget);
      expect(find.textContaining('pas dans cette application'), findsOneWidget);

      await tapText(tester, 'Valider le projet');
      expect(find.textContaining('Il manque'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      final boxes = find.byType(Checkbox);
      final count = boxes.evaluate().length;
      expect(count, project.steps.length + project.criteria.length);
      for (var i = 0; i < count; i++) {
        await tester.ensureVisible(boxes.at(i));
        await tester.pumpAndSettle();
        await tester.tap(boxes.at(i));
        await tester.pumpAndSettle();
      }
      expect(tester.widget<Checkbox>(boxes.first).value, isTrue);

      final repository = container.read(projectRepositoryProvider);
      await tester.runAsync(
        () => repository.setQuizPassed(project.id, passed: true),
      );
      await tester.pumpAndSettle();

      final proof = find.widgetWithText(TextField, 'Preuve');
      await tester.ensureVisible(proof);
      await tester.enterText(proof, 'https://exemple.com/depot');
      await tester.pump();
      await tapText(tester, 'Valider le projet');

      expect(find.text('Projet terminé (autoévaluation).'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('la grille finale se dit autoévaluation et calcule le total', (
      tester,
    ) async {
      final container = await pumpApp(tester, size: const Size(420, 2400));
      await goTo(tester, container, finalProjectPath);

      expect(find.textContaining('autoévaluation'), findsWidgets);
      expect(find.text('0 sur 100'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), '12');
      await tester.enterText(find.byType(TextField).at(1), 'Trois testeurs');
      await tester.pump();
      await tapText(tester, 'Enregistrer la grille');

      expect(find.text('12 sur 100'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('un projet inconnu reste sans plantage', (tester) async {
      final container = await pumpApp(tester);
      await goTo(tester, container, projectPath('absent'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('les écrans tiennent sur un petit écran', (tester) async {
      final container = await pumpApp(tester, size: const Size(320, 568));
      await goTo(tester, container, AppSection.projets.path);
      expect(tester.takeException(), isNull);
      await goTo(tester, container, projectPath('flutter-natif'));
      expect(tester.takeException(), isNull);
    });
  });
}
