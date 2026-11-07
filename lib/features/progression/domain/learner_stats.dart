import '../../academie/domain/module_catalog.dart';

/// Ce que le programme contient, lu dans les cours et les projets.
class LearningCatalog {
  const LearningCatalog({
    required this.lessonsByModule,
    required this.lessonTitles,
    required this.projectLevels,
  });

  /// Leçons de chaque module, dans l'ordre.
  final Map<String, List<String>> lessonsByModule;
  final Map<String, String> lessonTitles;
  final Map<String, ModuleLevel> projectLevels;

  int get lessonCount =>
      lessonsByModule.values.fold(0, (sum, lessons) => sum + lessons.length);
}

class XpEntry {
  const XpEntry(this.source, this.amount, this.at);

  final String source;
  final int amount;
  final DateTime at;
}

/// Tout ce que l'apprenant a fait, lu en base.
class LearnerStats {
  const LearnerStats({
    this.completedLessons = const {},
    this.passedQuizzes = const {},
    this.perfectQuizzes = 0,
    this.evaluationDates = const {},
    this.exercisesDone = 0,
    this.labSolved = const {},
    this.projectsDone = const {},
    this.finalValidated = false,
    this.bugsVerified = const [],
    this.conversations = 0,
    this.xpEvents = const [],
    this.badges = const {},
  });

  final Set<String> completedLessons;
  final Set<String> passedQuizzes;
  final int perfectQuizzes;

  /// Modules dont l'évaluation est réussie, avec la date de la réussite.
  final Map<String, DateTime> evaluationDates;
  final int exercisesDone;
  final Set<String> labSolved;
  final Set<String> projectsDone;
  final bool finalValidated;
  final List<int> bugsVerified;
  final int conversations;
  final List<XpEntry> xpEvents;
  final Map<String, DateTime> badges;

  int get xp => xpEvents.fold(0, (sum, event) => sum + event.amount);

  bool moduleLessonsDone(LearningCatalog catalog, String moduleId) {
    final lessons = catalog.lessonsByModule[moduleId] ?? const [];
    return lessons.isNotEmpty && lessons.every(completedLessons.contains);
  }

  bool moduleCompleted(LearningCatalog catalog, String moduleId) =>
      moduleLessonsDone(catalog, moduleId) &&
      evaluationDates.containsKey(moduleId);

  int streak(DateTime today) => currentStreak({
    for (final event in xpEvents) _day(event.at),
  }, _day(today));

  int bestStreak() {
    final days = {for (final event in xpEvents) _day(event.at)}.toList()
      ..sort();
    var best = 0;
    var run = 0;
    DateTime? previous;
    for (final day in days) {
      run = previous != null && _nextDay(previous) == day ? run + 1 : 1;
      if (run > best) best = run;
      previous = day;
    }
    return best;
  }
}

DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);

// Pas d'ajout de 24 heures : un changement d'heure décalerait le jour.
DateTime _nextDay(DateTime day) => DateTime(day.year, day.month, day.day + 1);

DateTime _previousDay(DateTime day) =>
    DateTime(day.year, day.month, day.day - 1);

/// Jours consécutifs d'activité. Aujourd'hui peut encore rester vide : la série
/// ne casse que si hier l'est aussi.
int currentStreak(Set<DateTime> activeDays, DateTime today) {
  var cursor = activeDays.contains(today) ? today : _previousDay(today);
  var streak = 0;
  while (activeDays.contains(cursor)) {
    streak++;
    cursor = _previousDay(cursor);
  }
  return streak;
}
