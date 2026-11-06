import 'dart:async';

import 'package:drift/native.dart';
import 'package:druide_and_droiid/core/persistence/app_database.dart';
import 'package:druide_and_droiid/core/security/secret_store.dart';
import 'package:druide_and_droiid/features/maitre/data/ai_clients.dart';
import 'package:druide_and_droiid/features/maitre/data/ai_settings_repository.dart';
import 'package:druide_and_droiid/features/maitre/data/conversation_repository.dart';
import 'package:druide_and_droiid/features/maitre/domain/ai_chat.dart';
import 'package:druide_and_droiid/features/maitre/domain/ai_provider.dart';
import 'package:druide_and_droiid/features/maitre/domain/teaching.dart';
import 'package:druide_and_droiid/features/maitre/presentation/chat_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeClient implements AiClient {
  final requests = <AiRequest>[];
  StreamController<AiEvent> controller = StreamController<AiEvent>();
  bool aborted = false;

  @override
  Stream<AiEvent> chat(AiRequest request) {
    requests.add(request);
    return controller.stream;
  }

  @override
  Future<List<String>> listModels() async => ['m'];

  @override
  void abort() => aborted = true;
}

void main() {
  late AppDatabase database;
  late ProviderContainer container;
  late FakeClient client;
  late int id;

  ConversationRepository repository() =>
      container.read(conversationRepositoryProvider);

  ChatController controller() =>
      container.read(chatControllerProvider(id).notifier);

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    database = AppDatabase(NativeDatabase.memory());
    client = FakeClient();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        secretStoreProvider.overrideWithValue(
          const SecretStore(FlutterSecureStorage()),
        ),
        aiClientBuilderProvider.overrideWithValue((config) async => client),
      ],
    );
    final settings = container.read(aiSettingsRepositoryProvider);
    await settings.saveConfig(
      const AiProviderConfig(
        kind: AiProviderKind.ollama,
        baseUrl: 'http://127.0.0.1:11434',
        model: 'llama3.2',
      ),
    );
    await settings.setActive(AiProviderKind.ollama);
    await settings.setLevel(LearnerLevel.avance);
    id = await repository().create(
      title: 'Titre',
      providerKind: 'ollama',
      model: 'llama3.2',
      mode: TeachingMode.logcat,
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  Future<void> waitForRequest() async {
    while (client.requests.isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('enregistre la question et la réponse, avec son usage', () async {
    final sending = controller().send('  Que veut dire ce journal ?  ');
    await waitForRequest();

    client.controller
      ..add(const AiTextDelta('Une '))
      ..add(const AiTextDelta('erreur'))
      ..add(const AiUsage(inputTokens: 10, outputTokens: 4))
      ..add(const AiDone(AiStopReason.complete));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(chatControllerProvider(id)).partial, 'Une erreur');

    await client.controller.close();
    await sending;

    final rows = await repository().messages(id);
    expect(rows.map((row) => row.content), [
      'Que veut dire ce journal ?',
      'Une erreur',
    ]);
    expect(rows.last.outputTokens, 4);
    expect(rows.last.stopReason, 'complete');
    expect(
      (await repository().conversation(id)).title,
      'Que veut dire ce journal ?',
    );
    expect(container.read(chatControllerProvider(id)).responding, isFalse);
  });

  test('adapte la consigne au mode et au niveau', () async {
    final sending = controller().send('Question');
    await waitForRequest();
    await client.controller.close();
    await sending;

    final system = client.requests.single.system;
    expect(system, contains(TeachingMode.logcat.instruction));
    expect(system, contains(LearnerLevel.avance.description));
    expect(client.requests.single.model, 'llama3.2');
  });

  test('renvoie tout l\'historique à la question suivante', () async {
    var sending = controller().send('Première');
    await waitForRequest();
    client.controller
      ..add(const AiTextDelta('Réponse'))
      ..add(const AiDone(AiStopReason.complete));
    await client.controller.close();
    await sending;

    client.controller = StreamController<AiEvent>();
    sending = controller().send('Seconde');
    while (client.requests.length < 2) {
      await Future<void>.delayed(Duration.zero);
    }
    await client.controller.close();
    await sending;

    expect(client.requests.last.messages.map((m) => m.text), [
      'Première',
      'Réponse',
      'Seconde',
    ]);
  });

  test('arrêter coupe la connexion et garde le début de réponse', () async {
    final sending = controller().send('Question');
    await waitForRequest();
    client.controller.add(const AiTextDelta('Début'));
    await Future<void>.delayed(Duration.zero);

    await controller().stop();
    await sending;

    expect(client.aborted, isTrue);
    final last = (await repository().messages(id)).last;
    expect(last.content, 'Début');
    expect(last.stopReason, 'interrupted');
    expect(container.read(chatControllerProvider(id)).responding, isFalse);
  });

  test('une erreur s\'affiche, puis réessayer ne duplique rien', () async {
    final sending = controller().send('Question');
    await waitForRequest();
    client.controller.addError(const AiFailure(AiFailureKind.rateLimited));
    await sending;

    var state = container.read(chatControllerProvider(id));
    expect(state.failure, AiFailureKind.rateLimited.message);
    expect(state.canRetry, isTrue);
    expect(await repository().messages(id), hasLength(1));

    client.controller = StreamController<AiEvent>();
    final retrying = controller().retry();
    while (client.requests.length < 2) {
      await Future<void>.delayed(Duration.zero);
    }
    client.controller
      ..add(const AiTextDelta('Enfin'))
      ..add(const AiDone(AiStopReason.complete));
    await client.controller.close();
    await retrying;

    state = container.read(chatControllerProvider(id));
    expect(state.failure, isNull);
    final rows = await repository().messages(id);
    expect(rows.map((row) => row.content), ['Question', 'Enfin']);
  });

  test('une clé refusée ne propose pas de réessayer', () async {
    final sending = controller().send('Question');
    await waitForRequest();
    client.controller.addError(const AiFailure(AiFailureKind.invalidKey));
    await sending;

    expect(container.read(chatControllerProvider(id)).canRetry, isFalse);
  });

  test('sans fournisseur prêt, rien n\'est envoyé', () async {
    await container
        .read(aiSettingsRepositoryProvider)
        .saveConfig(
          const AiProviderConfig(
            kind: AiProviderKind.ollama,
            baseUrl: 'http://127.0.0.1:11434',
          ),
        );

    await controller().send('Question');

    expect(client.requests, isEmpty);
    expect(container.read(chatControllerProvider(id)).failure, isNotNull);
  });

  test('supprimer une conversation efface ses messages', () async {
    await repository().addUserMessage(id, 'Texte');
    final other = await repository().create(
      title: 'Autre',
      providerKind: 'ollama',
      model: 'm',
      mode: TeachingMode.general,
    );
    await repository().addUserMessage(other, 'Reste');

    await repository().delete(id);

    expect(await repository().messages(id), isEmpty);
    expect(await repository().messages(other), hasLength(1));

    await repository().deleteAll();
    expect(await database.select(database.aiMessages).get(), isEmpty);
    expect(await database.select(database.aiConversations).get(), isEmpty);
  });

  test('la clé va au coffre, jamais dans la base', () async {
    final settings = container.read(aiSettingsRepositoryProvider);
    await settings.saveKey(AiProviderKind.anthropic, 'cle-secrete');

    expect(await settings.readKey(AiProviderKind.anthropic), 'cle-secrete');
    final meta = await database.select(database.appMeta).get();
    expect(meta.map((row) => row.value), isNot(contains('cle-secrete')));
    expect(
      (await settings.read()).keysSaved,
      contains(AiProviderKind.anthropic),
    );

    await settings.deleteKey(AiProviderKind.anthropic);
    expect(await settings.readKey(AiProviderKind.anthropic), isNull);
    expect((await settings.read()).keysSaved, isEmpty);
  });
}
