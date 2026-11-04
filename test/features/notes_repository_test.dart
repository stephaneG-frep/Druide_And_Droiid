import 'package:drift/native.dart';
import 'package:druide_and_droiid/core/persistence/app_database.dart';
import 'package:druide_and_droiid/features/academie/data/favorites_repository.dart';
import 'package:druide_and_droiid/features/notes/data/notes_repository.dart';
import 'package:druide_and_droiid/features/notes/domain/note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DateTime now;
  late NotesRepository notes;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    now = DateTime(2026, 11, 4, 10);
    notes = NotesRepository(database, () => now);
  });
  tearDown(() => database.close());

  test('crée et relit une note avec accents et emoji', () async {
    final id = await notes.create(
      title: 'Coroutines',
      body: 'Le ī de Droiīd 🧙\nDeuxième ligne',
      moduleId: 'kotlin',
    );

    final note = await notes.find(id);
    expect(note?.title, 'Coroutines');
    expect(note?.body, 'Le ī de Droiīd 🧙\nDeuxième ligne');
    expect(note?.moduleId, 'kotlin');
    expect(note?.createdAt, now);
  });

  test('une note absente renvoie null', () async {
    expect(await notes.find(999), isNull);
  });

  test('modifier conserve la création et avance la modification', () async {
    final id = await notes.create(title: 'A', body: '');
    final created = now;
    now = now.add(const Duration(hours: 1));

    await notes.update(id, title: 'B', body: 'texte');

    final note = await notes.find(id);
    expect(note?.title, 'B');
    expect(note?.createdAt, created);
    expect(note?.updatedAt, now);
  });

  test('la liste présente d\'abord la note modifiée en dernier', () async {
    final first = await notes.create(title: 'Première', body: '');
    now = now.add(const Duration(minutes: 1));
    await notes.create(title: 'Seconde', body: '');
    now = now.add(const Duration(minutes: 1));
    await notes.update(first, title: 'Première', body: 'revue');

    final titles = (await notes.watch().first).map((note) => note.title);
    expect(titles, ['Première', 'Seconde']);
  });

  test('filtre les notes d\'un module', () async {
    await notes.create(title: 'Kotlin', body: '', moduleId: 'kotlin');
    await notes.create(title: 'Java', body: '', moduleId: 'java');
    await notes.create(title: 'Libre', body: '');

    final list = await notes.watch(moduleId: 'kotlin').first;
    expect(list.map((note) => note.title), ['Kotlin']);
  });

  test('supprimer retire la note', () async {
    final id = await notes.create(title: 'À jeter', body: '');

    await notes.delete(id);

    expect(await notes.find(id), isNull);
    expect(await notes.watch().first, isEmpty);
  });

  test('un titre vide s\'affiche « Sans titre »', () {
    final note = Note(
      id: 1,
      title: '   ',
      body: '',
      moduleId: null,
      createdAt: now,
      updatedAt: now,
    );

    expect(note.displayTitle, 'Sans titre');
  });

  group('favoris', () {
    late FavoritesRepository favorites;

    setUp(() => favorites = FavoritesRepository(database, () => now));

    Future<Set<String>> current() {
      return favorites.watch(FavoriteKind.module).first;
    }

    test('ajouter puis retirer', () async {
      await favorites.setFavorite(
        FavoriteKind.module,
        'kotlin',
        favorite: true,
      );
      expect(await current(), {'kotlin'});

      await favorites.setFavorite(
        FavoriteKind.module,
        'kotlin',
        favorite: false,
      );
      expect(await current(), isEmpty);
    });

    test('ajouter deux fois ne provoque pas d\'erreur', () async {
      await favorites.setFavorite(
        FavoriteKind.module,
        'kotlin',
        favorite: true,
      );
      await favorites.setFavorite(
        FavoriteKind.module,
        'kotlin',
        favorite: true,
      );

      expect(await current(), {'kotlin'});
    });
  });
}
