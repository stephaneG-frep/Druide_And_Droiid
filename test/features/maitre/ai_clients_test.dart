import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:druide_and_droiid/features/maitre/data/ai_clients.dart';
import 'package:druide_and_droiid/features/maitre/domain/ai_chat.dart';
import 'package:druide_and_droiid/features/maitre/domain/ai_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

const _key = 'cle-de-test-123456';

/// Serveur local qui rejoue le protocole documenté de chaque fournisseur.
/// Aucun appel ne quitte la machine : ces tests ne prouvent pas que le service
/// réel se comporte ainsi.
class FakeServer {
  late HttpServer server;
  final requests =
      <({String path, Map<String, String> headers, String body})>[];
  late Future<void> Function(HttpRequest request) handler;

  Future<void> start() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final body = await utf8.decodeStream(request);
      final headers = <String, String>{};
      request.headers.forEach((name, values) => headers[name] = values.join());
      requests.add((
        path: request.uri.toString(),
        headers: headers,
        body: body,
      ));
      await handler(request);
    });
  }

  String get url => 'http://127.0.0.1:${server.port}';

  void reply(String body, {int status = 200}) {
    handler = (request) async {
      request.response.statusCode = status;
      request.response.write(body);
      await request.response.close();
    };
  }

  Map<String, Object?> get lastBody =>
      jsonDecode(requests.last.body) as Map<String, Object?>;
}

AiClient clientFor(
  AiProviderKind kind,
  String url, {
  String? key = _key,
  int timeout = 5,
}) {
  return createAiClient(
    config: AiProviderConfig(
      kind: kind,
      baseUrl: url,
      model: 'modele-test',
      timeoutSeconds: timeout,
    ),
    apiKey: key,
    clientFactory: http.Client.new,
  );
}

const _request = AiRequest(
  model: 'modele-test',
  system: 'Consigne',
  messages: [
    AiMessage(AiRole.user, 'Bonjour'),
    AiMessage(AiRole.assistant, 'Salut'),
    AiMessage(AiRole.user, 'Explique Flow'),
  ],
  maxOutputTokens: 256,
);

String textOf(List<AiEvent> events) =>
    events.whereType<AiTextDelta>().map((event) => event.text).join();

AiStopReason reasonOf(List<AiEvent> events) =>
    events.whereType<AiDone>().single.reason;

AiUsage usageOf(List<AiEvent> events) => events.whereType<AiUsage>().last;

Matcher failure(AiFailureKind kind) =>
    isA<AiFailure>().having((error) => error.kind, 'kind', kind);

void main() {
  late FakeServer fake;

  setUp(() async {
    fake = FakeServer();
    await fake.start();
  });

  tearDown(() => fake.server.close(force: true));

  group('Anthropic', () {
    const stream = '''
event: message_start
data: {"type":"message_start","message":{"usage":{"input_tokens":25,"cache_read_input_tokens":5,"output_tokens":1}}}

event: content_block_start
data: {"type":"content_block_start","index":0,"content_block":{"type":"thinking","thinking":""}}

event: content_block_delta
data: {"type":"content_block_delta","index":0,"delta":{"type":"thinking_delta","thinking":"réflexion cachée"}}

event: ping
data: {"type":"ping"}

event: content_block_delta
data: {"type":"content_block_delta","index":1,"delta":{"type":"text_delta","text":"Un flux "}}

event: content_block_delta
data: {"type":"content_block_delta","index":1,"delta":{"type":"text_delta","text":"de valeurs"}}

event: message_delta
data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":12}}

event: message_stop
data: {"type":"message_stop"}

''';

    test('envoie la forme documentée et lit le flux', () async {
      fake.reply(stream);
      final events = await clientFor(
        AiProviderKind.anthropic,
        fake.url,
      ).chat(_request).toList();

      expect(textOf(events), 'Un flux de valeurs');
      expect(reasonOf(events), AiStopReason.complete);
      expect(usageOf(events).inputTokens, 30);
      expect(usageOf(events).outputTokens, 12);

      final call = fake.requests.single;
      expect(call.path, '/v1/messages');
      expect(call.headers['x-api-key'], _key);
      expect(call.headers['anthropic-version'], isNotEmpty);
      expect(fake.lastBody['system'], 'Consigne');
      expect(fake.lastBody['max_tokens'], 256);
      expect(fake.lastBody['stream'], isTrue);
      expect(fake.lastBody.containsKey('temperature'), isFalse);
      expect((fake.lastBody['messages'] as List).length, 3);
    });

    test('signale un refus et une réponse coupée', () async {
      fake.reply(stream.replaceFirst('end_turn', 'refusal'));
      var events = await clientFor(
        AiProviderKind.anthropic,
        fake.url,
      ).chat(_request).toList();
      expect(reasonOf(events), AiStopReason.refused);

      fake.reply(stream.replaceFirst('end_turn', 'max_tokens'));
      events = await clientFor(
        AiProviderKind.anthropic,
        fake.url,
      ).chat(_request).toList();
      expect(reasonOf(events), AiStopReason.truncated);
    });

    test('une erreur au milieu du flux devient une panne du service', () {
      fake.reply('''
event: error
data: {"type":"error","error":{"type":"overloaded_error","message":"Overloaded"}}

''');
      expect(
        clientFor(AiProviderKind.anthropic, fake.url).chat(_request).toList(),
        throwsA(failure(AiFailureKind.server)),
      );
    });

    test('liste les modèles sans générer de réponse', () async {
      fake.reply('{"data":[{"id":"b"},{"id":"a"}]}');
      final models = await clientFor(
        AiProviderKind.anthropic,
        fake.url,
      ).listModels();

      expect(models, ['a', 'b']);
      expect(fake.requests.single.path, startsWith('/v1/models'));
    });
  });

  group('OpenAI et API compatibles', () {
    const stream = '''
data: {"choices":[{"delta":{"role":"assistant","content":""},"finish_reason":null}]}

data: {"choices":[{"delta":{"content":"Bon"},"finish_reason":null}]}

data: {"choices":[{"delta":{"content":"jour"},"finish_reason":null}]}

data: {"choices":[{"delta":{},"finish_reason":"stop"}]}

data: {"choices":[],"usage":{"prompt_tokens":9,"completion_tokens":3}}

data: [DONE]

''';

    test('OpenAI utilise max_completion_tokens et la clé en en-tête', () async {
      fake.reply(stream);
      final events = await clientFor(
        AiProviderKind.openai,
        '${fake.url}/v1',
      ).chat(_request).toList();

      expect(textOf(events), 'Bonjour');
      expect(reasonOf(events), AiStopReason.complete);
      expect(usageOf(events).inputTokens, 9);
      expect(fake.requests.single.path, '/v1/chat/completions');
      expect(fake.requests.single.headers['authorization'], 'Bearer $_key');
      expect(fake.lastBody['max_completion_tokens'], 256);
      final messages = fake.lastBody['messages'] as List;
      expect((messages.first as Map)['role'], 'system');
    });

    test('une API compatible accepte l\'absence de clé', () async {
      fake.reply(stream.replaceFirst('"stop"', '"length"'));
      final events = await clientFor(
        AiProviderKind.compatible,
        '${fake.url}/v1/',
        key: null,
      ).chat(_request).toList();

      expect(reasonOf(events), AiStopReason.truncated);
      expect(
        fake.requests.single.headers.containsKey('authorization'),
        isFalse,
      );
      expect(fake.lastBody['max_tokens'], 256);
    });

    test('un flux sans signal de fin est marqué interrompu', () async {
      fake.reply('data: {"choices":[{"delta":{"content":"Bon"}}]}\n\n');
      final events = await clientFor(
        AiProviderKind.openai,
        fake.url,
      ).chat(_request).toList();

      expect(reasonOf(events), AiStopReason.interrupted);
    });
  });

  group('Gemini', () {
    test('passe la clé en en-tête, jamais dans l\'adresse', () async {
      fake.reply('''
data: {"candidates":[{"content":{"role":"model","parts":[{"text":"Bon"}]}}]}

data: {"candidates":[{"content":{"role":"model","parts":[{"text":"jour"}]},"finishReason":"STOP"}],"usageMetadata":{"promptTokenCount":7,"candidatesTokenCount":2,"thoughtsTokenCount":3}}

''');
      final events = await clientFor(
        AiProviderKind.gemini,
        fake.url,
      ).chat(_request).toList();

      expect(textOf(events), 'Bonjour');
      expect(usageOf(events).outputTokens, 5);
      final call = fake.requests.single;
      expect(call.path, '/models/modele-test:streamGenerateContent?alt=sse');
      expect(call.path, isNot(contains(_key)));
      expect(call.headers['x-goog-api-key'], _key);
      final contents = fake.lastBody['contents'] as List;
      expect((contents[1] as Map)['role'], 'model');
      expect(fake.lastBody['systemInstruction'], isNotNull);
    });

    test('un contenu bloqué est un refus', () async {
      fake.reply('data: {"promptFeedback":{"blockReason":"SAFETY"}}\n\n');
      final events = await clientFor(
        AiProviderKind.gemini,
        fake.url,
      ).chat(_request).toList();

      expect(reasonOf(events), AiStopReason.refused);
    });

    test('ne garde que les modèles capables de générer du texte', () async {
      fake.reply(
        '{"models":[{"name":"models/a","supportedGenerationMethods":'
        '["generateContent"]},{"name":"models/b",'
        '"supportedGenerationMethods":["embedContent"]}]}',
      );
      final models = await clientFor(
        AiProviderKind.gemini,
        fake.url,
      ).listModels();

      expect(models, ['a']);
    });
  });

  group('Ollama', () {
    test('lit les lignes JSON, sans clé', () async {
      fake.reply('''
{"message":{"role":"assistant","content":"Bon"},"done":false}
{"message":{"role":"assistant","content":"jour"},"done":false}
{"message":{"role":"assistant","content":""},"done":true,"done_reason":"stop","prompt_eval_count":11,"eval_count":4}
''');
      final events = await clientFor(
        AiProviderKind.ollama,
        fake.url,
        key: null,
      ).chat(_request).toList();

      expect(textOf(events), 'Bonjour');
      expect(usageOf(events).outputTokens, 4);
      expect(fake.requests.single.path, '/api/chat');
      expect((fake.lastBody['options'] as Map)['num_predict'], 256);
    });

    test('liste les modèles locaux', () async {
      fake.reply('{"models":[{"name":"llama3.2"}]}');
      final models = await clientFor(
        AiProviderKind.ollama,
        fake.url,
        key: null,
      ).listModels();

      expect(models, ['llama3.2']);
      expect(fake.requests.single.path, '/api/tags');
    });

    test('remonte un modèle absent', () async {
      fake.reply('{"error":"model not found"}', status: 404);
      await expectLater(
        clientFor(
          AiProviderKind.ollama,
          fake.url,
          key: null,
        ).chat(_request).toList(),
        throwsA(
          isA<AiFailure>()
              .having((e) => e.kind, 'kind', AiFailureKind.modelNotFound)
              .having((e) => e.detail, 'detail', 'model not found'),
        ),
      );
    });
  });

  group('erreurs', () {
    Future<void> expectStatus(int status, AiFailureKind kind) async {
      fake.reply('{"error":{"message":"non"}}', status: status);
      await expectLater(
        clientFor(AiProviderKind.anthropic, fake.url).chat(_request).toList(),
        throwsA(failure(kind)),
      );
    }

    test('chaque statut donne un message adapté', () async {
      await expectStatus(401, AiFailureKind.invalidKey);
      await expectStatus(403, AiFailureKind.forbidden);
      await expectStatus(404, AiFailureKind.modelNotFound);
      await expectStatus(429, AiFailureKind.rateLimited);
      await expectStatus(500, AiFailureKind.server);
      await expectStatus(529, AiFailureKind.server);
      await expectStatus(400, AiFailureKind.badRequest);
    });

    test('reconnaît un crédit épuisé', () async {
      fake.reply(
        '{"error":{"message":"Your credit balance is too low"}}',
        status: 400,
      );
      await expectLater(
        clientFor(AiProviderKind.anthropic, fake.url).chat(_request).toList(),
        throwsA(failure(AiFailureKind.quota)),
      );
    });

    test('une clé renvoyée par le service n\'est jamais affichée', () async {
      fake.reply('{"error":{"message":"Clé $_key invalide"}}', status: 401);
      await expectLater(
        clientFor(AiProviderKind.anthropic, fake.url).chat(_request).toList(),
        throwsA(
          isA<AiFailure>().having(
            (error) => error.message,
            'message',
            allOf(contains('[clé masquée]'), isNot(contains(_key))),
          ),
        ),
      );
    });

    test('un service muet déclenche le délai d\'attente', () async {
      fake.handler = (request) async {
        await Future<void>.delayed(const Duration(seconds: 3));
      };
      await expectLater(
        clientFor(
          AiProviderKind.ollama,
          fake.url,
          key: null,
          timeout: 1,
        ).chat(_request).toList(),
        throwsA(failure(AiFailureKind.timeout)),
      );
    });

    test('un flux qui s\'arrête de parler déclenche le délai', () async {
      fake.handler = (request) async {
        request.response
          ..bufferOutput = false
          ..write('{"message":{"content":"Bon"},"done":false}\n');
        await request.response.flush();
      };
      await expectLater(
        clientFor(
          AiProviderKind.ollama,
          fake.url,
          key: null,
          timeout: 1,
        ).chat(_request).toList(),
        throwsA(failure(AiFailureKind.timeout)),
      );
    });

    test('un service éteint est une erreur réseau', () async {
      final url = fake.url;
      await fake.server.close(force: true);
      await expectLater(
        clientFor(AiProviderKind.ollama, url, key: null).listModels(),
        throwsA(failure(AiFailureKind.network)),
      );
    });

    test('une réponse illisible est signalée', () async {
      fake.reply('data: pas du json\n\n');
      await expectLater(
        clientFor(AiProviderKind.openai, fake.url).chat(_request).toList(),
        throwsA(failure(AiFailureKind.invalidResponse)),
      );
    });

    test('couper la réponse termine aussitôt le flux', () async {
      fake.handler = (request) async {
        request.response
          ..bufferOutput = false
          ..write('{"message":{"content":"Bon"},"done":false}\n');
        await request.response.flush();
      };
      final client = clientFor(AiProviderKind.ollama, fake.url, key: null);
      final received = Completer<void>();
      final ended = Completer<Object?>();
      client
          .chat(_request)
          .listen(
            (_) => received.complete(),
            onError: ended.complete,
            onDone: () {
              if (!ended.isCompleted) ended.complete();
            },
          );
      await received.future;
      client.abort();

      // Le délai d'attente est de 5 secondes : la fin vient bien de l'arrêt.
      await ended.future.timeout(const Duration(seconds: 2));
    });

    test('refuse d\'envoyer une clé en clair vers un autre hôte', () {
      expect(
        () => clientFor(AiProviderKind.compatible, 'http://192.168.1.20/v1'),
        throwsA(failure(AiFailureKind.insecureUrl)),
      );
    });

    test('un accent coupé entre deux paquets reste lisible', () async {
      final bytes = utf8.encode(
        '{"message":{"content":"été"},"done":true,"done_reason":"stop"}\n',
      );
      fake.handler = (request) async {
        request.response.add(bytes.sublist(0, 26));
        await request.response.flush();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        request.response.add(bytes.sublist(26));
        await request.response.close();
      };
      final events = await clientFor(
        AiProviderKind.ollama,
        fake.url,
        key: null,
      ).chat(_request).toList();

      expect(textOf(events), 'été');
    });
  });
}
