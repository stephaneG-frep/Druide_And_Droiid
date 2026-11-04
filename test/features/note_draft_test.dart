import 'dart:async';

import 'package:druide_and_droiid/core/persistence/app_database.dart';
import 'package:drift/native.dart';
import 'package:druide_and_droiid/features/notes/data/notes_repository.dart';
import 'package:druide_and_droiid/features/notes/presentation/note_draft.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dépôt instrumenté : compte les appels, peut échouer ou faire patienter.
class _SpyRepository implements NotesRepository {
  var creates = 0;
  var updates = 0;
  var fail = false;
  String? lastBody;
  Completer<void>? gate;

  @override
  Future<int> create({
    required String title,
    required String body,
    String? moduleId,
  }) async {
    creates++;
    await gate?.future;
    if (fail) throw Exception('disque plein');
    lastBody = body;
    return 7;
  }

  @override
  Future<void> update(
    int id, {
    required String title,
    required String body,
  }) async {
    updates++;
    await gate?.future;
    if (fail) throw Exception('disque plein');
    lastBody = body;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _SpyRepository repository;
  late NoteDraft draft;

  setUp(() {
    repository = _SpyRepository();
    draft = NoteDraft(repository, debounce: const Duration(hours: 1));
  });

  test('une note neuve restée vide n\'est jamais créée', () async {
    draft.update(title: '   ', body: '\n');
    await draft.flush();

    expect(repository.creates, 0);
    expect(draft.status, SaveStatus.idle);
  });

  test('ne fait rien si le texte n\'a pas changé', () async {
    draft.update(title: '', body: '');
    await draft.flush();

    expect(repository.creates, 0);
  });

  test('crée la note une fois, puis la met à jour', () async {
    draft.update(title: '', body: 'a');
    await draft.flush();
    draft.update(title: '', body: 'ab');
    await draft.flush();

    expect(repository.creates, 1);
    expect(repository.updates, 1);
    expect(repository.lastBody, 'ab');
    expect(draft.id, 7);
    expect(draft.status, SaveStatus.saved);
  });

  test('une frappe pendant la création ne crée pas de doublon', () async {
    repository.gate = Completer();

    draft.update(title: '', body: 'a');
    final saving = draft.flush();
    await pumpEventQueue();
    draft.update(title: '', body: 'ab');
    unawaited(draft.flush());
    repository.gate!.complete();
    await saving;

    expect(repository.creates, 1);
    expect(repository.updates, 1);
    expect(repository.lastBody, 'ab');
  });

  test('enregistre après le délai, sans action de l\'utilisateur', () async {
    final quick = NoteDraft(
      repository,
      debounce: const Duration(milliseconds: 5),
    );

    quick.update(title: '', body: 'texte');
    expect(quick.status, SaveStatus.pending);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(repository.lastBody, 'texte');
    expect(quick.status, SaveStatus.saved);
  });

  test('un échec garde le texte et Réessayer l\'enregistre', () async {
    repository.fail = true;
    draft.update(title: '', body: 'précieux');
    await draft.flush();

    expect(draft.status, SaveStatus.failed);
    expect(draft.body, 'précieux');

    repository.fail = false;
    await draft.flush();

    expect(draft.status, SaveStatus.saved);
    expect(repository.lastBody, 'précieux');
  });

  test('discard annule l\'écriture en attente', () async {
    draft.update(title: '', body: 'à oublier');
    await draft.discard();
    await draft.flush();

    expect(repository.creates, 0);
  });

  test('flush après dispose termine l\'écriture sans erreur', () async {
    final closing = NoteDraft(repository, debounce: const Duration(hours: 1));
    closing.update(title: '', body: 'dernier mot');

    final saving = closing.flush();
    closing.dispose();
    await saving;

    expect(repository.lastBody, 'dernier mot');
  });

  test('fonctionne avec le vrai dépôt SQLite', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final real = NotesRepository(database, DateTime.now);
    final realDraft = NoteDraft(real, moduleId: 'java');

    realDraft.update(title: 'Titre', body: 'Corps');
    await realDraft.flush();

    final note = await real.find(realDraft.id!);
    expect(note?.title, 'Titre');
    expect(note?.moduleId, 'java');
  });
}
