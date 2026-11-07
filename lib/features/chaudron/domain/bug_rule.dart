import '../../../design_system/code_highlighter.dart';

enum BugFamily {
  gradle('Erreurs Gradle'),
  sdk('Problèmes SDK'),
  adb('Erreurs ADB'),
  apk('APK incompatibles'),
  abi('Problèmes ABI'),
  crash('Crashs au démarrage'),
  splash('Blocages sur splash screen'),
  permissions('Erreurs de permissions'),
  dependances('Problèmes de dépendances'),
  flutter('Erreurs Flutter/Dart');

  const BugFamily(this.label);

  final String label;
}

class BugExample {
  const BugExample(this.language, this.code);

  final CodeLanguage language;
  final String code;
}

/// Fiche rédigée à l'avance, reconnue par des mots-clés. Ce n'est pas une IA, et
/// l'écran doit toujours le dire.
class BugRule {
  BugRule({
    required this.id,
    required this.family,
    required this.title,
    required List<String> patterns,
    required this.samples,
    required this.summary,
    required this.causes,
    required this.checks,
    required this.fixes,
    required this.lesson,
    required this.validation,
    this.example,
  }) : patterns = patterns.map(RegExp.new).toList();

  factory BugRule.fromJson(Map<String, Object?> json) {
    List<String> strings(String key) =>
        (json[key]! as List<Object?>).cast<String>();
    final example = json['example'] as Map<String, Object?>?;

    return BugRule(
      id: json['id']! as String,
      family: BugFamily.values.byName(json['family']! as String),
      title: json['title']! as String,
      patterns: strings('patterns'),
      samples: strings('samples'),
      summary: json['summary']! as String,
      causes: strings('causes'),
      checks: strings('checks'),
      fixes: strings('fixes'),
      lesson: json['lesson']! as String,
      validation: strings('validation'),
      example: example == null
          ? null
          : BugExample(
              CodeLanguage.values.byName(example['language']! as String),
              example['code']! as String,
            ),
    );
  }

  final String id;
  final BugFamily family;
  final String title;
  final List<RegExp> patterns;

  /// Messages représentatifs, vérifiés par les tests.
  final List<String> samples;
  final String summary;
  final List<String> causes;
  final List<String> checks;
  final List<String> fixes;
  final String lesson;
  final List<String> validation;
  final BugExample? example;

  int? firstMatch(String text) {
    int? first;
    for (final pattern in patterns) {
      final start = pattern.firstMatch(text)?.start;
      if (start != null && (first == null || start < first)) first = start;
    }
    return first;
  }
}

List<BugRule> parseRules(Map<String, Object?> json) {
  return (json['rules']! as List<Object?>)
      .cast<Map<String, Object?>>()
      .map(BugRule.fromJson)
      .toList();
}

/// Fiches reconnues, de la première erreur du texte à la dernière : les
/// suivantes sont souvent des conséquences.
List<BugRule> matchRules(List<BugRule> rules, String text) {
  final matches = [
    for (final rule in rules)
      if (rule.firstMatch(text) case final position?) (position, rule),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final match in matches) match.$2];
}
