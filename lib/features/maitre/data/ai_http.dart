import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/ai_chat.dart';

typedef HttpClientFactory = http.Client Function();

/// Transport commun : délais, erreurs traduites, lecture ligne par ligne.
class AiHttp {
  AiHttp({required this.clientFactory, required this.timeout, this.secret});

  final HttpClientFactory clientFactory;
  final Duration timeout;

  /// Retiré de tout texte d'erreur affiché ou enregistré.
  final String? secret;

  final _active = <http.Client>{};

  /// Coupe les connexions en cours. Annuler un flux `async*` ne suffit pas : un
  /// générateur en attente ne voit l'annulation qu'à son prochain `yield`.
  void abort() {
    for (final client in _active) {
      client.close();
    }
    _active.clear();
  }

  Stream<String> lines(http.BaseRequest request) async* {
    final client = clientFactory();
    _active.add(client);
    try {
      final response = await client.send(request).timeout(timeout);
      if (response.statusCode >= 400) {
        final body = await response.stream.bytesToString().timeout(timeout);
        throw failureFor(response.statusCode, body);
      }
      // Pas de `yield*` : ses erreurs ne passeraient pas par ce `try`.
      final lines = response.stream
          .timeout(timeout)
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      await for (final line in lines) {
        yield line;
      }
    } on TimeoutException {
      throw const AiFailure(AiFailureKind.timeout);
    } on SocketException {
      throw const AiFailure(AiFailureKind.network);
    } on HandshakeException {
      throw const AiFailure(AiFailureKind.network);
    } on http.ClientException {
      throw const AiFailure(AiFailureKind.network);
    } finally {
      _active.remove(client);
      client.close();
    }
  }

  Future<Map<String, Object?>> getJson(Uri uri, Map<String, String> headers) {
    final request = http.Request('GET', uri)..headers.addAll(headers);
    return lines(request).join('\n').then((text) {
      try {
        return jsonDecode(text) as Map<String, Object?>;
      } on Object {
        throw const AiFailure(AiFailureKind.invalidResponse);
      }
    });
  }

  http.Request postJson(
    Uri uri,
    Map<String, String> headers,
    Map<String, Object?> body,
  ) {
    return http.Request('POST', uri)
      ..headers.addAll({'content-type': 'application/json', ...headers})
      ..body = jsonEncode(body);
  }

  AiFailure failureFor(int status, String body) {
    final detail = serviceMessage(body);
    final lower = detail?.toLowerCase() ?? '';
    final kind = switch (status) {
      401 => AiFailureKind.invalidKey,
      402 => AiFailureKind.quota,
      403 => AiFailureKind.forbidden,
      404 => AiFailureKind.modelNotFound,
      408 || 504 => AiFailureKind.timeout,
      429 when lower.contains('quota') => AiFailureKind.quota,
      429 => AiFailureKind.rateLimited,
      >= 500 => AiFailureKind.server,
      _ when lower.contains('credit') => AiFailureKind.quota,
      _ => AiFailureKind.badRequest,
    };
    return AiFailure(kind, detail: detail);
  }

  /// Texte d'erreur du service, tronqué et sans la clé.
  String? serviceMessage(String body) {
    Object? message;
    try {
      final json = jsonDecode(body);
      final error = json is Map ? json['error'] : null;
      message = error is Map ? error['message'] : error;
    } on FormatException {
      return null;
    }
    if (message is! String || message.isEmpty) return null;
    final key = secret;
    final safe = key == null || key.isEmpty
        ? message
        : message.replaceAll(key, '[clé masquée]');
    return safe.length > 300 ? '${safe.substring(0, 300)}…' : safe;
  }
}

class SseEvent {
  const SseEvent(this.name, this.data);

  final String? name;
  final String data;
}

/// Regroupe les lignes d'un flux `text/event-stream` en événements.
Stream<SseEvent> parseSse(Stream<String> lines) async* {
  String? name;
  final data = <String>[];
  await for (final line in lines) {
    if (line.isEmpty) {
      if (data.isNotEmpty) yield SseEvent(name, data.join('\n'));
      name = null;
      data.clear();
    } else if (line.startsWith('event:')) {
      name = line.substring(6).trim();
    } else if (line.startsWith('data:')) {
      data.add(line.substring(5).trimLeft());
    }
  }
  if (data.isNotEmpty) yield SseEvent(name, data.join('\n'));
}

Map<String, Object?> decodeEvent(String data) {
  try {
    return jsonDecode(data) as Map<String, Object?>;
  } on Object {
    throw const AiFailure(AiFailureKind.invalidResponse);
  }
}
