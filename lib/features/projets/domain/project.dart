import '../../../design_system/code_highlighter.dart';
import '../../academie/domain/course.dart';
import '../../academie/domain/module_catalog.dart';

class ProjectCode {
  const ProjectCode({required this.language, required this.code, this.output});

  factory ProjectCode.fromJson(Map<String, Object?> json) {
    return ProjectCode(
      language: CodeLanguage.values.byName(json['language']! as String),
      code: json['code']! as String,
      output: json['output'] as String?,
    );
  }

  final CodeLanguage language;
  final String code;
  final String? output;
}

class ProjectStep {
  const ProjectStep({
    required this.title,
    required this.text,
    required this.verify,
    this.code,
  });

  factory ProjectStep.fromJson(Map<String, Object?> json) {
    final code = json['code'] as Map<String, Object?>?;
    return ProjectStep(
      title: json['title']! as String,
      text: json['text']! as String,
      verify: json['verify']! as String,
      code: code == null ? null : ProjectCode.fromJson(code),
    );
  }

  final String title;
  final String text;

  /// Ce que l'apprenant doit observer avant de cocher l'étape.
  final String verify;
  final ProjectCode? code;
}

class Project {
  const Project({
    required this.id,
    required this.level,
    required this.title,
    required this.stack,
    required this.objective,
    required this.prerequisites,
    required this.modules,
    required this.steps,
    required this.test,
    required this.testIntro,
    required this.criteria,
    required this.quiz,
  });

  factory Project.fromJson(Map<String, Object?> json) {
    List<String> strings(String key) =>
        (json[key]! as List<Object?>).cast<String>();

    return Project(
      id: json['id']! as String,
      level: ModuleLevel.values.byName(json['level']! as String),
      title: json['title']! as String,
      stack: json['stack']! as String,
      objective: json['objective']! as String,
      prerequisites: strings('prerequisites'),
      modules: strings('modules'),
      steps: (json['steps']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(ProjectStep.fromJson)
          .toList(),
      test: ProjectCode.fromJson(json['test']! as Map<String, Object?>),
      testIntro: json['testIntro']! as String,
      criteria: strings('criteria'),
      quiz: (json['quiz']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(
            (question) => CourseQuestion(
              prompt: question['prompt']! as String,
              options: (question['options']! as List<Object?>).cast<String>(),
              answers: (question['answers']! as List<Object?>)
                  .cast<int>()
                  .toSet(),
              explanation: question['explanation']! as String,
            ),
          )
          .toList(),
    );
  }

  final String id;
  final ModuleLevel level;
  final String title;
  final String stack;
  final String objective;
  final List<String> prerequisites;
  final List<String> modules;
  final List<ProjectStep> steps;
  final ProjectCode test;
  final String testIntro;
  final List<String> criteria;
  final List<CourseQuestion> quiz;
}

List<Project> parseProjects(Map<String, Object?> json) {
  return (json['projects']! as List<Object?>)
      .cast<Map<String, Object?>>()
      .map(Project.fromJson)
      .toList();
}

/// Avancement lu en base, décodé.
class ProjectState {
  const ProjectState({
    this.doneSteps = const {},
    this.doneCriteria = const {},
    this.quizPassed = false,
    this.proof = '',
    this.completed = false,
  });

  final Set<int> doneSteps;
  final Set<int> doneCriteria;
  final bool quizPassed;
  final String proof;
  final bool completed;

  bool get started =>
      doneSteps.isNotEmpty || doneCriteria.isNotEmpty || quizPassed;

  /// Ce qui manque encore : un projet ne se déclare pas terminé sans preuve.
  List<String> missing(Project project) => [
    if (doneSteps.length < project.steps.length) 'toutes les étapes',
    if (!quizPassed) 'le questionnaire',
    if (doneCriteria.length < project.criteria.length)
      'tous les critères de réussite',
    if (proof.trim().isEmpty) 'une preuve',
  ];
}
