import '../../../design_system/code_highlighter.dart';

/// Contenu détaillé d'un module, chargé depuis `assets/courses/<module>.json`.
class Course {
  const Course({
    required this.moduleId,
    required this.lessons,
    required this.evaluation,
    required this.resources,
  });

  factory Course.fromJson(Map<String, Object?> json) {
    final path = JsonPath('cours');
    final course = Course(
      moduleId: path.string(json, 'moduleId'),
      lessons: path.list(json, 'lessons', Lesson.fromJson),
      evaluation: Evaluation.fromJson(
        path.map(json, 'evaluation'),
        path.child('evaluation'),
      ),
      resources: path.list(json, 'resources', Resource.fromJson),
    );
    if (course.lessons.isEmpty) path.fail('aucune leçon');
    return course;
  }

  final String moduleId;
  final List<Lesson> lessons;
  final Evaluation evaluation;
  final List<Resource> resources;

  Lesson? lessonById(String id) {
    for (final lesson in lessons) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }

  /// Leçon suivante dans le module, ou `null` à la fin.
  Lesson? lessonAfter(String id) {
    final index = lessons.indexWhere((lesson) => lesson.id == id);
    return index < 0 || index + 1 >= lessons.length ? null : lessons[index + 1];
  }
}

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.minutes,
    required this.blocks,
    required this.quiz,
    required this.exercises,
  });

  factory Lesson.fromJson(Map<String, Object?> json, JsonPath path) {
    final lesson = Lesson(
      id: path.string(json, 'id'),
      title: path.string(json, 'title'),
      minutes: path.integer(json, 'minutes'),
      blocks: path.list(json, 'blocks', LessonBlock.fromJson),
      quiz: path.list(json, 'quiz', CourseQuestion.fromJson),
      exercises: path.list(json, 'exercises', Exercise.fromJson),
    );
    if (lesson.blocks.isEmpty) path.fail('leçon sans contenu');
    return lesson;
  }

  final String id;
  final String title;
  final int minutes;
  final List<LessonBlock> blocks;
  final List<CourseQuestion> quiz;
  final List<Exercise> exercises;
}

enum CalloutKind { info, warning }

sealed class LessonBlock {
  const LessonBlock();

  factory LessonBlock.fromJson(Map<String, Object?> json, JsonPath path) {
    final type = path.string(json, 'type');
    return switch (type) {
      'heading' => HeadingBlock(path.string(json, 'text')),
      'paragraph' => ParagraphBlock(path.string(json, 'text')),
      'list' => ListBlock(path.strings(json, 'items')),
      'code' => CodeBlock(
        language: path.language(json),
        code: path.string(json, 'code'),
      ),
      'info' => CalloutBlock(CalloutKind.info, path.string(json, 'text')),
      'warning' => CalloutBlock(CalloutKind.warning, path.string(json, 'text')),
      'tip' => TipBlock(path.string(json, 'text')),
      'layers' => LayersBlock(
        title: path.string(json, 'title'),
        layers: path.list(json, 'layers', DiagramLayer.fromJson),
      ),
      _ => path.fail('type de bloc inconnu : $type'),
    };
  }
}

class HeadingBlock extends LessonBlock {
  const HeadingBlock(this.text);

  final String text;
}

class ParagraphBlock extends LessonBlock {
  const ParagraphBlock(this.text);

  final String text;
}

class ListBlock extends LessonBlock {
  const ListBlock(this.items);

  final List<String> items;
}

class CodeBlock extends LessonBlock {
  const CodeBlock({required this.language, required this.code});

  final CodeLanguage language;
  final String code;
}

class CalloutBlock extends LessonBlock {
  const CalloutBlock(this.kind, this.text);

  final CalloutKind kind;
  final String text;
}

/// Conseil du Maître And-Droiīd, rédigé à l'avance.
class TipBlock extends LessonBlock {
  const TipBlock(this.text);

  final String text;
}

/// Schéma en couches empilées, de la plus haute à la plus basse.
class LayersBlock extends LessonBlock {
  const LayersBlock({required this.title, required this.layers});

  final String title;
  final List<DiagramLayer> layers;
}

class DiagramLayer {
  const DiagramLayer({required this.name, required this.detail});

  factory DiagramLayer.fromJson(Map<String, Object?> json, JsonPath path) {
    return DiagramLayer(
      name: path.string(json, 'name'),
      detail: path.string(json, 'detail'),
    );
  }

  final String name;
  final String detail;
}

/// Question à une ou plusieurs bonnes réponses.
class CourseQuestion {
  const CourseQuestion({
    required this.prompt,
    required this.options,
    required this.answers,
    required this.explanation,
  });

  factory CourseQuestion.fromJson(Map<String, Object?> json, JsonPath path) {
    final options = path.strings(json, 'options');
    final answers = path.integers(json, 'answers').toSet();
    if (options.length < 2) path.fail('moins de deux options');
    if (answers.isEmpty) path.fail('aucune bonne réponse');
    if (answers.any((answer) => answer < 0 || answer >= options.length)) {
      path.fail('bonne réponse hors des options');
    }
    return CourseQuestion(
      prompt: path.string(json, 'prompt'),
      options: options,
      answers: answers,
      explanation: path.string(json, 'explanation'),
    );
  }

  final String prompt;
  final List<String> options;
  final Set<int> answers;
  final String explanation;

  bool get isMultiple => answers.length > 1;

  bool isCorrect(Set<int> selected) {
    return selected.length == answers.length && selected.containsAll(answers);
  }
}

/// Note d'un questionnaire. Une question multiple ne compte que si elle est
/// entièrement juste.
int scoreOf(List<CourseQuestion> questions, Map<int, Set<int>> selections) {
  var score = 0;
  for (final (index, question) in questions.indexed) {
    if (question.isCorrect(selections[index] ?? const {})) score++;
  }
  return score;
}

bool hasPassed(int score, int maxScore, int passPercent) {
  return maxScore > 0 && score * 100 >= maxScore * passPercent;
}

class Evaluation {
  const Evaluation({required this.passPercent, required this.questions});

  factory Evaluation.fromJson(Map<String, Object?> json, JsonPath path) {
    final evaluation = Evaluation(
      passPercent: path.integer(json, 'passPercent'),
      questions: path.list(json, 'questions', CourseQuestion.fromJson),
    );
    if (evaluation.questions.isEmpty) path.fail('évaluation sans question');
    if (evaluation.passPercent < 1 || evaluation.passPercent > 100) {
      path.fail('seuil de réussite invalide');
    }
    return evaluation;
  }

  final int passPercent;
  final List<CourseQuestion> questions;
}

enum ExerciseKind { fill, self }

/// Exercice sans exécution de code :
/// - `fill` : réponse courte corrigée automatiquement ;
/// - `self` : réponse libre comparée au corrigé par l'apprenant.
class Exercise {
  const Exercise({
    required this.id,
    required this.kind,
    required this.prompt,
    required this.solution,
    required this.accepted,
    required this.solutionLanguage,
  });

  factory Exercise.fromJson(Map<String, Object?> json, JsonPath path) {
    final kind = switch (path.string(json, 'kind')) {
      'fill' => ExerciseKind.fill,
      'self' => ExerciseKind.self,
      final other => path.fail('type d\'exercice inconnu : $other'),
    };
    final accepted = kind == ExerciseKind.fill
        ? path.strings(json, 'accepted')
        : const <String>[];
    if (kind == ExerciseKind.fill && accepted.isEmpty) {
      path.fail('aucune réponse acceptée');
    }
    return Exercise(
      id: path.string(json, 'id'),
      kind: kind,
      prompt: path.string(json, 'prompt'),
      solution: path.string(json, 'solution'),
      accepted: accepted,
      solutionLanguage: json.containsKey('language')
          ? path.language(json)
          : null,
    );
  }

  final String id;
  final ExerciseKind kind;
  final String prompt;
  final String solution;
  final List<String> accepted;

  /// Langage du corrigé, s'il s'agit de code.
  final CodeLanguage? solutionLanguage;

  /// Compare sans tenir compte de la casse ni des espaces en trop.
  bool accepts(String answer) {
    String normalize(String text) =>
        text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return accepted.map(normalize).contains(normalize(answer));
  }
}

class Resource {
  const Resource({required this.title, required this.url});

  factory Resource.fromJson(Map<String, Object?> json, JsonPath path) {
    return Resource(
      title: path.string(json, 'title'),
      url: path.string(json, 'url'),
    );
  }

  final String title;
  final String url;
}

/// Lecture validée du JSON : une erreur indique où se trouve le problème.
class JsonPath {
  JsonPath(this.location);

  final String location;

  JsonPath child(String key) => JsonPath('$location > $key');

  Never fail(String message) {
    throw FormatException('$location : $message');
  }

  Object? _read(Map<String, Object?> json, String key) {
    if (!json.containsKey(key)) fail('champ manquant « $key »');
    return json[key];
  }

  T _typed<T>(Map<String, Object?> json, String key, String expected) {
    final value = _read(json, key);
    return value is T ? value : fail('« $key » doit être $expected');
  }

  String string(Map<String, Object?> json, String key) {
    final value = _typed<String>(json, key, 'un texte');
    if (value.trim().isEmpty) fail('« $key » est vide');
    return value;
  }

  int integer(Map<String, Object?> json, String key) {
    return _typed<int>(json, key, 'un entier');
  }

  Map<String, Object?> map(Map<String, Object?> json, String key) {
    return _typed<Map<String, Object?>>(json, key, 'un objet');
  }

  List<String> strings(Map<String, Object?> json, String key) {
    final values = _typed<List<Object?>>(json, key, 'une liste');
    if (values.any((value) => value is! String)) {
      fail('« $key » doit contenir des textes');
    }
    return values.cast<String>();
  }

  List<int> integers(Map<String, Object?> json, String key) {
    final values = _typed<List<Object?>>(json, key, 'une liste');
    if (values.any((value) => value is! int)) {
      fail('« $key » doit contenir des entiers');
    }
    return values.cast<int>();
  }

  List<T> list<T>(
    Map<String, Object?> json,
    String key,
    T Function(Map<String, Object?>, JsonPath) parse,
  ) {
    final values = _typed<List<Object?>>(json, key, 'une liste');
    return [
      for (final (index, value) in values.indexed)
        value is Map<String, Object?>
            ? parse(value, child('$key[$index]'))
            : fail('« $key[$index] » doit être un objet'),
    ];
  }

  CodeLanguage language(Map<String, Object?> json) {
    final name = string(json, 'language');
    return CodeLanguage.values.asNameMap()[name] ??
        fail('langage inconnu : $name');
  }
}
