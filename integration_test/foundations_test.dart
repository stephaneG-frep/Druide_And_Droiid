import 'dart:io';

import 'package:drift/native.dart';
import 'package:druide_and_droiid/app/app.dart';
import 'package:druide_and_droiid/app/sections.dart';
import 'package:druide_and_droiid/core/persistence/app_database.dart';
import 'package:druide_and_droiid/core/security/secret_store.dart';
import 'package:druide_and_droiid/design_system/motion.dart';
import 'package:druide_and_droiid/features/academie/data/course_repository.dart';
import 'package:druide_and_droiid/features/academie/data/favorites_repository.dart';
import 'package:druide_and_droiid/features/notes/data/notes_repository.dart';
import 'package:druide_and_droiid/features/parametres/domain/appearance.dart';
import 'package:druide_and_droiid/features/parametres/presentation/appearance_controller.dart';
import 'package:druide_and_droiid/features/progression/data/progress_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('l\'application démarre et navigue sur la plateforme réelle', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // La boucle de la mascotte empêcherait pumpAndSettle de se terminer.
          initialAppearanceProvider.overrideWithValue(
            const Appearance(
              themeMode: ThemeMode.dark,
              motion: MotionLevel.none,
            ),
          ),
        ],
        child: const DruideApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bienvenue à l\'Académie !'), findsOneWidget);

    await tester.tap(find.text('Plus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppSection.chaudron.label));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(AppBar, AppSection.chaudron.label),
      findsOneWidget,
    );
  });

  test('les cours embarqués se chargent sur la plateforme réelle', () async {
    final repository = CourseRepository(rootBundle);

    final modules = await repository.availableModules();
    expect(modules, isNotEmpty);
    for (final moduleId in modules) {
      final course = await repository.load(moduleId);
      expect(course.lessons, isNotEmpty, reason: moduleId);
    }
  });

  test('SQLite conserve les données après réouverture du fichier', () async {
    final directory = await getTemporaryDirectory();
    final file = File(p.join(directory.path, 'druide_smoke.sqlite'));
    addTearDown(() async {
      if (file.existsSync()) await file.delete();
    });

    final first = AppDatabase(NativeDatabase(file));
    await first.writeMeta('smoke', 'persisté');
    await first.close();

    final second = AppDatabase(NativeDatabase(file));
    expect(await second.readMeta('smoke'), 'persisté');
    await second.close();
  });

  test('notes, progression et favoris survivent à la fermeture', () async {
    final directory = await getTemporaryDirectory();
    final file = File(p.join(directory.path, 'druide_smoke_data.sqlite'));
    addTearDown(() async {
      if (file.existsSync()) await file.delete();
    });

    final first = AppDatabase(NativeDatabase(file));
    final noteId = await NotesRepository(
      first,
      DateTime.now,
    ).create(title: 'Fibres', body: 'Accents : é ī', moduleId: 'kotlin');
    await ProgressRepository(first, DateTime.now).recordQuizAttempt(
      quizId: 'smoke',
      score: 1,
      maxScore: 1,
      passed: true,
      xp: 10,
    );
    await FavoritesRepository(
      first,
      DateTime.now,
    ).setFavorite(FavoriteKind.module, 'kotlin', favorite: true);
    await first.close();

    final second = AppDatabase(NativeDatabase(file));
    final note = await NotesRepository(second, DateTime.now).find(noteId);
    final progress = await ProgressRepository(
      second,
      DateTime.now,
    ).watch().first;
    final favorites = await FavoritesRepository(
      second,
      DateTime.now,
    ).watch(FavoriteKind.module).first;
    await second.close();

    expect(note?.body, 'Accents : é ī');
    expect(progress.xp, 10);
    expect(progress.quizzesPassed, 1);
    expect(favorites, {'kotlin'});
  });

  test('le coffre de la plateforme écrit, relit et efface un secret', () async {
    const store = SecretStore(FlutterSecureStorage());
    const name = 'druide_smoke_secret';

    await store.write(name, 'valeur-de-test');
    expect(await store.read(name), 'valeur-de-test');

    await store.delete(name);
    expect(await store.read(name), isNull);
  });
}
