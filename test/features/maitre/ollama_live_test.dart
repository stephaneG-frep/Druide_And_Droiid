import 'dart:async';
import 'dart:io';

import 'package:druide_and_droiid/features/maitre/data/ai_clients.dart';
import 'package:druide_and_droiid/features/maitre/domain/ai_chat.dart';
import 'package:druide_and_droiid/features/maitre/domain/ai_provider.dart';
import 'package:druide_and_droiid/features/maitre/domain/teaching.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Essai contre un vrai serveur Ollama, lancé seulement à la demande :
///
///     OLLAMA_MODEL=gemma3:1b flutter test test/features/maitre/ollama_live_test.dart
void main() {
  final model = Platform.environment['OLLAMA_MODEL'];

  AiClient client({int timeout = 120}) => createAiClient(
    config: AiProviderConfig(
      kind: AiProviderKind.ollama,
      baseUrl: AiProviderKind.ollama.defaultBaseUrl,
      timeoutSeconds: timeout,
    ),
    apiKey: null,
    clientFactory: http.Client.new,
  );

  AiRequest request(String question, {int maxTokens = 200}) => AiRequest(
    model: model!,
    system: systemPrompt(
      level: LearnerLevel.debutant,
      mode: TeachingMode.explain,
    ),
    messages: [AiMessage(AiRole.user, question)],
    maxOutputTokens: maxTokens,
  );

  group('Ollama réel', skip: model == null ? 'OLLAMA_MODEL absent' : null, () {
    test('liste le modèle installé', () async {
      expect(await client().listModels(), contains(model));
    });

    test('répond par morceaux et annonce l\'usage', () async {
      final events = await client()
          .chat(request('Qu\'est-ce qu\'une Activity Android ?'))
          .toList();

      final deltas = events.whereType<AiTextDelta>().toList();
      final text = deltas.map((event) => event.text).join();
      // ignore: avoid_print
      print('Réponse réelle :\n$text');
      expect(deltas.length, greaterThan(1));
      expect(text, isNotEmpty);
      final usage = events.whereType<AiUsage>().single;
      expect(usage.inputTokens, greaterThan(0));
      expect(usage.outputTokens, greaterThan(0));
      expect(
        events.whereType<AiDone>().single.reason,
        isNot(AiStopReason.interrupted),
      );
    }, timeout: const Timeout(Duration(minutes: 4)));

    test('signale une réponse coupée par la limite', () async {
      final events = await client()
          .chat(request('Raconte l\'histoire d\'Android.', maxTokens: 5))
          .toList();

      expect(events.whereType<AiDone>().single.reason, AiStopReason.truncated);
    }, timeout: const Timeout(Duration(minutes: 4)));

    test('un modèle absent donne un message clair', () async {
      final absent = AiRequest(
        model: 'modele-inexistant',
        system: 'x',
        messages: const [AiMessage(AiRole.user, 'x')],
        maxOutputTokens: 5,
      );
      await expectLater(
        client().chat(absent).toList(),
        throwsA(
          isA<AiFailure>().having(
            (failure) => failure.kind,
            'kind',
            AiFailureKind.modelNotFound,
          ),
        ),
      );
    });

    test('couper la réponse la termine vraiment', () async {
      final live = client();
      final first = Completer<void>();
      final ended = Completer<void>();
      live
          .chat(request('Explique Gradle en détail.', maxTokens: 400))
          .listen(
            (_) {
              if (!first.isCompleted) first.complete();
            },
            onError: (Object _) {
              if (!ended.isCompleted) ended.complete();
            },
            onDone: () {
              if (!ended.isCompleted) ended.complete();
            },
          );
      await first.future;
      live.abort();

      await ended.future.timeout(const Duration(seconds: 3));
    }, timeout: const Timeout(Duration(minutes: 4)));
  });
}
