import 'package:drift/native.dart';
import 'package:druide_and_droiid/app/sections.dart';
import 'package:druide_and_droiid/core/persistence/app_database.dart';
import 'package:druide_and_droiid/features/academie/domain/module_catalog.dart';
import 'package:druide_and_droiid/features/notes/data/notes_repository.dart';
import 'package:druide_and_droiid/features/notes/presentation/notes_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

/// Laisse passer le délai de la sauvegarde automatique.
Future<void> waitForAutosave(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

/// Les flux Drift ont besoin du temps réel, absent de `testWidgets`.
Future<List<String>> storedTitles(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final notes = await tester.runAsync(
    () => container.read(notesRepositoryProvider).watch().first,
  );
  return notes!.map((note) => note.title).toList();
}

Future<void> openNotes(WidgetTester tester, ProviderContainer container) {
  return goTo(tester, container, AppSection.notes.path);
}

Finder titleField() => find.widgetWithText(TextField, 'Titre');

void main() {
  testWidgets('sans note, la page l\'indique sans se dire IA', (tester) async {
    final container = await pumpApp(tester);
    await openNotes(tester, container);

    expect(find.textContaining('encore vierge'), findsOneWidget);
    expect(find.text('Message préenregistré'), findsOneWidget);
  });

  testWidgets('écrire une note l\'enregistre sans action', (tester) async {
    final container = await pumpApp(tester);
    await openNotes(tester, container);

    await tester.tap(find.text('Nouvelle note'));
    await tester.pumpAndSettle();
    await tester.enterText(titleField(), 'Gradle');
    await waitForAutosave(tester);

    expect(find.text('Enregistré'), findsOneWidget);
    expect(await storedTitles(tester, container), ['Gradle']);
  });

  testWidgets('quitter aussitôt après la frappe ne perd rien', (tester) async {
    final container = await pumpApp(tester);
    await openNotes(tester, container);

    await tester.tap(find.text('Nouvelle note'));
    await tester.pumpAndSettle();
    await tester.enterText(titleField(), 'Écrit à la dernière seconde');
    await tester.pump();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(await storedTitles(tester, container), [
      'Écrit à la dernière seconde',
    ]);
    expect(find.text('Écrit à la dernière seconde'), findsOneWidget);
  });

  testWidgets('passer en arrière-plan enregistre immédiatement', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    await openNotes(tester, container);

    await tester.tap(find.text('Nouvelle note'));
    await tester.pumpAndSettle();
    await tester.enterText(titleField(), 'Interrompue');
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );

    expect(await storedTitles(tester, container), ['Interrompue']);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  });

  testWidgets('une note neuve abandonnée n\'est pas créée', (tester) async {
    final container = await pumpApp(tester);
    await openNotes(tester, container);

    await tester.tap(find.text('Nouvelle note'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(await storedTitles(tester, container), isEmpty);
  });

  testWidgets('rouvrir une note présente son contenu et le modifie', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    final repository = container.read(notesRepositoryProvider);
    await repository.create(title: 'Avant', body: 'Corps');
    await openNotes(tester, container);

    await tester.tap(find.text('Avant'));
    await tester.pumpAndSettle();
    expect(find.text('Corps'), findsOneWidget);

    await tester.enterText(titleField(), 'Après');
    await waitForAutosave(tester);

    expect(await storedTitles(tester, container), ['Après']);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  });

  group('suppression', () {
    Future<ProviderContainer> openExistingNote(WidgetTester tester) async {
      final container = await pumpApp(tester);
      await container
          .read(notesRepositoryProvider)
          .create(title: 'Fragile', body: '');
      await openNotes(tester, container);
      await tester.tap(find.text('Fragile'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Supprimer la note'));
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('annuler conserve la note', (tester) async {
      final container = await openExistingNote(tester);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(await storedTitles(tester, container), ['Fragile']);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    });

    testWidgets('confirmer efface la note et revient à la liste', (
      tester,
    ) async {
      final container = await openExistingNote(tester);

      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      expect(await storedTitles(tester, container), isEmpty);
      expect(location(container), AppSection.notes.path);
    });
  });

  testWidgets('une note inconnue affiche un message clair', (tester) async {
    final container = await pumpApp(tester);

    await goTo(tester, container, notePath(404));

    expect(find.text('Cette note est introuvable.'), findsOneWidget);
    expect(find.byTooltip('Supprimer la note'), findsNothing);
  });

  group('depuis un module', () {
    final module = academyModules[1];
    final modulePath = '${AppSection.academie.path}/${module.id}';

    testWidgets('une note créée est rattachée au module et y revient', (
      tester,
    ) async {
      final container = await pumpApp(tester, size: const Size(390, 2400));
      await goTo(tester, container, modulePath);

      await tester.tap(find.text('Ajouter une note'));
      await tester.pumpAndSettle();
      await tester.enterText(titleField(), 'Sur Kotlin');
      await tester.pump();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(location(container), modulePath);
      expect(find.text('Sur Kotlin'), findsOneWidget);
      final notes = await tester.runAsync(
        () => container
            .read(notesRepositoryProvider)
            .watch(moduleId: module.id)
            .first,
      );
      expect(notes!.single.title, 'Sur Kotlin');
    });

    testWidgets('l\'étoile ajoute le module aux favoris de l\'Académie', (
      tester,
    ) async {
      final container = await pumpApp(tester);
      await goTo(tester, container, modulePath);

      await tester.tap(find.byTooltip('Ajouter aux favoris'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Retirer des favoris'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Vos favoris'), findsOneWidget);
      expect(find.text(module.title), findsWidgets);
    });
  });

  testWidgets('les données survivent à un redémarrage complet', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    // Le conteneur simule un lancement ; la base partagée, le fichier sur disque.
    final first = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    await first
        .read(notesRepositoryProvider)
        .create(title: 'Durable', body: '');
    first.dispose();

    final second = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(second.dispose);
    expect(await storedTitles(tester, second), ['Durable']);
  });
}
