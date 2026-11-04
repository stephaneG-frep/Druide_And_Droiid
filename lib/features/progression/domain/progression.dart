import 'package:flutter/material.dart';

/// Grades de l'Académie. Les seuils sont provisoires : la phase 10 les ajustera.
enum Rank {
  apprenti('Apprenti du Droid', 0, Icons.auto_fix_normal),
  initie('Initié des Circuits', 100, Icons.memory),
  alchimiste('Alchimiste Kotlin', 300, Icons.science),
  mage('Mage des Interfaces', 600, Icons.dashboard_customize),
  gardien('Gardien du SDK', 1000, Icons.shield),
  maitre('Maître du Débogage', 1500, Icons.bug_report),
  archimage('Archimage Android', 2200, Icons.auto_awesome),
  grandDruide('Grand Druide And-Droiīd', 3000, Icons.park);

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

/// Résultat de l'enregistrement d'une tentative de quiz.
class QuizOutcome {
  const QuizOutcome({required this.recorded, required this.xpEarned});

  /// `false` si la tentative a été ignorée car le quiz ne compte qu'une fois.
  final bool recorded;
  final int xpEarned;
}
