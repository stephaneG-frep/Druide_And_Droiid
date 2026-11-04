/// Barème d'expérience, provisoire : la phase 10 l'ajustera.
abstract final class Rewards {
  static const lesson = 20;
  static const quiz = 15;
  static const exercise = 10;
  static const evaluation = 50;
}

/// Pourcentage minimal pour réussir le quiz d'une leçon.
const lessonQuizPassPercent = 70;

String lessonQuizId(String lessonId) => 'lesson:$lessonId';

String evaluationQuizId(String moduleId) => 'eval:$moduleId';
