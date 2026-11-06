import 'dart:convert';

/// Fournisseurs interchangeables du Professeur IA.
enum AiProviderKind {
  anthropic(
    label: 'Anthropic Claude',
    defaultBaseUrl: 'https://api.anthropic.com',
    needsKey: true,
    isLocal: false,
  ),
  openai(
    label: 'OpenAI',
    defaultBaseUrl: 'https://api.openai.com/v1',
    needsKey: true,
    isLocal: false,
  ),
  gemini(
    label: 'Google Gemini',
    defaultBaseUrl: 'https://generativelanguage.googleapis.com/v1beta',
    needsKey: true,
    isLocal: false,
  ),
  ollama(
    label: 'Ollama',
    defaultBaseUrl: 'http://127.0.0.1:11434',
    needsKey: false,
    isLocal: true,
  ),
  compatible(
    label: 'API compatible OpenAI',
    defaultBaseUrl: '',
    needsKey: false,
    isLocal: false,
  );

  const AiProviderKind({
    required this.label,
    required this.defaultBaseUrl,
    required this.needsKey,
    required this.isLocal,
  });

  final String label;
  final String defaultBaseUrl;

  /// Une clé est indispensable. Elle reste facultative pour [compatible].
  final bool needsKey;

  /// Les données restent sur une machine que l'utilisateur contrôle.
  final bool isLocal;

  bool get acceptsKey => this != ollama;
  bool get editableBaseUrl => this == ollama || this == compatible;

  static AiProviderKind? byName(String? name) {
    for (final kind in values) {
      if (kind.name == name) return kind;
    }
    return null;
  }
}

/// Réglages non secrets d'un fournisseur. La clé vit dans le coffre.
class AiProviderConfig {
  const AiProviderConfig({
    required this.kind,
    required this.baseUrl,
    this.model = '',
    this.timeoutSeconds = defaultTimeoutSeconds,
    this.maxOutputTokens = defaultMaxOutputTokens,
    this.inputPricePerMillion,
    this.outputPricePerMillion,
  });

  factory AiProviderConfig.initial(AiProviderKind kind) =>
      AiProviderConfig(kind: kind, baseUrl: kind.defaultBaseUrl);

  factory AiProviderConfig.fromJson(
    AiProviderKind kind,
    Map<String, Object?> json,
  ) {
    return AiProviderConfig(
      kind: kind,
      baseUrl: json['baseUrl'] as String? ?? kind.defaultBaseUrl,
      model: json['model'] as String? ?? '',
      timeoutSeconds: json['timeoutSeconds'] as int? ?? defaultTimeoutSeconds,
      maxOutputTokens:
          json['maxOutputTokens'] as int? ?? defaultMaxOutputTokens,
      inputPricePerMillion: (json['inputPrice'] as num?)?.toDouble(),
      outputPricePerMillion: (json['outputPrice'] as num?)?.toDouble(),
    );
  }

  static const defaultTimeoutSeconds = 60;
  static const defaultMaxOutputTokens = 4096;

  final AiProviderKind kind;
  final String baseUrl;
  final String model;
  final int timeoutSeconds;
  final int maxOutputTokens;

  /// Tarifs saisis par l'utilisateur : ils changent trop pour être codés ici.
  final double? inputPricePerMillion;
  final double? outputPricePerMillion;

  String encode() => jsonEncode({
    'baseUrl': baseUrl,
    'model': model,
    'timeoutSeconds': timeoutSeconds,
    'maxOutputTokens': maxOutputTokens,
    'inputPrice': inputPricePerMillion,
    'outputPrice': outputPricePerMillion,
  });

  /// Une clé ne part jamais en clair, sauf vers la machine elle-même.
  String? urlProblem({required bool withKey}) {
    final uri = Uri.tryParse(baseUrl.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Saisissez une adresse complète, par exemple https://exemple.com/v1.';
    }
    if (uri.scheme == 'https') return null;
    if (uri.scheme != 'http') return 'L\'adresse doit commencer par https://.';
    if (withKey && !isLoopback(uri.host)) {
      return 'Une clé ne peut pas être envoyée en HTTP : utilisez https://.';
    }
    return null;
  }

  /// Les messages restent sur cette machine : aucun accord n'est à demander.
  bool get staysOnDevice =>
      kind.isLocal && isLoopback(Uri.tryParse(baseUrl.trim())?.host ?? '');

  static bool isLoopback(String host) =>
      host == 'localhost' ||
      host == '127.0.0.1' ||
      host == '::1' ||
      host == '10.0.2.2';
}

/// Niveau déclaré de l'apprenant, repris dans chaque consigne.
enum LearnerLevel {
  debutant('Débutant', 'débute en programmation Android'),
  intermediaire('Intermédiaire', 'connaît les bases de Kotlin et d\'Android'),
  avance('Avancé', 'développe déjà des applications complètes'),
  expert('Expert', 'maîtrise Android et cherche des réponses précises');

  const LearnerLevel(this.label, this.description);

  final String label;
  final String description;

  static LearnerLevel byName(String? name) {
    for (final level in values) {
      if (level.name == name) return level;
    }
    return debutant;
  }
}

/// État complet des réglages IA, reconstruit depuis la base.
class AiSettings {
  const AiSettings({
    this.configs = const {},
    this.keysSaved = const {},
    this.consents = const {},
    this.active,
    this.level = LearnerLevel.debutant,
  });

  final Map<AiProviderKind, AiProviderConfig> configs;
  final Set<AiProviderKind> keysSaved;
  final Set<AiProviderKind> consents;
  final AiProviderKind? active;
  final LearnerLevel level;

  AiProviderConfig configOf(AiProviderKind kind) =>
      configs[kind] ?? AiProviderConfig.initial(kind);

  bool isUsable(AiProviderKind kind) {
    final config = configOf(kind);
    final hasKey = keysSaved.contains(kind);
    return config.model.isNotEmpty &&
        (!kind.needsKey || hasKey) &&
        config.urlProblem(withKey: hasKey) == null;
  }

  /// Fournisseur prêt à répondre, ou `null` : l'application reste utilisable.
  AiProviderConfig? get activeConfig {
    final kind = active;
    return kind != null && isUsable(kind) ? configOf(kind) : null;
  }
}
