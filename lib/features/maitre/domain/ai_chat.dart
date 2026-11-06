enum AiRole { user, assistant }

class AiMessage {
  const AiMessage(this.role, this.text);

  final AiRole role;
  final String text;
}

class AiRequest {
  const AiRequest({
    required this.model,
    required this.system,
    required this.messages,
    required this.maxOutputTokens,
  });

  final String model;
  final String system;
  final List<AiMessage> messages;
  final int maxOutputTokens;
}

enum AiStopReason {
  /// La réponse est terminée.
  complete,

  /// La limite de longueur a coupé la réponse.
  truncated,

  /// Le service a refusé de répondre.
  refused,

  /// Le flux s'est arrêté sans signal de fin.
  interrupted,
}

sealed class AiEvent {
  const AiEvent();
}

class AiTextDelta extends AiEvent {
  const AiTextDelta(this.text);

  final String text;
}

class AiUsage extends AiEvent {
  const AiUsage({this.inputTokens, this.outputTokens});

  final int? inputTokens;
  final int? outputTokens;
}

class AiDone extends AiEvent {
  const AiDone(this.reason);

  final AiStopReason reason;
}

enum AiFailureKind {
  invalidKey('La clé est refusée. Vérifiez-la dans les réglages du Maître.'),
  forbidden('Ce compte n\'a pas accès à cette fonction ou à ce modèle.'),
  modelNotFound(
    'Ce modèle ou cette adresse est introuvable. Vérifiez les réglages.',
  ),
  rateLimited('Trop de requêtes. Patientez un moment, puis réessayez.'),
  quota('Le crédit ou le quota de ce compte semble épuisé.'),
  badRequest('Le service a rejeté la requête.'),
  server('Le service rencontre un problème. Réessayez plus tard.'),
  network('Connexion impossible. Vérifiez le réseau et l\'adresse du service.'),
  timeout('Le service met trop de temps à répondre.'),
  invalidResponse('La réponse du service n\'a pas pu être lue.'),
  insecureUrl('Cette adresse n\'est pas sûre pour envoyer une clé.');

  const AiFailureKind(this.message);

  final String message;

  bool get retryable => switch (this) {
    rateLimited || server || network || timeout => true,
    _ => false,
  };
}

/// Erreur présentable à l'utilisateur. [detail] vient du service, sans la clé.
class AiFailure implements Exception {
  const AiFailure(this.kind, {this.detail});

  final AiFailureKind kind;
  final String? detail;

  String get message => detail == null || detail!.isEmpty
      ? kind.message
      : '${kind.message}\nDétail du service : $detail';

  @override
  String toString() => 'AiFailure(${kind.name})';
}

/// Coût estimé, seulement si les tarifs sont connus et l'usage annoncé.
double? estimateCost({
  required int? inputTokens,
  required int? outputTokens,
  required double? inputPricePerMillion,
  required double? outputPricePerMillion,
}) {
  if (inputTokens == null ||
      outputTokens == null ||
      inputPricePerMillion == null ||
      outputPricePerMillion == null) {
    return null;
  }
  return inputTokens / 1000000 * inputPricePerMillion +
      outputTokens / 1000000 * outputPricePerMillion;
}

/// Garde les messages les plus récents dans la limite, en commençant par une
/// question : certains services refusent un historique ouvert par l'assistant.
List<AiMessage> trimHistory(List<AiMessage> messages, {required int maxChars}) {
  var total = 0;
  var start = messages.length;
  while (start > 0) {
    total += messages[start - 1].text.length;
    if (total > maxChars && start < messages.length) break;
    start--;
  }
  while (start < messages.length - 1 && messages[start].role != AiRole.user) {
    start++;
  }
  return messages.sublist(start);
}
