import 'package:druide_and_droiid/app/sections.dart';
import 'package:druide_and_droiid/core/persistence/app_database.dart';
import 'package:druide_and_droiid/features/academie/presentation/paths.dart';
import 'package:druide_and_droiid/features/maitre/data/ai_clients.dart';
import 'package:druide_and_droiid/features/maitre/data/ai_settings_repository.dart';
import 'package:druide_and_droiid/features/maitre/domain/ai_chat.dart';
import 'package:druide_and_droiid/features/maitre/domain/ai_provider.dart';
import 'package:druide_and_droiid/features/maitre/presentation/ai_paths.dart';
import 'package:druide_and_droiid/features/maitre/presentation/ai_settings_page.dart';
import 'package:druide_and_droiid/features/maitre/presentation/chat_controller.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_app.dart';

const tall = Size(390, 1600);

class ScriptedClient implements AiClient {
  ScriptedClient(this.events);

  final List<AiEvent> events;
  int calls = 0;

  @override
  Stream<AiEvent> chat(AiRequest request) {
    calls++;
    return Stream.fromIterable(events);
  }

  @override
  Future<List<String>> listModels() async => ['modele-a', 'modele-b'];

  @override
  void abort() {}
}

Future<void> configure(
  WidgetTester tester,
  ProviderContainer container, {
  AiProviderKind kind = AiProviderKind.ollama,
}) async {
  final settings = container.read(aiSettingsRepositoryProvider);
  await tester.runAsync(() async {
    await settings.saveConfig(
      AiProviderConfig(
        kind: kind,
        baseUrl: kind.isLocal ? 'http://127.0.0.1:11434' : kind.defaultBaseUrl,
        model: 'modele-a',
      ),
    );
    if (kind.needsKey) await settings.saveKey(kind, 'cle');
    await settings.setActive(kind);
  });
  await tester.pumpAndSettle();
}

Future<ProviderContainer> pumpAppWith(
  WidgetTester tester,
  AiClient client,
) async {
  final container = await pumpApp(
    tester,
    size: tall,
    database: AppDatabase(NativeDatabase.memory()),
    extraOverrides: [
      aiClientBuilderProvider.overrideWithValue((config) async => client),
    ],
  );
  return container;
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('sans fournisseur, le Maître le dit et l\'application vit', (
    tester,
  ) async {
    final container = await pumpApp(tester, size: tall);
    await goTo(tester, container, AppSection.maitre.path);

    expect(find.text('Message préenregistré'), findsOneWidget);
    expect(find.text('Configurer le Maître'), findsOneWidget);
    expect(find.textContaining('restent disponibles sans IA'), findsOneWidget);

    await goTo(
      tester,
      container,
      lessonPath('fondations', 'fondations-02-versions'),
    );
    expect(find.text('Corriger avec le Maître'), findsNothing);
    expect(find.text('Demander au Maître'), findsNothing);
  });

  testWidgets('une conversation répond et affiche l\'usage', (tester) async {
    final client = ScriptedClient(const [
      AiTextDelta('Voici :\n```kotlin\nval a = 1\n```'),
      AiUsage(inputTokens: 12, outputTokens: 7),
      AiDone(AiStopReason.complete),
    ]);
    final container = await pumpAppWith(tester, client);
    await configure(tester, container);

    await goTo(tester, container, AppSection.maitre.path);
    await tester.tap(find.text('Nouvelle conversation'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Une question');
    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pumpAndSettle();

    expect(client.calls, 1);
    expect(find.text('Une question'), findsWidgets);
    expect(find.text('Kotlin'), findsOneWidget);
    expect(find.textContaining('12 en entrée, 7 en sortie'), findsOneWidget);
    expect(find.textContaining('générées par une IA'), findsOneWidget);
    expect(find.text('Maître And-Droiīd · IA'), findsOneWidget);
  });

  testWidgets('une réponse coupée le signale', (tester) async {
    final client = ScriptedClient(const [
      AiTextDelta('Début'),
      AiDone(AiStopReason.truncated),
    ]);
    final container = await pumpAppWith(tester, client);
    await configure(tester, container);

    await goTo(tester, container, AppSection.maitre.path);
    await tester.tap(find.text('Nouvelle conversation'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Question');
    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Réponse coupée'), findsOneWidget);
  });

  testWidgets('un service externe exige un accord avant le premier envoi', (
    tester,
  ) async {
    final client = ScriptedClient(const [AiDone(AiStopReason.complete)]);
    final container = await pumpAppWith(tester, client);
    await configure(tester, container, kind: AiProviderKind.anthropic);

    await goTo(tester, container, AppSection.maitre.path);
    await tester.tap(find.text('Nouvelle conversation'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Question');
    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pumpAndSettle();

    expect(find.text('Envoyer vers Anthropic Claude ?'), findsOneWidget);
    await tester.tap(find.text('Refuser'));
    await tester.pumpAndSettle();
    expect(client.calls, 0);

    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accepter'));
    await tester.pumpAndSettle();
    expect(client.calls, 1);

    await tester.enterText(find.byType(TextField), 'Encore');
    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pumpAndSettle();
    expect(find.text('Envoyer vers Anthropic Claude ?'), findsNothing);
    expect(client.calls, 2);
  });

  testWidgets('supprimer une conversation demande confirmation', (
    tester,
  ) async {
    final client = ScriptedClient(const [AiDone(AiStopReason.complete)]);
    final container = await pumpAppWith(tester, client);
    await configure(tester, container);

    await goTo(tester, container, AppSection.maitre.path);
    await tester.tap(find.text('Nouvelle conversation'));
    await tester.pumpAndSettle();
    await goTo(tester, container, AppSection.maitre.path);

    await tester.tap(find.byTooltip('Supprimer la conversation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Supprimer la conversation'), findsOneWidget);

    await tester.tap(find.byTooltip('Supprimer la conversation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    expect(find.text('Aucune conversation pour l\'instant.'), findsOneWidget);
  });

  testWidgets('corriger un exercice envoie l\'énoncé et la réponse', (
    tester,
  ) async {
    final client = ScriptedClient(const [
      AiTextDelta('Bien vu !'),
      AiDone(AiStopReason.complete),
    ]);
    final container = await pumpAppWith(tester, client);
    await configure(tester, container);

    await goTo(
      tester,
      container,
      lessonPath('fondations', 'fondations-02-versions'),
    );
    final labels = find.text('Corriger avec le Maître');
    while (labels.evaluate().isEmpty) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
      await tester.pumpAndSettle();
    }
    final button = labels.first;
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(client.calls, 0);
    expect(find.text('Écrivez d\'abord votre réponse.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    final field = find.widgetWithText(TextField, 'Votre réponse').first;
    await tester.ensureVisible(field);
    await tester.enterText(field, 'minSdk');
    await tester.pump();
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(client.calls, 1);
    expect(location(container), startsWith('/maitre/conversation/'));
    expect(find.text('Bien vu !'), findsOneWidget);
  });

  testWidgets('les réglages testent, listent et activent un fournisseur', (
    tester,
  ) async {
    final client = ScriptedClient(const []);
    final container = await pumpAppWith(tester, client);

    await goTo(tester, container, aiSettingsPath);
    expect(find.byType(AiSettingsPage), findsOneWidget);

    await tester.tap(find.text('Anthropic Claude').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ollama').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tester la connexion'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Connexion réussie : 2 modèles'),
      findsOneWidget,
    );

    await tester.tap(find.text('Enregistrer et activer'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await goTo(tester, container, AppSection.maitre.path);
    expect(find.text('Ollama · modele-a'), findsOneWidget);
  });

  testWidgets('une clé manquante est refusée sans appel réseau', (
    tester,
  ) async {
    final client = ScriptedClient(const []);
    final container = await pumpAppWith(tester, client);

    await goTo(tester, container, aiSettingsPath);
    await tester.tap(find.text('Tester la connexion'));
    await tester.pumpAndSettle();

    expect(find.text('Saisissez d\'abord votre clé.'), findsOneWidget);
  });

  testWidgets('les écrans du Maître tiennent sur un petit écran', (
    tester,
  ) async {
    final client = ScriptedClient(const [AiDone(AiStopReason.complete)]);
    final container = await pumpApp(
      tester,
      size: const Size(320, 568),
      extraOverrides: [
        aiClientBuilderProvider.overrideWithValue((config) async => client),
      ],
    );
    // Enregistrer avant d'ouvrir un écran abonné : `runAsync` bloquerait sinon
    // sur le flux de la base, qui vit dans le temps simulé.
    await configure(tester, container);
    await goTo(tester, container, aiSettingsPath);
    expect(tester.takeException(), isNull);
    await goTo(tester, container, AppSection.maitre.path);
    expect(tester.takeException(), isNull);
  });
}
