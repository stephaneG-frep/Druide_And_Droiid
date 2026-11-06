import '../../../design_system/code_highlighter.dart';

const labLanguages = [
  CodeLanguage.kotlin,
  CodeLanguage.java,
  CodeLanguage.dart,
  CodeLanguage.xml,
];

class LabExercise {
  const LabExercise({
    required this.id,
    required this.language,
    required this.title,
    required this.level,
    required this.statement,
    required this.starter,
    this.solution,
    this.expectedOutput,
    this.required = const [],
  });

  factory LabExercise.fromJson(Map<String, Object?> json) {
    return LabExercise(
      id: json['id']! as String,
      language: CodeLanguage.values.byName(json['language']! as String),
      title: json['title']! as String,
      level: json['level']! as String,
      statement: json['statement']! as String,
      starter: json['starter']! as String,
      solution: json['solution']! as String,
      expectedOutput: json['expectedOutput'] as String?,
      required: ((json['required'] as List<Object?>?) ?? const [])
          .cast<String>(),
    );
  }

  /// Feuille libre : pas d'énoncé, pas de corrigé.
  factory LabExercise.free(CodeLanguage language) {
    return LabExercise(
      id: 'libre-${language.name}',
      language: language,
      title: 'Feuille libre ${language.label}',
      level: 'Libre',
      statement: 'Écrivez ce que vous voulez : rien n\'est corrigé ici.',
      starter: switch (language) {
        CodeLanguage.kotlin => 'fun main() {\n    println("Bonjour")\n}',
        CodeLanguage.java =>
          'public class Main {\n'
              '    public static void main(String[] args) {\n'
              '        System.out.println("Bonjour");\n'
              '    }\n'
              '}',
        CodeLanguage.dart => "void main() {\n  print('Bonjour');\n}",
        _ => '<?xml version="1.0" encoding="utf-8"?>\n<racine />',
      },
    );
  }

  final String id;
  final CodeLanguage language;
  final String title;
  final String level;
  final String statement;
  final String starter;
  final String? solution;
  final String? expectedOutput;

  /// Éléments attendus dans un exercice XML.
  final List<String> required;

  bool get isFree => solution == null;

  String get fileName => switch (language) {
    CodeLanguage.kotlin => 'Main.kt',
    CodeLanguage.java => 'Main.java',
    CodeLanguage.dart => 'main.dart',
    _ => '$id.xml',
  };
}

List<LabExercise> parseExercises(Map<String, Object?> json) {
  return (json['exercises']! as List<Object?>)
      .cast<Map<String, Object?>>()
      .map(LabExercise.fromJson)
      .toList();
}
