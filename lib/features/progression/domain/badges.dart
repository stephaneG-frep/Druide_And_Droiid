import 'package:flutter/material.dart';

import '../../academie/domain/module_catalog.dart';
import 'learner_stats.dart';

class Badge {
  const Badge(this.id, this.title, this.description, this.icon, this.earned);

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool Function(LearnerStats stats, LearningCatalog catalog) earned;
}

int _modulesDone(LearnerStats stats, LearningCatalog catalog) => catalog
    .lessonsByModule
    .keys
    .where((module) => stats.moduleCompleted(catalog, module))
    .length;

int _labWith(LearnerStats stats, String prefix) =>
    stats.labSolved.where((id) => id.startsWith(prefix)).length;

bool _projectAt(
  LearnerStats stats,
  LearningCatalog catalog,
  ModuleLevel level,
) => stats.projectsDone.any((id) => catalog.projectLevels[id] == level);

final badges = <Badge>[
  Badge(
    'premiere-lecon',
    'Première page',
    'Terminer une leçon.',
    Icons.menu_book,
    (stats, _) => stats.completedLessons.isNotEmpty,
  ),
  Badge(
    'dix-lecons',
    'Lecteur assidu',
    'Terminer dix leçons.',
    Icons.auto_stories,
    (stats, _) => stats.completedLessons.length >= 10,
  ),
  Badge(
    'cinquante-lecons',
    'Rat de bibliothèque',
    'Terminer cinquante leçons.',
    Icons.local_library,
    (stats, _) => stats.completedLessons.length >= 50,
  ),
  Badge(
    'premier-quiz',
    'Première étincelle',
    'Réussir un quiz.',
    Icons.quiz,
    (stats, _) => stats.passedQuizzes.isNotEmpty,
  ),
  Badge(
    'quiz-parfait',
    'Sans-faute',
    'Obtenir toutes les réponses à un quiz.',
    Icons.grade,
    (stats, _) => stats.perfectQuizzes >= 1,
  ),
  Badge(
    'dix-exercices',
    'Main sûre',
    'Réussir dix exercices de l\'Académie.',
    Icons.edit_note,
    (stats, _) => stats.exercisesDone >= 10,
  ),
  Badge(
    'premier-module',
    'Module accompli',
    'Terminer un module et son évaluation.',
    Icons.workspace_premium,
    (stats, catalog) => _modulesDone(stats, catalog) >= 1,
  ),
  Badge(
    'tous-modules',
    'Encyclopédiste',
    'Terminer les douze modules.',
    Icons.school,
    (stats, catalog) =>
        catalog.lessonsByModule.isNotEmpty &&
        _modulesDone(stats, catalog) == catalog.lessonsByModule.length,
  ),
  Badge(
    'lab-kotlin',
    'Forgeron Kotlin',
    'Réussir un exercice Kotlin au Lab.',
    Icons.terminal,
    (stats, _) => _labWith(stats, 'kt-') >= 1,
  ),
  Badge(
    'lab-java',
    'Vétéran Java',
    'Réussir un exercice Java au Lab.',
    Icons.coffee,
    (stats, _) => _labWith(stats, 'java-') >= 1,
  ),
  Badge(
    'lab-dart',
    'Tisseur de Dart',
    'Réussir un exercice Dart au Lab.',
    Icons.flutter_dash,
    (stats, _) => _labWith(stats, 'dart-') >= 1,
  ),
  Badge(
    'lab-xml',
    'Architecte XML',
    'Réussir un exercice XML au Lab.',
    Icons.code,
    (stats, _) => _labWith(stats, 'xml-') >= 1,
  ),
  Badge(
    'chasseur',
    'Chasseur de bugs',
    'Vérifier la correction d\'un bug.',
    Icons.pest_control,
    (stats, _) => stats.bugsVerified.isNotEmpty,
  ),
  Badge(
    'interlocuteur',
    'Disciple curieux',
    'Ouvrir une conversation avec le Maître.',
    Icons.forum,
    (stats, _) => stats.conversations >= 1,
  ),
  Badge(
    'projet-debutant',
    'Premier chantier',
    'Terminer un projet débutant.',
    Icons.construction,
    (stats, catalog) => _projectAt(stats, catalog, ModuleLevel.debutant),
  ),
  Badge(
    'projet-intermediaire',
    'Bâtisseur',
    'Terminer un projet intermédiaire.',
    Icons.handyman,
    (stats, catalog) => _projectAt(stats, catalog, ModuleLevel.intermediaire),
  ),
  Badge(
    'projet-avance',
    'Ingénieur des arcanes',
    'Terminer un projet avancé.',
    Icons.precision_manufacturing,
    (stats, catalog) => _projectAt(stats, catalog, ModuleLevel.avance),
  ),
  Badge(
    'projet-expert',
    'Maître d\'œuvre',
    'Terminer un projet expert.',
    Icons.rocket_launch,
    (stats, catalog) => _projectAt(stats, catalog, ModuleLevel.expert),
  ),
  Badge(
    'evaluation-finale',
    'Épreuve du Druide',
    'Valider l\'évaluation finale.',
    Icons.military_tech,
    (stats, _) => stats.finalValidated,
  ),
  Badge(
    'serie-sept',
    'Sept jours de magie',
    'Apprendre sept jours de suite.',
    Icons.local_fire_department,
    (stats, _) => stats.bestStreak() >= 7,
  ),
];
