import 'dart:convert';
import 'dart:io';

import 'package:druide_and_droiid/app/sections.dart';
import 'package:druide_and_droiid/features/academie/data/exercise_repository.dart';
import 'package:druide_and_droiid/features/academie/domain/course.dart';
import 'package:druide_and_droiid/features/academie/domain/rewards.dart';
import 'package:druide_and_droiid/features/academie/presentation/paths.dart';
import 'package:druide_and_droiid/features/progression/data/progress_repository.dart';
import 'package:druide_and_droiid/features/progression/domain/progression.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

const moduleId = 'fondations';
const tall = Size(800, 9000);

final course = Course.fromJson(
  jsonDecode(File('assets/courses/$moduleId.json').readAsStringSync())
      as Map<String, Object?>,
);
final firstLesson = course.lessons.first;

Future<ProgressSnapshot> storedProgress(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final progress = await tester.runAsync(
    () => container.read(progressRepositoryProvider).watch().first,
  );
  return progress!;
}

Future<void> openLesson(
  WidgetTester tester,
  ProviderContainer container, [
  Lesson? lesson,
]) {
  return goTo(
    tester,
    container,
    lessonPath(moduleId, (lesson ?? firstLesson).id),
  );
}

/// Répond à tout le quiz, en se trompant aux indices [wrong].
Future<void> answerQuiz(
  WidgetTester tester,
  List<CourseQuestion> questions, {
  Set<int> wrong = const {},
}) async {
  for (final (index, question) in questions.indexed) {
    final options = wrong.contains(index)
        ? {question.answers.first == 0 ? 1 : 0}
        : question.answers;
    for (final option in options) {
      await tester.tap(find.text(question.options[option]).first);
      await tester.pump();
    }
  }
  await tester.tap(find.text('Valider mes réponses'));
  await tester.pumpAndSettle();
}

/// Termine toutes les leçons sans passer par l'écran.
Future<void> completeAllLessons(
  WidgetTester tester,
  ProviderContainer container,
) async {
  // Le temps simulé doit avancer entre deux écritures, sinon les flux de
  // l'écran gardent le verrou de la base et la suivante attend indéfiniment.
  for (final lesson in course.lessons) {
    await tester.runAsync(
      () => container
          .read(progressRepositoryProvider)
          .completeLesson(lessonId: lesson.id, moduleId: moduleId, xp: 0),
    );
    await tester.pumpAndSettle();
  }
}

class _SingleModuleBundle extends DiskAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) {
    if (key.endsWith('index.json')) {
      return Future.value('{"modules": ["$moduleId"]}');
    }
    return super.loadString(key, cache: cache);
  }
}

class _BrokenBundle extends DiskAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) {
    if (key.endsWith('$moduleId.json')) {
      return Future.value('{"moduleId": "$moduleId"}');
    }
    return super.loadString(key, cache: cache);
  }
}

void main() {
  group('leçon', () {
    testWidgets('affiche titre, contenu et avancement', (tester) async {
      final container = await pumpApp(tester, size: tall);
      await openLesson(tester, container);

      expect(find.text(firstLesson.title), findsOneWidget);
      expect(find.text('Leçon 1 / ${course.lessons.length}'), findsOneWidget);
      expect(find.text('Valider mes réponses'), findsNothing);
      expect(find.textContaining('Répondez à toutes'), findsOneWidget);
    });

    testWidgets('le schéma en couches et le code s\'affichent', (tester) async {
      final container = await pumpApp(tester, size: tall);

      await openLesson(tester, container, course.lessons[2]);
      expect(find.text('Noyau Linux'), findsWidgets);

      await openLesson(tester, container, course.lessons[1]);
      expect(find.byTooltip('Copier le code'), findsWidgets);
    });

    testWidgets('terminer enregistre, crédite et passe à la suivante', (
      tester,
    ) async {
      final container = await pumpApp(tester, size: tall);
      await openLesson(tester, container);

      await tester.tap(find.text('Terminer la leçon'));
      await tester.pumpAndSettle();

      expect(location(container), lessonPath(moduleId, course.lessons[1].id));
      final progress = await storedProgress(tester, container);
      expect(progress.lessonsCompleted, 1);
      expect(progress.xp, Rewards.lesson);
    });

    testWidgets('la dernière leçon revient au module', (tester) async {
      final container = await pumpApp(tester, size: tall);
      await openLesson(tester, container, course.lessons.last);

      await tester.tap(find.text('Terminer la leçon'));
      await tester.pumpAndSettle();

      expect(location(container), modulePath(moduleId));
    });

    testWidgets('rouvrir une leçon terminée ne recrédite rien', (tester) async {
      final container = await pumpApp(tester, size: tall);
      await openLesson(tester, container);
      await tester.tap(find.text('Terminer la leçon'));
      await tester.pumpAndSettle();

      await openLesson(tester, container);
      expect(find.text('Terminée'), findsOneWidget);
      await tester.tap(find.text('Leçon suivante'));
      await tester.pumpAndSettle();

      expect((await storedProgress(tester, container)).xp, Rewards.lesson);
    });

    testWidgets('une leçon inconnue affiche la page introuvable', (
      tester,
    ) async {
      final container = await pumpApp(tester);

      await goTo(tester, container, lessonPath(moduleId, 'fantome'));

      expect(find.text('Page introuvable'), findsOneWidget);
    });

    testWidgets('un cours illisible affiche un message d\'erreur', (
      tester,
    ) async {
      final container = await pumpApp(tester, bundle: _BrokenBundle());

      await openLesson(tester, container);

      expect(find.textContaining('pas pu être chargée'), findsOneWidget);
    });

    testWidgets('le module affiche la même erreur sans planter', (
      tester,
    ) async {
      final container = await pumpApp(tester, bundle: _BrokenBundle());

      await goTo(tester, container, modulePath(moduleId));

      expect(find.textContaining('pas pu être chargé'), findsOneWidget);
    });
  });

  group('quiz', () {
    testWidgets('toutes bonnes réponses : réussi, enregistré, crédité', (
      tester,
    ) async {
      final container = await pumpApp(tester, size: tall);
      await openLesson(tester, container);

      await answerQuiz(tester, firstLesson.quiz);

      final total = firstLesson.quiz.length;
      expect(find.textContaining('$total / $total. Réussi'), findsOneWidget);
      final progress = await storedProgress(tester, container);
      expect(progress.quizzesPassed, 1);
      expect(progress.xp, Rewards.quiz);
    });

    testWidgets('sous le seuil : échec sans expérience, corrections visibles', (
      tester,
    ) async {
      final container = await pumpApp(tester, size: tall);
      await openLesson(tester, container);

      await answerQuiz(tester, firstLesson.quiz, wrong: {0, 1, 2});

      expect(find.textContaining('Relisez les corrections'), findsOneWidget);
      expect(find.text(firstLesson.quiz.first.explanation), findsOneWidget);
      final progress = await storedProgress(tester, container);
      expect(progress.quizzesPassed, 0);
      expect(progress.xp, 0);
    });

    testWidgets('Recommencer efface et réussir ensuite crédite une fois', (
      tester,
    ) async {
      final container = await pumpApp(tester, size: tall);
      await openLesson(tester, container);

      await answerQuiz(tester, firstLesson.quiz, wrong: {0});
      await tester.tap(find.text('Recommencer'));
      await tester.pumpAndSettle();
      expect(find.textContaining('(0 / '), findsOneWidget);

      await answerQuiz(tester, firstLesson.quiz);
      await tester.tap(find.text('Recommencer'));
      await tester.pumpAndSettle();
      await answerQuiz(tester, firstLesson.quiz);

      expect((await storedProgress(tester, container)).xp, Rewards.quiz);
    });

    testWidgets('les réponses cochées survivent au défilement', (tester) async {
      final container = await pumpApp(tester);
      await openLesson(tester, container);
      final option = firstLesson.quiz.first.options.first;
      final list = find.byType(Scrollable).first;

      await tester.scrollUntilVisible(find.text(option), 400, scrollable: list);
      await tester.tap(find.text(option));
      await tester.pump();
      expect(find.textContaining('(1 / '), findsOneWidget);

      await tester.drag(list, const Offset(0, 6000));
      await tester.pumpAndSettle();
      expect(find.text(option), findsNothing);
      await tester.scrollUntilVisible(
        find.textContaining('(1 / '),
        400,
        scrollable: list,
      );

      expect(find.textContaining('(1 / '), findsOneWidget);
    });
  });

  group('exercices', () {
    final fill = firstLesson.exercises[0];
    final self = firstLesson.exercises[1];

    Finder answerField(String prompt) => find.descendant(
      of: find
          .ancestor(of: find.text(prompt), matching: find.byType(Column))
          .first,
      matching: find.byType(TextField),
    );

    testWidgets('une bonne réponse courte est validée et créditée', (
      tester,
    ) async {
      final container = await pumpApp(tester, size: tall);
      await openLesson(tester, container);

      await tester.enterText(answerField(fill.prompt), 'aosp');
      await tester.tap(find.text('Vérifier'));
      await tester.pumpAndSettle();

      expect(find.text('Exercice réussi.'), findsOneWidget);
      expect((await storedProgress(tester, container)).xp, Rewards.exercise);
    });

    testWidgets('une mauvaise réponse propose la correction, sans crédit', (
      tester,
    ) async {
      final container = await pumpApp(tester, size: tall);
      await openLesson(tester, container);

      await tester.enterText(answerField(fill.prompt), 'dalvik');
      await tester.tap(find.text('Vérifier'));
      await tester.pumpAndSettle();

      expect(find.textContaining('pas la réponse attendue'), findsOneWidget);
      expect((await storedProgress(tester, container)).xp, 0);
      expect(find.text(fill.solution), findsNothing);

      await tester.tap(find.text('Voir la correction').first);
      await tester.pumpAndSettle();
      expect(find.text(fill.solution), findsOneWidget);
    });

    testWidgets('l\'autoévaluation montre le corrigé puis enregistre', (
      tester,
    ) async {
      final container = await pumpApp(tester, size: tall);
      await openLesson(tester, container);

      await tester.enterText(answerField(self.prompt), 'Ma réponse');
      await tester.tap(find.text('Voir la correction'));
      await tester.pumpAndSettle();
      expect(find.text(self.solution), findsOneWidget);

      await tester.tap(find.text('J\'ai réussi'));
      await tester.pumpAndSettle();

      expect(find.text('Exercice réussi.'), findsOneWidget);
      final saved = await tester.runAsync(
        () => container.read(exerciseRepositoryProvider).find(self.id),
      );
      expect(saved?.text, 'Ma réponse');
      expect(saved?.status, ExerciseStatus.success);
    });

    testWidgets('« À retravailler » ne rapporte rien', (tester) async {
      final container = await pumpApp(tester, size: tall);
      await openLesson(tester, container);

      await tester.tap(find.text('Voir la correction'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('À retravailler'));
      await tester.pumpAndSettle();

      expect(find.text('Marqué à retravailler.'), findsOneWidget);
      expect((await storedProgress(tester, container)).xp, 0);
    });

    testWidgets('le texte saisi revient en rouvrant la leçon', (tester) async {
      final container = await pumpApp(tester, size: tall);
      await openLesson(tester, container);

      await tester.enterText(answerField(self.prompt), 'Brouillon');
      await tester.pump();

      await goTo(tester, container, modulePath(moduleId));
      await tester.pump(const Duration(seconds: 1));
      await openLesson(tester, container);
      await tester.pumpAndSettle();

      expect(find.text('Brouillon'), findsOneWidget);
    });
  });

  group('module et évaluation', () {
    testWidgets('le module liste les leçons et leur avancement', (
      tester,
    ) async {
      final container = await pumpApp(tester, size: tall);
      await goTo(tester, container, modulePath(moduleId));

      expect(find.text('1. ${firstLesson.title}'), findsOneWidget);
      expect(find.text('0 / ${course.lessons.length} leçons'), findsOneWidget);
      expect(find.text('Pour aller plus loin'), findsOneWidget);

      await tester.tap(find.text('1. ${firstLesson.title}'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Terminer la leçon'));
      await tester.pumpAndSettle();
      await goTo(tester, container, modulePath(moduleId));

      expect(find.text('1 / ${course.lessons.length} leçons'), findsOneWidget);
    });

    testWidgets('un module sans contenu l\'indique', (tester) async {
      final container = await pumpApp(tester, size: tall);

      await goTo(tester, container, modulePath('java'));

      expect(find.textContaining('pas encore rédigées'), findsOneWidget);
    });

    testWidgets('l\'évaluation reste fermée tant que des leçons manquent', (
      tester,
    ) async {
      final container = await pumpApp(tester, size: tall);

      await goTo(tester, container, evaluationPath(moduleId));

      expect(
        find.textContaining('il en reste ${course.lessons.length}'),
        findsOneWidget,
      );
      expect(find.text(course.evaluation.questions.first.prompt), findsNothing);
    });

    testWidgets('réussir valide le module et crédite une fois', (tester) async {
      final container = await pumpApp(tester, size: tall);
      await completeAllLessons(tester, container);
      await goTo(tester, container, evaluationPath(moduleId));

      expect(find.textContaining('certification'), findsOneWidget);
      await answerQuiz(tester, course.evaluation.questions);

      expect((await storedProgress(tester, container)).xp, Rewards.evaluation);

      await goTo(tester, container, modulePath(moduleId));
      expect(find.textContaining('réussie'), findsOneWidget);
      await goTo(tester, container, AppSection.academie.path);
      expect(find.text('Validé'), findsOneWidget);
    });

    testWidgets('échouer n\'empêche pas de retenter', (tester) async {
      final container = await pumpApp(tester, size: tall);
      await completeAllLessons(tester, container);
      await goTo(tester, container, evaluationPath(moduleId));

      await answerQuiz(tester, course.evaluation.questions, wrong: {0, 1, 2});
      expect(find.textContaining('Relisez les corrections'), findsOneWidget);
      expect((await storedProgress(tester, container)).xp, 0);

      await tester.tap(find.text('Recommencer'));
      await tester.pumpAndSettle();
      await answerQuiz(tester, course.evaluation.questions);

      expect((await storedProgress(tester, container)).xp, Rewards.evaluation);
    });
  });

  group('reprise depuis l\'accueil', () {
    testWidgets('propose la première leçon non terminée', (tester) async {
      await pumpApp(tester);

      expect(find.text('Continuer : ${firstLesson.title}'), findsOneWidget);
    });

    testWidgets('avance après une leçon terminée', (tester) async {
      final container = await pumpApp(tester);

      await tester.runAsync(
        () => container
            .read(progressRepositoryProvider)
            .completeLesson(
              lessonId: firstLesson.id,
              moduleId: moduleId,
              xp: 0,
            ),
      );
      await tester.pumpAndSettle();
      await tester.pump();

      expect(
        find.text('Continuer : ${course.lessons[1].title}'),
        findsOneWidget,
      );
    });

    testWidgets('passe au module suivant, puis à l\'Académie à la fin', (
      tester,
    ) async {
      final container = await pumpApp(tester, bundle: _SingleModuleBundle());

      await completeAllLessons(tester, container);
      await tester.pump();

      expect(find.text('Découvrir l\'Académie'), findsOneWidget);
    });
  });
}
