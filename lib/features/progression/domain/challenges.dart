import 'learner_stats.dart';

enum ChallengePeriod { day, week }

class Challenge {
  const Challenge(
    this.id,
    this.title,
    this.prefix,
    this.count,
    this.xp,
    this.period,
  );

  final String id;
  final String title;

  /// Préfixe des sources d'expérience qui comptent pour ce défi.
  final String prefix;
  final int count;
  final int xp;
  final ChallengePeriod period;
}

const _daily = [
  Challenge(
    'lecon',
    'Terminer une leçon',
    'lesson:',
    1,
    15,
    ChallengePeriod.day,
  ),
  Challenge(
    'quiz',
    'Réussir un quiz de leçon',
    'quiz:lesson:',
    1,
    15,
    ChallengePeriod.day,
  ),
  Challenge(
    'flash',
    'Réussir la question flash',
    'quiz:flash',
    1,
    10,
    ChallengePeriod.day,
  ),
  Challenge(
    'exercice',
    'Réussir un exercice',
    'exercise:',
    1,
    15,
    ChallengePeriod.day,
  ),
  Challenge(
    'lab',
    'Réussir un exercice au Lab',
    'lab:',
    1,
    20,
    ChallengePeriod.day,
  ),
];

const _weekly = [
  Challenge(
    'lecons',
    'Terminer trois leçons',
    'lesson:',
    3,
    40,
    ChallengePeriod.week,
  ),
  Challenge(
    'quizzes',
    'Réussir cinq quiz de leçon',
    'quiz:lesson:',
    5,
    40,
    ChallengePeriod.week,
  ),
  Challenge(
    'labs',
    'Réussir deux exercices au Lab',
    'lab:',
    2,
    40,
    ChallengePeriod.week,
  ),
  Challenge(
    'projet',
    'Terminer un projet',
    'project:',
    1,
    60,
    ChallengePeriod.week,
  ),
];

DateTime _dayOf(DateTime date) => DateTime(date.year, date.month, date.day);

/// Lundi de la semaine.
DateTime weekStart(DateTime date) =>
    DateTime(date.year, date.month, date.day - (date.weekday - 1));

int _daysSinceEpoch(DateTime day) =>
    DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

/// Deux défis du jour et un de la semaine, identiques toute la période.
List<Challenge> challengesFor(DateTime date) {
  final day = _daysSinceEpoch(date);
  final week = _daysSinceEpoch(weekStart(date)) ~/ 7;
  return [
    _daily[day % _daily.length],
    _daily[(day + 2) % _daily.length],
    _weekly[week % _weekly.length],
  ];
}

DateTime periodStart(Challenge challenge, DateTime date) =>
    challenge.period == ChallengePeriod.day ? _dayOf(date) : weekStart(date);

/// Source unique d'une réclamation : un défi ne paie qu'une fois par période.
String challengeSource(Challenge challenge, DateTime date) {
  final start = periodStart(challenge, date);
  final stamp = '${start.year}-${start.month}-${start.day}';
  return 'challenge:$stamp:${challenge.id}';
}

int challengeProgress(Challenge challenge, LearnerStats stats, DateTime date) {
  final start = periodStart(challenge, date);
  return stats.xpEvents
      .where(
        (event) =>
            event.source.startsWith(challenge.prefix) &&
            !event.at.isBefore(start),
      )
      .length;
}

int lessonsThisWeek(LearnerStats stats, DateTime date) {
  final start = weekStart(date);
  return stats.xpEvents
      .where(
        (event) =>
            event.source.startsWith('lesson:') && !event.at.isBefore(start),
      )
      .length;
}
