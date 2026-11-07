import 'package:druide_and_droiid/app/sections.dart';
import 'package:druide_and_droiid/features/lab/data/code_runner.dart';
import 'package:druide_and_droiid/features/lab/data/lab_platform.dart';
import 'package:druide_and_droiid/features/lab/data/tool_commands.dart';
import 'package:druide_and_droiid/features/lab/data/tool_detector.dart';
import 'package:druide_and_droiid/features/lab/domain/lab_exercise.dart';
import 'package:druide_and_droiid/features/lab/domain/lab_tools.dart';
import 'package:druide_and_droiid/features/lab/presentation/code_editor.dart';
import 'package:druide_and_droiid/features/lab/presentation/lab_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_app.dart';

const tall = Size(420, 1800);

class FakeRunner implements CodeRunner {
  FakeRunner(this.result);

  RunResult result;
  final codes = <String>[];

  @override
  Future<RunResult> run(
    LabExercise exercise,
    String code, {
    RunCancel? cancel,
    void Function(String step)? onStep,
  }) async {
    codes.add(code);
    return result;
  }
}

class FakeExporter implements CodeExporter {
  final exported = <(String, String)>[];

  @override
  Future<String?> export(String fileName, String code) async {
    exported.add((fileName, code));
    return '/tmp/$fileName';
  }
}

class FakeCommands implements ToolCommands {
  final launched = <String>[];

  @override
  Future<CommandResult> run(LabCommand command) async =>
      const CommandResult('Pixel_9');

  @override
  Future<void> openAndroidStudio() async => launched.add('studio');

  @override
  Future<void> startEmulator(String avd) async => launched.add(avd);
}

List<Override> linux(CodeRunner runner, CodeExporter exporter) => [
  labCapabilitiesProvider.overrideWithValue(
    const LabCapabilities(canRunCode: true),
  ),
  codeRunnerProvider.overrideWithValue(runner),
  codeExporterProvider.overrideWithValue(exporter),
];

final android = [
  labCapabilitiesProvider.overrideWithValue(
    const LabCapabilities(canRunCode: false),
  ),
];

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).first);
  await tester.pumpAndSettle();
}

Future<void> waitToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sur téléphone, le Lab dit qu\'il n\'exécute rien', (
    tester,
  ) async {
    final container = await pumpApp(
      tester,
      size: tall,
      extraOverrides: android,
    );
    await goTo(tester, container, AppSection.lab.path);
    expect(find.textContaining('Le Lab ne simule rien'), findsOneWidget);
    expect(find.text('Outils Linux'), findsNothing);

    await goTo(tester, container, labEditorPath('kt-niveau'));
    expect(find.text('Exécuter'), findsNothing);
    expect(find.textContaining('pas disponible'), findsOneWidget);
    expect(find.text('Je valide moi-même'), findsOneWidget);
  });

  testWidgets('le XML est réellement analysé, même sur téléphone', (
    tester,
  ) async {
    final container = await pumpApp(
      tester,
      size: tall,
      extraOverrides: android,
    );
    await goTo(tester, container, labEditorPath('xml-permission'));

    await tapText(tester, 'Analyser le XML');
    expect(find.textContaining('Élément attendu'), findsWidgets);

    await tester.enterText(find.byType(TextField), '<manifest>');
    await tester.pump();
    await tapText(tester, 'Analyser le XML');
    expect(find.textContaining('XML invalide'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      '<manifest><uses-permission android:name='
      '"android.permission.CAMERA" /></manifest>',
    );
    await tester.pump();
    await tapText(tester, 'Analyser le XML');
    expect(find.text('Exercice réussi.'), findsOneWidget);
    await waitToast(tester);
  });

  testWidgets('sur Linux, exécuter demande un accord puis compare la sortie', (
    tester,
  ) async {
    final runner = FakeRunner(
      const RunResult(output: 'Niveau 1\nNiveau 2\nNiveau 3\n', exitCode: 0),
    );
    final container = await pumpApp(
      tester,
      size: tall,
      extraOverrides: linux(runner, FakeExporter()),
    );
    await goTo(tester, container, labEditorPath('kt-niveau'));

    await tapText(tester, 'Exécuter');
    expect(find.text('Exécuter du code sur cet ordinateur ?'), findsOneWidget);
    await tapText(tester, 'Annuler');
    expect(runner.codes, isEmpty);

    await tapText(tester, 'Exécuter');
    await tapText(tester, 'J\'ai compris');
    expect(runner.codes, hasLength(1));
    expect(find.text('Résultat réel de l\'exécution'), findsOneWidget);
    expect(find.textContaining('correspond à la sortie'), findsOneWidget);
    expect(find.text('Exercice réussi.'), findsOneWidget);
    await waitToast(tester);

    await tapText(tester, 'Exécuter');
    expect(find.text('Exécuter du code sur cet ordinateur ?'), findsNothing);
    expect(runner.codes, hasLength(2));
  });

  testWidgets('une sortie fausse n\'est pas validée', (tester) async {
    final runner = FakeRunner(const RunResult(output: 'Faux', exitCode: 0));
    final container = await pumpApp(
      tester,
      size: tall,
      extraOverrides: linux(runner, FakeExporter()),
    );
    await goTo(tester, container, labEditorPath('kt-null'));

    await tapText(tester, 'Exécuter');
    await tapText(tester, 'J\'ai compris');

    expect(find.textContaining('diffère de la sortie'), findsOneWidget);
    expect(find.text('Exercice réussi.'), findsNothing);
  });

  testWidgets('une erreur de compilation s\'affiche', (tester) async {
    final runner = FakeRunner(
      const RunResult(
        errors: 'Main.kt:1: error',
        exitCode: 1,
        compileFailed: true,
      ),
    );
    final container = await pumpApp(
      tester,
      size: tall,
      extraOverrides: linux(runner, FakeExporter()),
    );
    await goTo(tester, container, labEditorPath('kt-null'));

    await tapText(tester, 'Exécuter');
    await tapText(tester, 'J\'ai compris');

    expect(find.textContaining('Main.kt:1'), findsOneWidget);
    expect(find.text('La compilation a échoué.'), findsOneWidget);
  });

  testWidgets('le code se retrouve après avoir quitté l\'éditeur', (
    tester,
  ) async {
    final container = await pumpApp(
      tester,
      size: tall,
      extraOverrides: android,
    );
    await goTo(tester, container, labEditorPath('kt-null'));
    await tester.enterText(find.byType(TextField), 'val monCode = 1');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    await goTo(tester, container, AppSection.lab.path);
    await goTo(tester, container, labEditorPath('kt-null'));

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'val monCode = 1');
  });

  testWidgets('versions, comparaison et retour en arrière', (tester) async {
    final container = await pumpApp(
      tester,
      size: tall,
      extraOverrides: android,
    );
    await goTo(tester, container, labEditorPath('kt-null'));

    await tester.enterText(find.byType(TextField), 'version un');
    await tester.pump();
    await tapText(tester, 'Enregistrer une version');
    await waitToast(tester);

    await tester.enterText(find.byType(TextField), 'version deux');
    await tester.pump();
    await tapText(tester, 'Historique');
    expect(find.text('Version enregistrée'), findsOneWidget);

    await tapText(tester, 'Comparer à mon code actuel');
    expect(
      find.textContaining('− version un', findRichText: true),
      findsOneWidget,
    );

    await tapText(tester, 'Revenir à cette version');
    await waitToast(tester);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'version un');
  });

  testWidgets('le corrigé demande confirmation avant de s\'afficher', (
    tester,
  ) async {
    final container = await pumpApp(
      tester,
      size: tall,
      extraOverrides: android,
    );
    await goTo(tester, container, labEditorPath('kt-null'));

    await tapText(tester, 'Comparer au corrigé');
    expect(find.text('Afficher le corrigé ?'), findsOneWidget);
    await tapText(tester, 'Afficher');

    expect(find.textContaining('Corrigé'), findsWidgets);
    expect(
      find.textContaining('+     return texte?.length', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('réinitialiser garde le code dans l\'historique', (tester) async {
    final container = await pumpApp(
      tester,
      size: tall,
      extraOverrides: android,
    );
    await goTo(tester, container, labEditorPath('kt-null'));
    await tester.enterText(find.byType(TextField), 'mon essai');
    await tester.pump();

    await tapText(tester, 'Réinitialiser');
    await tester.tap(find.widgetWithText(FilledButton, 'Réinitialiser'));
    await tester.pumpAndSettle();
    await waitToast(tester);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, contains('fun longueur'));

    await tapText(tester, 'Historique');
    expect(find.text('Avant retour en arrière'), findsOneWidget);
  });

  testWidgets('exporter envoie le code courant', (tester) async {
    final exporter = FakeExporter();
    final container = await pumpApp(
      tester,
      size: tall,
      extraOverrides: linux(FakeRunner(const RunResult()), exporter),
    );
    await goTo(tester, container, labEditorPath('libre-java'));

    await tapText(tester, 'Exporter');

    expect(exporter.exported.single.$1, 'Main.java');
    expect(exporter.exported.single.$2, contains('Bonjour'));
    expect(find.textContaining('/tmp/Main.java'), findsOneWidget);
    await waitToast(tester);
  });

  testWidgets('la touche Tabulation insère des espaces', (tester) async {
    final container = await pumpApp(
      tester,
      size: tall,
      extraOverrides: android,
    );
    await goTo(tester, container, labEditorPath('libre-dart'));
    final field = find.byType(TextField);
    await tester.enterText(field, 'a');
    await tester.pump();

    final controller =
        tester.widget<TextField>(field).controller! as CodeEditingController;
    controller.insertAtCursor('    ');
    expect(controller.text, 'a    ');
  });

  testWidgets('un exercice inconnu donne une page introuvable', (tester) async {
    final container = await pumpApp(tester, extraOverrides: android);
    await goTo(tester, container, labEditorPath('absent'));

    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('les outils affichent la détection et la procédure', (
    tester,
  ) async {
    final commands = FakeCommands();
    final container = await pumpApp(
      tester,
      size: const Size(420, 3200),
      extraOverrides: [
        labCapabilitiesProvider.overrideWithValue(
          const LabCapabilities(canRunCode: true),
        ),
        labToolchainProvider.overrideWithValue(
          const LabToolchain(
            paths: {
              LabTool.emulator: '/sdk/emulator',
              LabTool.androidStudio: '/opt/studio.sh',
            },
          ),
        ),
        toolCommandsProvider.overrideWithValue(commands),
      ],
    );
    await goTo(tester, container, labToolsPath);

    expect(find.text('/sdk/emulator'), findsOneWidget);
    expect(find.textContaining('sudo apt install adb'), findsOneWidget);
    expect(find.text('Non détecté.'), findsWidgets);

    await tapText(tester, 'Appareils virtuels');
    expect(find.text('Appareils virtuels : résultat réel'), findsOneWidget);

    await tapText(tester, 'Démarrer Pixel_9');
    expect(find.text('Démarrer Pixel_9 ?'), findsOneWidget);
    await tapText(tester, 'Annuler');
    expect(commands.launched, isEmpty);

    await tapText(tester, 'Démarrer Pixel_9');
    await tapText(tester, 'Lancer');
    expect(commands.launched, ['Pixel_9']);
    await waitToast(tester);
  });

  testWidgets('les écrans du Lab tiennent sur un petit écran', (tester) async {
    final container = await pumpApp(
      tester,
      size: const Size(320, 568),
      extraOverrides: android,
    );
    await goTo(tester, container, AppSection.lab.path);
    expect(tester.takeException(), isNull);
    await goTo(tester, container, labEditorPath('java-flux'));
    expect(tester.takeException(), isNull);
  });
}
