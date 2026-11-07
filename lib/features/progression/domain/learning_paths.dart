/// Parcours personnalisés : un ordre de modules selon l'objectif de l'apprenant.
enum LearningPath {
  natif('Développeur Android natif', [
    'fondations',
    'kotlin',
    'android-studio',
    'interfaces',
    'donnees-reseaux',
    'avance',
    'publication',
    'expert',
  ]),
  flutter('Développeur Flutter', [
    'fondations',
    'android-studio',
    'flutter',
    'donnees-reseaux',
    'publication',
    'expert',
  ]),
  securite('Sécurité Android', [
    'fondations',
    'kotlin',
    'donnees-reseaux',
    'avance',
    'securite',
  ]),
  ia('IA sur Android', [
    'fondations',
    'kotlin',
    'donnees-reseaux',
    'securite',
    'ia',
  ]),
  complet('Toute l\'Académie', [
    'fondations',
    'kotlin',
    'java',
    'android-studio',
    'interfaces',
    'donnees-reseaux',
    'flutter',
    'avance',
    'securite',
    'ia',
    'publication',
    'expert',
  ]);

  const LearningPath(this.label, this.modules);

  final String label;
  final List<String> modules;

  static LearningPath? byName(String? name) {
    for (final path in values) {
      if (path.name == name) return path;
    }
    return null;
  }
}

class NextLesson {
  const NextLesson(this.moduleId, this.lessonId);

  final String moduleId;
  final String lessonId;
}

/// Première leçon non terminée du parcours, ou `null` s'il est achevé.
NextLesson? nextLesson(
  LearningPath path,
  Map<String, List<String>> lessonsByModule,
  Set<String> completed,
) {
  for (final module in path.modules) {
    for (final lesson in lessonsByModule[module] ?? const <String>[]) {
      if (!completed.contains(lesson)) return NextLesson(module, lesson);
    }
  }
  return null;
}
