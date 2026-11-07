import '../domain/module_catalog.dart';

/// Barème d'expérience. Chaque action ne rapporte qu'une fois.
abstract final class Rewards {
  static const lesson = 20;
  static const quiz = 15;
  static const exercise = 10;
  static const evaluation = 50;
  static const labExercise = 15;
  static const bugVerified = 20;

  /// Un dossier se déclare librement : au-delà, il ne rapporte plus rien.
  static const bugVerifiedLimit = 10;
  static const finalProject = 500;

  static int project(ModuleLevel level) => switch (level) {
    ModuleLevel.debutant => 50,
    ModuleLevel.intermediaire => 100,
    ModuleLevel.avance => 150,
    ModuleLevel.expert => 200,
  };
}

/// Pourcentage minimal pour réussir le quiz d'une leçon.
const lessonQuizPassPercent = 70;

String lessonQuizId(String lessonId) => 'lesson:$lessonId';

String evaluationQuizId(String moduleId) => 'eval:$moduleId';
