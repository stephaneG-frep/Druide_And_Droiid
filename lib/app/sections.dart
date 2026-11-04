import 'package:flutter/material.dart';

/// Rubriques de l'application : source unique pour le routage et les menus.
enum AppSection {
  accueil(
    path: '/accueil',
    label: 'Accueil',
    description: 'Votre tableau de bord et la suite de votre parcours.',
    icon: Icons.home_outlined,
    plannedPhase: 2,
  ),
  academie(
    path: '/academie',
    label: 'Académie',
    description: 'Les douze modules, des fondations au niveau expert.',
    icon: Icons.school_outlined,
    plannedPhase: 4,
  ),
  maitre(
    path: '/maitre',
    label: 'Maître',
    description: 'Maître And-Droiīd, votre professeur IA.',
    icon: Icons.smart_toy_outlined,
    plannedPhase: 6,
  ),
  lab(
    path: '/lab',
    label: 'Lab',
    description: 'Android Lab : éditeur, exercices et outils Linux.',
    icon: Icons.science_outlined,
    plannedPhase: 7,
  ),
  chaudron(
    path: '/plus/chaudron',
    label: 'Chaudron des Bugs',
    description: 'Analysez erreurs et logs pour comprendre vos pannes.',
    icon: Icons.bug_report_outlined,
    plannedPhase: 8,
  ),
  projets(
    path: '/plus/projets',
    label: 'Projets',
    description: 'Des projets guidés, du débutant à l\'expert.',
    icon: Icons.build_outlined,
    plannedPhase: 9,
  ),
  progression(
    path: '/plus/progression',
    label: 'Progression',
    description: 'Niveaux, badges, défis et statistiques.',
    icon: Icons.emoji_events_outlined,
    plannedPhase: 10,
  ),
  grimoire(
    path: '/plus/grimoire',
    label: 'Grimoire du Druide',
    description: 'Le mode d\'emploi de l\'application.',
    icon: Icons.menu_book_outlined,
    plannedPhase: 11,
  ),
  parametres(
    path: '/plus/parametres',
    label: 'Paramètres',
    description: 'Apparence, fournisseurs IA et sauvegardes.',
    icon: Icons.settings_outlined,
    plannedPhase: 11,
  );

  const AppSection({
    required this.path,
    required this.label,
    required this.description,
    required this.icon,
    required this.plannedPhase,
  });

  final String path;
  final String label;
  final String description;
  final IconData icon;

  /// Phase de la feuille de route qui livrera le contenu de la rubrique.
  final int plannedPhase;

  /// Rubriques ayant leur propre onglet de navigation.
  static const primary = [accueil, academie, maitre, lab];

  /// Rubriques regroupées derrière l'onglet « Plus ».
  static const secondary = [
    chaudron,
    projets,
    progression,
    grimoire,
    parametres,
  ];
}
