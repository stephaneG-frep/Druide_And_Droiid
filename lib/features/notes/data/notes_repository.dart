import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/persistence/app_database.dart';
import '../domain/note.dart';

class NotesRepository {
  const NotesRepository(this._database, this._now);

  final AppDatabase _database;
  final DateTime Function() _now;

  /// Notes les plus récemment modifiées d'abord, éventuellement d'un seul module.
  Stream<List<Note>> watch({String? moduleId}) {
    final query = _database.select(_database.notes)
      ..orderBy([
        (row) => OrderingTerm.desc(row.updatedAt),
        (row) => OrderingTerm.desc(row.id),
      ]);
    if (moduleId != null) {
      query.where((row) => row.moduleId.equals(moduleId));
    }
    return query.watch().map((rows) => rows.map(_toNote).toList());
  }

  Future<Note?> find(int id) async {
    final query = _database.select(_database.notes)
      ..where((row) => row.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _toNote(row);
  }

  Future<int> create({
    required String title,
    required String body,
    String? moduleId,
  }) {
    final now = _now();
    return _database
        .into(_database.notes)
        .insert(
          NotesCompanion.insert(
            title: title,
            body: body,
            moduleId: Value(moduleId),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> update(int id, {required String title, required String body}) {
    final query = _database.update(_database.notes)
      ..where((row) => row.id.equals(id));
    return query.write(
      NotesCompanion(
        title: Value(title),
        body: Value(body),
        updatedAt: Value(_now()),
      ),
    );
  }

  Future<void> delete(int id) {
    final query = _database.delete(_database.notes)
      ..where((row) => row.id.equals(id));
    return query.go();
  }

  Note _toNote(NoteRow row) => Note(
    id: row.id,
    title: row.title,
    body: row.body,
    moduleId: row.moduleId,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

final notesRepositoryProvider = Provider<NotesRepository>(
  (ref) =>
      NotesRepository(ref.watch(appDatabaseProvider), ref.watch(clockProvider)),
);

final notesProvider = StreamProvider<List<Note>>(
  (ref) => ref.watch(notesRepositoryProvider).watch(),
);

final moduleNotesProvider = StreamProvider.family<List<Note>, String>(
  (ref, moduleId) =>
      ref.watch(notesRepositoryProvider).watch(moduleId: moduleId),
);
