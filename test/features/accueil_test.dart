import 'package:druide_and_droiid/app/sections.dart';
import 'package:druide_and_droiid/features/accueil/domain/flash_questions.dart';
import 'package:druide_and_droiid/features/progression/data/progress_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

/// Les flux Drift ont besoin du temps réel, absent de `testWidgets`.
Future<int> storedXp(WidgetTester tester, ProviderContainer container) async {
  final progress = await tester.runAsync(
    () => container.read(progressRepositoryProvider).watch().first,
  );
  return progress!.xp;
}

Future<void> answer(WidgetTester tester, {required bool correctly}) async {
  final question = flashQuestionFor(DateTime.now());
  final wrong = question.answerIndex == 0 ? 1 : 0;
  final option = question.options[correctly ? question.answerIndex : wrong];

  await tester.scrollUntilVisible(
    find.text(option),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(find.text(option));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('une bonne réponse crédite l\'expérience et l\'affiche', (
    tester,
  ) async {
    final container = await pumpApp(tester);

    await answer(tester, correctly: true);

    expect(await storedXp(tester, container), flashQuizXp);
    expect(find.text('+$flashQuizXp XP gagnés !'), findsOneWidget);
    expect(find.textContaining('réponse du jour est enregistrée'), findsOne);
  });

  testWidgets('se tromper puis recommencer ne rapporte rien', (tester) async {
    final container = await pumpApp(tester);

    await answer(tester, correctly: false);
    await tester.tap(find.text('Recommencer'));
    await tester.pumpAndSettle();
    await answer(tester, correctly: true);

    expect(await storedXp(tester, container), 0);
  });

  testWidgets('répondre juste deux fois ne crédite qu\'une fois', (
    tester,
  ) async {
    final container = await pumpApp(tester);

    await answer(tester, correctly: true);
    await tester.tap(find.text('Recommencer'));
    await tester.pumpAndSettle();
    await answer(tester, correctly: true);

    expect(await storedXp(tester, container), flashQuizXp);
  });

  testWidgets('la page Progression reflète l\'expérience gagnée', (
    tester,
  ) async {
    final container = await pumpApp(tester);

    await answer(tester, correctly: true);
    await goTo(tester, container, AppSection.progression.path);

    expect(find.text('$flashQuizXp / 100 XP'), findsOneWidget);
  });
}
