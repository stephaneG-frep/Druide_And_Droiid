import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    required this.badges,
  });

  static const start = ProgressSnapshot(
    xp: 0,
    lessonsCompleted: 0,
    quizzesPassed: 0,
    badges: 0,
  );

  final int xp;
  final int lessonsCompleted;
  final int quizzesPassed;
  final int badges;

  Rank get rank => Rank.forXp(xp);
}

/// Aucune activité n'existe encore : la phase 3 branchera ce fournisseur à SQLite.
final progressProvider = Provider<ProgressSnapshot>(
  (ref) => ProgressSnapshot.start,
);
