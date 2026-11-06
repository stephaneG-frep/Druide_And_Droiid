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

/// Réponse de l'apprenant à un exercice, conservée entre deux sessions.
class ExerciseAnswers extends Table {
  TextColumn get exerciseId => text()();
  TextColumn get moduleId => text()();
  TextColumn get answer => text()();
  TextColumn get status => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {exerciseId};
}

class Favorites extends Table {
  TextColumn get kind => text()();
  TextColumn get targetId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {kind, targetId};
}

/// Conversation avec le Professeur IA.
@DataClassName('AiConversationRow')
class AiConversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get providerKind => text()();
  TextColumn get model => text()();
  TextColumn get mode => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('AiMessageRow')
class AiMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conversationId => integer().references(AiConversations, #id)();
  TextColumn get role => text()();
  TextColumn get content => text()();

  /// Jetons annoncés par le fournisseur, s'il les communique.
  IntColumn get inputTokens => integer().nullable()();
  IntColumn get outputTokens => integer().nullable()();

  /// Fin de la réponse : terminée, coupée, refusée ou interrompue.
  TextColumn get stopReason => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}
