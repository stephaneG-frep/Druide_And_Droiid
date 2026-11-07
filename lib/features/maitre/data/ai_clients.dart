import 'dart:async';
import 'dart:io';

import '../domain/ai_chat.dart';
import '../domain/ai_provider.dart';
import 'ai_http.dart';

/// Contrat commun des fournisseurs : tout le reste de l'application l'ignore.
abstract interface class AiClient {
  Stream<AiEvent> chat(AiRequest request);

  /// Sert aussi de test de connexion : aucune génération, donc aucun jeton.
  Future<List<String>> listModels();

  /// Coupe tout de suite la réponse en cours.
  void abort();
}

AiClient createAiClient({
  required AiProviderConfig config,
  required String? apiKey,
  required HttpClientFactory clientFactory,
  bool? onAndroid,
}) {
  final key = apiKey == null || apiKey.isEmpty ? null : apiKey;
  final isAndroid = onAndroid ?? Platform.isAndroid;
  final problem = config.urlProblem(withKey: key != null);
  if (problem != null) {
    throw AiFailure(AiFailureKind.insecureUrl, detail: problem);
  }
  final http = AiHttp(
    clientFactory: clientFactory,
    timeout: Duration(seconds: config.timeoutSeconds),
    secret: key,
    connectionHint: _connectionHint(config, onAndroid: isAndroid),
  );
  var base = config.baseUrl.trim();
  while (base.endsWith('/')) {
    base = base.substring(0, base.length - 1);
  }
  return switch (config.kind) {
    AiProviderKind.anthropic => AnthropicClient(http, base, key ?? ''),
    AiProviderKind.openai => OpenAiClient(
      http,
      base,
      key,
      tokensField: 'max_completion_tokens',
    ),
    AiProviderKind.compatible => OpenAiClient(
      http,
      base,
      key,
      tokensField: 'max_tokens',
    ),
    AiProviderKind.gemini => GeminiClient(http, base, key ?? ''),
    AiProviderKind.ollama => OllamaClient(http, base),
  };
}

/// Sur Android, `127.0.0.1` désigne le téléphone, pas l'ordinateur : Ollama n'y
/// est joignable que par le pont USB, qui disparaît au débranchement.
String? _connectionHint(AiProviderConfig config, {required bool onAndroid}) {
  if (config.kind != AiProviderKind.ollama || !config.staysOnDevice) {
    return null;
  }
  final host = Uri.tryParse(config.baseUrl.trim())?.host;
  if (!onAndroid) {
    return 'Ollama ne semble pas lancé sur cet ordinateur : démarrez-le avec '
        'ollama serve.';
  }
  return host == '10.0.2.2'
      ? 'Vérifiez qu\'Ollama tourne sur l\'ordinateur qui héberge l\'émulateur.'
      : 'Sur téléphone, Ollama passe par le câble USB. Vérifiez le câble, puis '
            'relancez sur l\'ordinateur : adb reverse tcp:11434 tcp:11434. Ce '
            'lien disparaît à chaque débranchement.';
}

String _roleName(AiRole role) => role == AiRole.user ? 'user' : 'assistant';

int? _int(Object? value) => value is num ? value.toInt() : null;

/// API Messages. L'historique ne contient que du texte : les blocs de réflexion
/// ne sont pas conservés, ce que l'API accepte hors usage d'outils.
class AnthropicClient implements AiClient {
  AnthropicClient(this._http, this._base, this._key);

  static const apiVersion = '2026-10-21';

  final AiHttp _http;
  final String _base;
  final String _key;

  Map<String, String> get _headers => {
    'x-api-key': _key,
    'anthropic-version': apiVersion,
  };

  @override
  void abort() => _http.abort();

  @override
  Stream<AiEvent> chat(AiRequest request) async* {
    final http = _http.postJson(Uri.parse('$_base/v1/messages'), _headers, {
      'model': request.model,
      'max_tokens': request.maxOutputTokens,
      'stream': true,
      'system': request.system,
      'messages': [
        for (final message in request.messages)
          {'role': _roleName(message.role), 'content': message.text},
      ],
    });
    int? input;
    var output = 0;
    var reason = AiStopReason.interrupted;
    await for (final event in parseSse(_http.lines(http))) {
      final json = decodeEvent(event.data);
      switch (json['type']) {
        case 'message_start':
          final usage = (json['message'] as Map?)?['usage'] as Map?;
          input =
              (_int(usage?['input_tokens']) ?? 0) +
              (_int(usage?['cache_read_input_tokens']) ?? 0) +
              (_int(usage?['cache_creation_input_tokens']) ?? 0);
        case 'content_block_delta':
          final delta = json['delta'] as Map?;
          if (delta?['type'] == 'text_delta') {
            yield AiTextDelta(delta!['text'] as String? ?? '');
          }
        case 'message_delta':
          final stop = (json['delta'] as Map?)?['stop_reason'];
          if (stop != null) reason = _stopReason(stop);
          output = _int((json['usage'] as Map?)?['output_tokens']) ?? output;
        case 'error':
          throw _streamError(json['error'] as Map?);
      }
    }
    yield AiUsage(inputTokens: input, outputTokens: output);
    yield AiDone(reason);
  }

  AiStopReason _stopReason(Object stop) => switch (stop) {
    'max_tokens' => AiStopReason.truncated,
    'refusal' => AiStopReason.refused,
    _ => AiStopReason.complete,
  };

  AiFailure _streamError(Map<dynamic, dynamic>? error) {
    final kind = switch (error?['type']) {
      'overloaded_error' || 'api_error' => AiFailureKind.server,
      'rate_limit_error' => AiFailureKind.rateLimited,
      'authentication_error' => AiFailureKind.invalidKey,
      _ => AiFailureKind.badRequest,
    };
    return AiFailure(kind, detail: error?['message'] as String?);
  }

  @override
  Future<List<String>> listModels() async {
    final json = await _http.getJson(
      Uri.parse('$_base/v1/models?limit=1000'),
      _headers,
    );
    return _ids(json['data']);
  }
}

List<String> _ids(Object? data) => [
  if (data is List)
    for (final item in data)
      if (item is Map && item['id'] is String) item['id'] as String,
]..sort();

/// Chat Completions : la même forme sert à OpenAI et aux API compatibles.
class OpenAiClient implements AiClient {
  OpenAiClient(this._http, this._base, this._key, {required this.tokensField});

  final AiHttp _http;
  final String _base;
  final String? _key;

  /// OpenAI et les services compatibles ne nomment pas ce champ pareil.
  final String tokensField;

  Map<String, String> get _headers => {
    if (_key != null) 'authorization': 'Bearer $_key',
  };

  @override
  void abort() => _http.abort();

  @override
  Stream<AiEvent> chat(AiRequest request) async* {
    final http = _http.postJson(
      Uri.parse('$_base/chat/completions'),
      _headers,
      {
        'model': request.model,
        tokensField: request.maxOutputTokens,
        'stream': true,
        'stream_options': {'include_usage': true},
        'messages': [
          {'role': 'system', 'content': request.system},
          for (final message in request.messages)
            {'role': _roleName(message.role), 'content': message.text},
        ],
      },
    );
    var reason = AiStopReason.interrupted;
    await for (final event in parseSse(_http.lines(http))) {
      if (event.data == '[DONE]') break;
      final json = decodeEvent(event.data);
      final error = json['error'];
      if (error is Map) {
        throw AiFailure(
          AiFailureKind.server,
          detail: error['message'] as String?,
        );
      }
      final choices = json['choices'];
      if (choices is List && choices.isNotEmpty) {
        final choice = choices.first as Map;
        final text = (choice['delta'] as Map?)?['content'];
        if (text is String && text.isNotEmpty) yield AiTextDelta(text);
        final finish = choice['finish_reason'];
        if (finish != null) {
          reason = switch (finish) {
            'length' => AiStopReason.truncated,
            'content_filter' => AiStopReason.refused,
            _ => AiStopReason.complete,
          };
        }
      }
      final usage = json['usage'];
      if (usage is Map) {
        yield AiUsage(
          inputTokens: _int(usage['prompt_tokens']),
          outputTokens: _int(usage['completion_tokens']),
        );
      }
    }
    yield AiDone(reason);
  }

  @override
  Future<List<String>> listModels() async {
    final json = await _http.getJson(Uri.parse('$_base/models'), _headers);
    return _ids(json['data']);
  }
}

/// La clé passe dans un en-tête, jamais dans l'adresse : celle-ci finit dans
/// les journaux.
class GeminiClient implements AiClient {
  GeminiClient(this._http, this._base, this._key);

  final AiHttp _http;
  final String _base;
  final String _key;

  Map<String, String> get _headers => {'x-goog-api-key': _key};

  @override
  void abort() => _http.abort();

  @override
  Stream<AiEvent> chat(AiRequest request) async* {
    final model = request.model.replaceFirst('models/', '');
    final http = _http.postJson(
      Uri.parse('$_base/models/$model:streamGenerateContent?alt=sse'),
      _headers,
      {
        'systemInstruction': {
          'parts': [
            {'text': request.system},
          ],
        },
        'generationConfig': {'maxOutputTokens': request.maxOutputTokens},
        'contents': [
          for (final message in request.messages)
            {
              'role': message.role == AiRole.user ? 'user' : 'model',
              'parts': [
                {'text': message.text},
              ],
            },
        ],
      },
    );
    var reason = AiStopReason.interrupted;
    AiUsage? usage;
    await for (final event in parseSse(_http.lines(http))) {
      final json = decodeEvent(event.data);
      if ((json['promptFeedback'] as Map?)?['blockReason'] != null) {
        reason = AiStopReason.refused;
      }
      final candidates = json['candidates'];
      if (candidates is List && candidates.isNotEmpty) {
        final candidate = candidates.first as Map;
        final parts = (candidate['content'] as Map?)?['parts'];
        if (parts is List) {
          for (final part in parts) {
            final text = (part as Map)['text'];
            if (text is String && part['thought'] != true) {
              yield AiTextDelta(text);
            }
          }
        }
        final finish = candidate['finishReason'];
        if (finish != null) {
          reason = switch (finish) {
            'STOP' => AiStopReason.complete,
            'MAX_TOKENS' => AiStopReason.truncated,
            _ => AiStopReason.refused,
          };
        }
      }
      final metadata = json['usageMetadata'];
      if (metadata is Map) {
        usage = AiUsage(
          inputTokens: _int(metadata['promptTokenCount']),
          outputTokens:
              (_int(metadata['candidatesTokenCount']) ?? 0) +
              (_int(metadata['thoughtsTokenCount']) ?? 0),
        );
      }
    }
    if (usage != null) yield usage;
    yield AiDone(reason);
  }

  @override
  Future<List<String>> listModels() async {
    final json = await _http.getJson(
      Uri.parse('$_base/models?pageSize=1000'),
      _headers,
    );
    final models = json['models'];
    return [
      if (models is List)
        for (final model in models)
          if (model is Map &&
              model['name'] is String &&
              (model['supportedGenerationMethods'] as List?)?.contains(
                    'generateContent',
                  ) !=
                  false)
            (model['name'] as String).replaceFirst('models/', ''),
    ]..sort();
  }
}

/// API locale : des lignes JSON, sans clé.
class OllamaClient implements AiClient {
  OllamaClient(this._http, this._base);

  final AiHttp _http;
  final String _base;

  @override
  void abort() => _http.abort();

  @override
  Stream<AiEvent> chat(AiRequest request) async* {
    final http = _http.postJson(Uri.parse('$_base/api/chat'), const {}, {
      'model': request.model,
      'stream': true,
      'options': {'num_predict': request.maxOutputTokens},
      'messages': [
        {'role': 'system', 'content': request.system},
        for (final message in request.messages)
          {'role': _roleName(message.role), 'content': message.text},
      ],
    });
    var reason = AiStopReason.interrupted;
    await for (final line in _http.lines(http)) {
      if (line.isEmpty) continue;
      final json = decodeEvent(line);
      if (json['error'] is String) {
        throw AiFailure(
          AiFailureKind.badRequest,
          detail: json['error'] as String,
        );
      }
      final text = (json['message'] as Map?)?['content'];
      if (text is String && text.isNotEmpty) yield AiTextDelta(text);
      if (json['done'] == true) {
        reason = json['done_reason'] == 'length'
            ? AiStopReason.truncated
            : AiStopReason.complete;
        yield AiUsage(
          inputTokens: _int(json['prompt_eval_count']),
          outputTokens: _int(json['eval_count']),
        );
      }
    }
    yield AiDone(reason);
  }

  @override
  Future<List<String>> listModels() async {
    final json = await _http.getJson(Uri.parse('$_base/api/tags'), const {});
    final models = json['models'];
    return [
      if (models is List)
        for (final model in models)
          if (model is Map && model['name'] is String) model['name'] as String,
    ]..sort();
  }
}
