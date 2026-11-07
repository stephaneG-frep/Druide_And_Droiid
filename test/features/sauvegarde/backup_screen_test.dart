import 'dart:convert';

import 'package:drift/native.dart';
import 'package:druide_and_droiid/app/sections.dart';
import 'package:druide_and_droiid/core/persistence/app_database.dart';
import 'package:druide_and_droiid/features/academie/presentation/paths.dart';
import 'package:druide_and_droiid/features/grimoire/domain/grimoire_topics.dart';
import 'package:druide_and_droiid/features/grimoire/presentation/help_button.dart';
import 'package:druide_and_droiid/features/lab/presentation/lab_paths.dart';
import 'package:druide_and_droiid/features/notes/data/notes_repository.dart';
import 'package:druide_and_droiid/features/sauvegarde/data/auto_backup.dart';
import 'package:druide_and_droiid/features/sauvegarde/data/backup_repository.dart';
import 'package:druide_and_droiid/features/sauvegarde/data/file_saver.dart';
import 'package:druide_and_droiid/features/sauvegarde/presentation/backup_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_app.dart';

class FakeSaver implements FileSaver {
  final saved = <String, List<int>>{};

  @override
  Future<String?> save(String fileName, List<int> bytes) async {
    saved[fileName] = bytes;
    return '/tmp/$fileName';
  }
}

class FakeOpener implements FileOpener {
  FakeOpener(this.bytes);

  final List<int>? bytes;

  @override
  Future<List<int>?> open() async => bytes;
}

const tall = Size(420, 2000);

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).first);
  await tester.pumpAndSettle();
}

Future<void> waitToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

List<Override> files(FakeSaver saver, {List<int>? open}) => [
  fileSaverProvider.overrideWithValue(saver),
  fileOpenerProvider.overrideWithValue(FakeOpener(open)),
  autoBackupListProvider.overrideWith((ref) async => []),
];

void main() {
  testWidgets('les paramètres mènent aux sauvegardes', (tester) async {
    final container = await pumpApp(
      tester,
      size: tall,
      extraOverrides: files(FakeSaver()),
    );
    await goTo(tester, container, AppSection.parametres.path);

    await tester.ensureVisible(find.byIcon(Icons.save_outlined));
    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();

    expect(location(container), backupPath);
    expect(find.textContaining('jamais incluses'), findsOneWidget);
  });

  testWidgets('exporter en JSON enregistre une vraie sauvegarde', (
    tester,
  ) async {
    final saver = FakeSaver();
    final container = await pumpApp(
      tester,
      size: tall,
      extraOverrides: files(saver),
    );
    await goTo(tester, container, backupPath);

    await tapText(tester, 'Exporter en JSON');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    final name = saver.saved.keys.single;
    expect(name, endsWith('.json'));
    final json = jsonDecode(utf8.decode(saver.saved[name]!)) as Map;
    expect(json['format'], backupFormat);
    expect(find.textContaining('Enregistré : /tmp/'), findsOneWidget);
    await waitToast(tester);
  });

  testWidgets('restaurer demande confirmation, puis remplace', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    final backup = {
      'format': backupFormat,
      'version': backupVersion,
      'schemaVersion': 3,
      'createdAt': '2026-11-01T10:00:00Z',
      'tables': {
        'notes': [
          {
            'id': 1,
            'title': 'Restaurée',
            'body': '',
            'module_id': null,
            'created_at': 1,
            'updated_at': 1,
          },
        ],
      },
    };
    final saver = FakeSaver();
    final container = await pumpApp(
      tester,
      size: tall,
      database: database,
      extraOverrides: files(saver, open: utf8.encode(jsonEncode(backup))),
    );
    await tester.runAsync(
      () => container
          .read(notesRepositoryProvider)
          .create(title: 'Actuelle', body: ''),
    );
    await goTo(tester, container, backupPath);

    await tapText(tester, 'Restaurer depuis un fichier');
    expect(find.text('Remplacer toutes vos données ?'), findsOneWidget);
    expect(find.textContaining('1 éléments'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    final notes = await tester.runAsync(
      () => database.select(database.notes).get(),
    );
    expect(notes!.single.title, 'Actuelle');
  });

  testWidgets('un fichier qui n\'est pas une sauvegarde est refusé', (
    tester,
  ) async {
    final container = await pumpApp(
      tester,
      size: tall,
      extraOverrides: files(FakeSaver(), open: utf8.encode('{"a":1}')),
    );
    await goTo(tester, container, backupPath);

    await tapText(tester, 'Restaurer depuis un fichier');

    expect(find.textContaining('n\'est pas une sauvegarde'), findsOneWidget);
    expect(find.text('Remplacer toutes vos données ?'), findsNothing);
    await waitToast(tester);
  });

  testWidgets('un module s\'exporte en PDF', (tester) async {
    final saver = FakeSaver();
    final container = await pumpApp(
      tester,
      size: tall,
      extraOverrides: files(saver),
    );
    await goTo(tester, container, modulePath('fondations'));

    await tester.tap(find.byTooltip('Exporter en PDF'));
    for (var i = 0; i < 50 && saver.saved.isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }

    final bytes = saver.saved['module-1-fondations.pdf']!;
    expect(utf8.decode(bytes.take(5).toList()), '%PDF-');
    await tester.pumpAndSettle();
    await waitToast(tester);
  });

  testWidgets('le Grimoire couvre tous les sujets du programme', (
    tester,
  ) async {
    final container = await pumpApp(tester, size: const Size(420, 3000));
    await goTo(tester, container, AppSection.grimoire.path);

    for (final topic in GrimoireTopic.values) {
      await tester.scrollUntilVisible(
        find.text(topic.title),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(topic.title), findsOneWidget);
    }
  });

  testWidgets('l\'aide d\'un écran ouvre la bonne rubrique', (tester) async {
    final container = await pumpApp(tester, size: tall);
    await goTo(tester, container, labEditorPath('kt-null'));

    await tester.tap(find.byTooltip('Aide'));
    await tester.pumpAndSettle();
    expect(find.text(GrimoireTopic.lab.title), findsOneWidget);

    await tester.tap(find.text('Ouvrir le Grimoire'));
    await tester.pumpAndSettle();
    expect(location(container), AppSection.grimoire.path);
    expect(find.text(GrimoireTopic.lab.paragraphs.first), findsOneWidget);
  });

  test('les sujets du Grimoire couvrent la section 12 du programme', () {
    final titles = GrimoireTopic.values.map((topic) => topic.title).join(' ');
    for (final subject in [
      'formation',
      'IA',
      'fournisseurs',
      'exercices',
      'Lab',
      'logs',
      'Exporter',
      'Sauvegarder',
      'Restaurer',
      'outils Linux',
    ]) {
      expect(titles, contains(subject));
    }
    expect(grimoirePath(GrimoireTopic.lab), contains('sujet=lab'));
  });
}
