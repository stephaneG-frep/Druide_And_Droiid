import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:druide_and_droiid/app/app.dart';
import 'package:druide_and_droiid/app/router.dart';
import 'package:druide_and_droiid/app/sections.dart';
import 'package:druide_and_droiid/core/persistence/app_database.dart';
import 'package:druide_and_droiid/design_system/motion.dart';
import 'package:druide_and_droiid/features/academie/data/course_repository.dart';
import 'package:druide_and_droiid/features/maitre/data/ai_settings_repository.dart';
import 'package:druide_and_droiid/features/maitre/domain/ai_provider.dart';
import 'package:druide_and_droiid/features/parametres/domain/appearance.dart';
import 'package:druide_and_droiid/features/parametres/presentation/appearance_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Le vrai client HTTP et le vrai coffre, face à un serveur local qui parle
/// le protocole compatible OpenAI. Aucun service externe n'est contacté.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('le chat passe par le coffre et le réseau réels', (tester) async {
    final headers = <String>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      await utf8.decodeStream(request);
      headers.add(request.headers.value('authorization') ?? '');
      request.response
        ..bufferOutput = false
        ..headers.contentType = ContentType('text', 'event-stream');
      for (final word in ['Bonjour ', 'apprenti']) {
        request.response.write(
          'data: ${jsonEncode({
            'choices': [
              {
                'delta': {'content': word},
                'finish_reason': null,
              },
            ],
          })}\n\n',
        );
        await request.response.flush();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      request.response.write(
        'data: {"choices":[{"delta":{},"finish_reason":"stop"}],'
        '"usage":{"prompt_tokens":8,"completion_tokens":2}}\n\n'
        'data: [DONE]\n\n',
      );
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));

    final database = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        initialAppearanceProvider.overrideWithValue(
          const Appearance(themeMode: ThemeMode.dark, motion: MotionLevel.none),
        ),
        assetBundleProvider.overrideWithValue(rootBundle),
        appDatabaseProvider.overrideWithValue(database),
      ],
    );
    addTearDown(container.dispose);

    final settings = container.read(aiSettingsRepositoryProvider);
    const kind = AiProviderKind.compatible;
    await settings.saveConfig(
      AiProviderConfig(
        kind: kind,
        baseUrl: 'http://127.0.0.1:${server.port}/v1',
        model: 'modele-local',
      ),
    );
    await settings.saveKey(kind, 'cle-integration');
    addTearDown(() => settings.deleteKey(kind));
    await settings.setActive(kind);
    await settings.grantConsent(kind);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const DruideApp()),
    );
    await tester.pumpAndSettle();

    container.read(routerProvider).go(AppSection.maitre.path);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nouvelle conversation'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Salut');
    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    for (
      var i = 0;
      i < 40 && find.textContaining('en sortie').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.textContaining('Bonjour apprenti'), findsOneWidget);
    expect(find.textContaining('8 en entrée, 2 en sortie'), findsOneWidget);
    expect(headers.single, 'Bearer cle-integration');

    final stored = await database.select(database.aiMessages).get();
    expect(stored.map((row) => row.content), ['Salut', 'Bonjour apprenti']);
  });
}
