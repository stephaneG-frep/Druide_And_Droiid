import 'package:drift/drift.dart';

/// Paires clé/valeur techniques et réglages.
class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class LessonProgress extends Table {
  TextColumn get lessonId => text()();
  TextColumn get moduleId => text()();
  DateTimeColumn get completedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {lessonId};
}

class QuizAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get quizId => text()();
  IntColumn get score => integer()();
  IntColumn get maxScore => integer()();
  BoolColumn get passed => boolean()();
  DateTimeColumn get attemptedAt => dateTime()();
}

/// Registre de l'expérience. L'unicité de [source] garantit qu'une même action
/// ne rapporte jamais deux fois, quels que soient les appels.
class XpEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get source => text().unique()();
  IntColumn get amount => integer()();
  DateTimeColumn get earnedAt => dateTime()();
}

@DataClassName('NoteRow')
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get body => text()();

  /// Module de l'Académie lié à la note, s'il y en a un.
  TextColumn get moduleId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class Favorites extends Table {
  TextColumn get kind => text()();
  TextColumn get targetId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {kind, targetId};
}
