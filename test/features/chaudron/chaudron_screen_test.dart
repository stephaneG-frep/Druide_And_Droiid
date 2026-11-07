import 'package:druide_and_droiid/app/sections.dart';
import 'package:druide_and_droiid/features/chaudron/data/log_importer.dart';
import 'package:druide_and_droiid/features/chaudron/domain/bug_rule.dart';
import 'package:druide_and_droiid/features/chaudron/presentation/chaudron_paths.dart';
import 'package:druide_and_droiid/features/maitre/data/ai_clients.dart';
import 'package:druide_and_droiid/features/maitre/data/ai_settings_repository.dart';
import 'package:druide_and_droiid/features/maitre/domain/ai_chat.dart';
import 'package:druide_and_droiid/features/maitre/domain/ai_provider.dart';
import 'package:druide_and_droiid/features/maitre/presentation/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_app.dart';

const tall = Size(420, 2400);

class FakeImporter implements LogImporter {
  FakeImporter(this.log);

  final ImportedLog? log;

  @override
  Future<ImportedLog?> pick() async => log;
}

class RecordingClient implements AiClient {
  final requests = <AiRequest>[];

  @override
  Stream<AiEvent> chat(AiRequest request) {
    requests.add(request);
    return Stream.fromIterable(const [
      AiTextDelta('Résumé du problème : une panne.'),
      AiDone(AiStopReason.complete),
    ]);
  }

  @override
  Future<List<String>> listModels() async => [];

  @override
  void abort() {}
}

List<Override> withClient(AiClient client) => [
  aiClientBuilderProvider.overrideWithValue((config) async => client),
];

Future<void> configureOllama(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final settings = container.read(aiSettingsRepositoryProvider);
  await tester.runAsync(() async {
    await settings.saveConfig(
      const AiProviderConfig(
        kind: AiProviderKind.ollama,
        baseUrl: 'http://127.0.0.1:11434',
        model: 'm',
      ),
    );
    await settings.setActive(AiProviderKind.ollama);
  });
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).first);
  await tester.pumpAndSettle();
}

Future<void> openCase(WidgetTester tester, String error) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'Message d\'erreur ou journal'),
    error,
  );
  await tester.pump();
  await tapText(tester, 'Jeter dans le chaudron');
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets(
    'sans IA, une erreur connue donne sa fiche, signalée comme telle',
    (tester) async {
      final container = await pumpApp(tester, size: tall);
      await goTo(tester, container, AppSection.chaudron.path);

      await openCase(tester, 'Failure [INSTALL_FAILED_NO_MATCHING_ABIS]');

      expect(find.text('Aucune architecture compatible'), findsOneWidget);
      expect(find.textContaining('Ce n\'est pas une IA'), findsOneWidget);
      expect(find.text('Résumé du problème'), findsOneWidget);
      expect(find.text('Causes possibles'), findsOneWidget);
      expect(find.text('Vérifications recommandées'), findsOneWidget);
      expect(find.text('Corrections proposées'), findsOneWidget);
      expect(find.text('Explication pédagogique'), findsOneWidget);
      expect(find.text('Procédure de validation'), findsOneWidget);
      expect(find.text('Demander une analyse IA'), findsNothing);
      expect(find.textContaining('Aucun fournisseur IA'), findsOneWidget);
      expect(find.text('État : Non vérifié'), findsOneWidget);
    },
  );

  testWidgets('une erreur inconnue le dit honnêtement', (tester) async {
    final container = await pumpApp(tester, size: tall);
    await goTo(tester, container, AppSection.chaudron.path);

    await openCase(tester, 'Une panne jamais vue');

    expect(find.textContaining('Aucune panne connue'), findsOneWidget);
  });

  testWidgets('un dossier vide est refusé', (tester) async {
    final container = await pumpApp(tester, size: tall);
    await goTo(tester, container, AppSection.chaudron.path);

    await tapText(tester, 'Jeter dans le chaudron');

    expect(find.textContaining('Collez une erreur'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('importer un fichier remplit le champ', (tester) async {
    final container = await pumpApp(
      tester,
      size: tall,
      extraOverrides: [
        logImporterProvider.overrideWithValue(
          FakeImporter(
            const ImportedLog(
              'build.log',
              'Duplicate class a',
              truncated: true,
            ),
          ),
        ),
      ],
    );
    await goTo(tester, container, AppSection.chaudron.path);

    await tapText(tester, 'Importer un fichier');

    expect(find.text('Duplicate class a'), findsOneWidget);
    expect(find.textContaining('seule sa fin'), findsOneWidget);
  });

  testWidgets('l\'analyse IA montre ce qui part, sans les secrets', (
    tester,
  ) async {
    final client = RecordingClient();
    final container = await pumpApp(
      tester,
      size: tall,
      extraOverrides: withClient(client),
    );
    await configureOllama(tester, container);
    await goTo(tester, container, AppSection.chaudron.path);

    await openCase(
      tester,
      'Unresolved reference Foo\nstorePassword=MonSecret\n/home/ana/Main.kt',
    );
    await tapText(tester, 'Demander une analyse IA');

    expect(find.text('Vérifiez ce qui sera envoyé'), findsOneWidget);
    expect(find.textContaining('2 élément(s) masqué(s)'), findsOneWidget);
    final preview = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(SelectableText),
    );
    final shown = tester.widget<SelectableText>(preview).data!;
    expect(shown, isNot(contains('MonSecret')));
    expect(shown, contains('storePassword=[masqué]'));

    await tapText(tester, 'Annuler');
    expect(client.requests, isEmpty);

    await tapText(tester, 'Demander une analyse IA');
    await tapText(tester, 'Envoyer');

    final request = client.requests.single;
    final text = request.messages.single.text;
    expect(text, isNot(contains('MonSecret')));
    expect(text, isNot(contains('/home/ana')));
    expect(text, contains('Référence Kotlin non résolue'));
    for (final title in [
      'Résumé du problème',
      'Causes possibles',
      'Vérifications recommandées',
      'Corrections proposées',
      'Explication pédagogique',
      'Procédure de validation',
    ]) {
      expect(request.system, contains(title));
    }
    expect(request.system, contains('Ne dites jamais'));
    expect(location(container), startsWith('/maitre/conversation/'));
    expect(find.textContaining('une panne'), findsOneWidget);
  });

  testWidgets('une réponse de l\'IA ne change pas l\'état du dossier', (
    tester,
  ) async {
    final client = RecordingClient();
    final container = await pumpApp(
      tester,
      size: tall,
      extraOverrides: withClient(client),
    );
    await configureOllama(tester, container);
    await goTo(tester, container, AppSection.chaudron.path);
    await openCase(tester, 'Duplicate class a');
    final path = location(container);

    await tapText(tester, 'Demander une analyse IA');
    await tapText(tester, 'Envoyer');
    await goTo(tester, container, path);

    expect(find.text('État : Non vérifié'), findsOneWidget);
    expect(find.text('Ouvrir l\'analyse'), findsOneWidget);
  });

  testWidgets('la vérification exige un résultat noté', (tester) async {
    final container = await pumpApp(tester, size: tall);
    await goTo(tester, container, AppSection.chaudron.path);
    await openCase(tester, 'Duplicate class a');

    await tapText(tester, 'La vérification réussit');
    expect(find.text('État : Non vérifié'), findsOneWidget);
    expect(find.textContaining('Notez d\'abord'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    final field = find.widgetWithText(
      TextField,
      'Résultat de votre vérification',
    );
    await tester.ensureVisible(field);
    await tester.enterText(field, './gradlew assembleDebug : réussi');
    await tester.pump();
    await tapText(tester, 'La vérification réussit');
    expect(find.text('État : Vérification réussie'), findsOneWidget);

    await goTo(tester, container, AppSection.chaudron.path);
    expect(find.text('Vérification réussie'), findsOneWidget);
  });

  testWidgets('supprimer un dossier demande confirmation', (tester) async {
    final container = await pumpApp(tester, size: tall);
    await goTo(tester, container, AppSection.chaudron.path);
    await openCase(tester, 'Duplicate class a');

    await tester.tap(find.byTooltip('Supprimer le dossier'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await tester.pumpAndSettle();

    expect(location(container), AppSection.chaudron.path);
    expect(find.text('Aucun dossier pour l\'instant.'), findsOneWidget);
  });

  testWidgets('chaque famille a son diagnostic guidé', (tester) async {
    final container = await pumpApp(tester, size: tall);

    for (final family in BugFamily.values) {
      await goTo(tester, container, bugGuidePath(family));
      expect(find.widgetWithText(AppBar, family.label), findsOneWidget);
      expect(find.byType(ExpansionTile), findsWidgets);
    }

    await goTo(tester, container, bugGuidePath(BugFamily.adb));
    await tapText(tester, 'Appareil non autorisé');
    expect(find.byType(Checkbox), findsWidgets);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    final box = tester.widget<Checkbox>(find.byType(Checkbox).first);
    expect(box.value, isTrue);
  });

  testWidgets('une adresse inconnue reste sans plantage', (tester) async {
    final container = await pumpApp(tester);
    await goTo(tester, container, '${AppSection.chaudron.path}/guide/absent');
    expect(tester.takeException(), isNull);
    await goTo(tester, container, bugCasePath(999));
    expect(find.textContaining('n\'existe plus'), findsOneWidget);
  });

  testWidgets('les écrans tiennent sur un petit écran', (tester) async {
    final container = await pumpApp(tester, size: const Size(320, 568));
    await goTo(tester, container, AppSection.chaudron.path);
    expect(tester.takeException(), isNull);
    await goTo(tester, container, bugGuidePath(BugFamily.gradle));
    expect(tester.takeException(), isNull);
  });
}
