import 'package:druide_and_droiid/app/theme/app_theme.dart';
import 'package:druide_and_droiid/design_system/code_highlighter.dart';
import 'package:druide_and_droiid/design_system/code_panel.dart';
import 'package:druide_and_droiid/design_system/grimoire_panel.dart';
import 'package:druide_and_droiid/design_system/mascot/maitre_and_droiid.dart';
import 'package:druide_and_droiid/design_system/motion.dart';
import 'package:druide_and_droiid/design_system/quiz_card.dart';
import 'package:druide_and_droiid/design_system/rune_badge.dart';
import 'package:druide_and_droiid/design_system/xp_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget harness(Widget child, {MotionLevel motion = MotionLevel.none}) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: MotionScope(
      level: motion,
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

const question = QuizQuestion(
  prompt: 'Question ?',
  options: ['Mauvaise', 'Bonne'],
  answerIndex: 1,
  explanation: 'Parce que.',
);

void main() {
  group('QuizCard', () {
    testWidgets('corrige une bonne réponse et explique', (tester) async {
      await tester.pumpWidget(harness(const QuizCard(question: question)));

      expect(find.text('Parce que.'), findsNothing);
      await tester.tap(find.text('Bonne'));
      await tester.pumpAndSettle();

      expect(find.text('Bien joué !'), findsOneWidget);
      expect(find.text('Parce que.'), findsOneWidget);
    });

    testWidgets('signale une mauvaise réponse et fige le choix', (
      tester,
    ) async {
      await tester.pumpWidget(harness(const QuizCard(question: question)));

      await tester.tap(find.text('Mauvaise'));
      await tester.pumpAndSettle();
      expect(find.text('Pas tout à fait.'), findsOneWidget);

      await tester.tap(find.text('Bonne'));
      await tester.pumpAndSettle();
      expect(find.text('Bien joué !'), findsNothing);
    });

    testWidgets('Recommencer efface la correction', (tester) async {
      await tester.pumpWidget(harness(const QuizCard(question: question)));

      await tester.tap(find.text('Bonne'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recommencer'));
      await tester.pumpAndSettle();

      expect(find.text('Bien joué !'), findsNothing);
      await tester.tap(find.text('Mauvaise'));
      await tester.pumpAndSettle();
      expect(find.text('Pas tout à fait.'), findsOneWidget);
    });
  });

  group('MaitreAndDroiid', () {
    testWidgets('se dessine dans chaque humeur', (tester) async {
      for (final mood in MascotMood.values) {
        await tester.pumpWidget(harness(MaitreAndDroiid(mood: mood)));
        expect(tester.takeException(), isNull, reason: mood.name);
      }
    });

    testWidgets('ne tourne en boucle qu\'avec toutes les animations', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(const MaitreAndDroiid(), motion: MotionLevel.reduced),
      );
      expect(tester.binding.transientCallbackCount, 0);

      await tester.pumpWidget(
        harness(const MaitreAndDroiid(), motion: MotionLevel.full),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.transientCallbackCount, greaterThan(0));

      // Le passage en mode réduit doit arrêter une boucle déjà lancée.
      await tester.pumpWidget(
        harness(const MaitreAndDroiid(), motion: MotionLevel.reduced),
      );
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
    });
  });

  testWidgets('GrimoirePanel se déplie et se replie', (tester) async {
    await tester.pumpWidget(
      harness(
        const GrimoirePanel(
          title: 'Chapitre',
          icon: Icons.book,
          child: Text('Contenu'),
        ),
      ),
    );
    expect(find.text('Contenu'), findsNothing);

    await tester.tap(find.text('Chapitre'));
    await tester.pumpAndSettle();
    expect(find.text('Contenu'), findsOneWidget);

    await tester.tap(find.text('Chapitre'));
    await tester.pumpAndSettle();
    expect(find.text('Contenu'), findsNothing);
  });

  testWidgets('CodePanel copie réellement le code', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );

    await tester.pumpWidget(
      harness(
        const CodePanel(code: 'val a = 1', language: CodeLanguage.kotlin),
      ),
    );
    await tester.tap(find.byTooltip('Copier le code'));
    await tester.pump();

    final copy = calls.singleWhere((c) => c.method == 'Clipboard.setData');
    expect((copy.arguments as Map)['text'], 'val a = 1');
    expect(find.text('Code copié dans le presse-papiers.'), findsOneWidget);
  });

  group('XpBar', () {
    testWidgets('annonce sa valeur aux lecteurs d\'écran', (tester) async {
      await tester.pumpWidget(
        harness(const XpBar(xp: 150, floor: 100, ceiling: 300)),
      );

      expect(find.bySemanticsLabel('Expérience'), findsOneWidget);
      expect(find.text('150 / 300 XP'), findsOneWidget);
    });

    testWidgets('remplit proportionnellement et reste dans ses bornes', (
      tester,
    ) async {
      double factor() => tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor!;

      await tester.pumpWidget(
        harness(const XpBar(xp: 200, floor: 100, ceiling: 300)),
      );
      await tester.pumpAndSettle();
      expect(factor(), 0.5);

      await tester.pumpWidget(
        harness(const XpBar(xp: 900, floor: 100, ceiling: 300)),
      );
      await tester.pumpAndSettle();
      expect(factor(), 1);

      // Dernier grade : plancher et plafond sont égaux.
      await tester.pumpWidget(
        harness(const XpBar(xp: 3000, floor: 3000, ceiling: 3000)),
      );
      await tester.pumpAndSettle();
      expect(factor(), 1);
    });
  });

  testWidgets('RuneBadge verrouillé remplace son icône par un cadenas', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const RuneBadge(icon: Icons.star, label: 'Grade', unlocked: false),
      ),
    );

    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNothing);
    expect(find.bySemanticsLabel('Grade, verrouillé'), findsOneWidget);
  });
}
