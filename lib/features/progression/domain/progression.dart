import 'package:flutter/material.dart';

/// Grades de l'Académie. Grand Druide demande d'avoir parcouru presque tout le
/// programme : `test/features/progression/gamification_test.dart` le vérifie.
enum Rank {
  apprenti('Apprenti du Droid', 0, Icons.auto_fix_normal),
  initie('Initié des Circuits', 150, Icons.memory),
  alchimiste('Alchimiste Kotlin', 500, Icons.science),
  mage('Mage des Interfaces', 1200, Icons.dashboard_customize),
  gardien('Gardien du SDK', 2400, Icons.shield),
  maitre('Maître du Débogage', 4000, Icons.bug_report),
  archimage('Archimage Android', 6500, Icons.auto_awesome),
  grandDruide('Grand Druide And-Droiīd', 9000, Icons.park);

  const Rank(this.title, this.minXp, this.icon);

  final String title;
  final int minXp;
  final IconData icon;

  static Rank forXp(int xp) {
    return values.lastWhere((rank) => xp >= rank.minXp, orElse: () => apprenti);
  }

  Rank? get next => index + 1 < values.length ? values[index + 1] : null;
}

/// Instantané de la progression de l'utilisateur.
class ProgressSnapshot {
  const ProgressSnapshot({
    required this.xp,
    required this.lessonsCompleted,
    required this.quizzesPassed,
  });

  static const start = ProgressSnapshot(
    xp: 0,
    lessonsCompleted: 0,
    quizzesPassed: 0,
  );

  final int xp;
  final int lessonsCompleted;

  /// Nombre de quiz différents réussis au moins une fois.
  final int quizzesPassed;

  Rank get rank => Rank.forXp(xp);
}

/// Meilleure tentative à un quiz.
class QuizBest {
  const QuizBest({
    required this.score,
    required this.maxScore,
    required this.passed,
  });

  final int score;
  final int maxScore;
  final bool passed;
}

/// Résultat de l'enregistrement d'une tentative de quiz.
class QuizOutcome {
  const QuizOutcome({required this.recorded, required this.xpEarned});

  /// `false` si la tentative a été ignorée car le quiz ne compte qu'une fois.
  final bool recorded;
  final int xpEarned;
}
