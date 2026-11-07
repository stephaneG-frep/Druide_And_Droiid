import 'dart:io';

import 'package:drift/native.dart';
import 'package:druide_and_droiid/core/persistence/app_database.dart';
import 'package:druide_and_droiid/features/notes/data/notes_repository.dart';
import 'package:druide_and_droiid/features/notes/domain/note.dart';
import 'package:druide_and_droiid/features/sauvegarde/data/auto_backup.dart';
import 'package:druide_and_droiid/features/sauvegarde/data/backup_repository.dart';
import 'package:druide_and_droiid/features/sauvegarde/data/document_exports.dart';
import 'package:druide_and_droiid/features/sauvegarde/data/file_saver.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

/// Système de fichiers, dossiers et polices réels, depuis l'application Linux.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('une sauvegarde écrite sur disque se restaure ailleurs', () async {
    final source = AppDatabase(NativeDatabase.memory());
    final target = AppDatabase(NativeDatabase.memory());
    addTearDown(source.close);
    addTearDown(target.close);
    await NotesRepository(
      source,
      DateTime.now,
    ).create(title: 'Été', body: 'Contenu');

    final bytes = await BackupRepository(source, DateTime.now).exportZip();
    final path = await saveInDownloads('essai-sauvegarde.zip', bytes);
    addTearDown(() => File(path).delete());

    final restore = BackupRepository(target, DateTime.now);
    await restore.restore(restore.decode(await File(path).readAsBytes()));
    final notes = await target.select(target.notes).get();
    expect(notes.single.title, 'Été');
  });

  test('les copies de sécurité vivent dans le dossier privé', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final autos = AutoBackups(
      BackupRepository(database, DateTime.now),
      getApplicationSupportDirectory,
      DateTime.now,
    );

    final file = await autos.create();
    addTearDown(() => file.delete());
    final support = await getApplicationSupportDirectory();

    expect(file.path, startsWith(support.path));
    expect(await file.length(), greaterThan(0));
  });

  test('un PDF de notes s\'écrit sur disque', () async {
    final bytes = await PdfExporter(rootBundle).notes([
      Note(
        id: 1,
        title: 'Note réelle',
        body: 'Accents : àéèêç',
        moduleId: null,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ]);
    final path = await saveInDownloads('essai-notes.pdf', bytes);
    addTearDown(() => File(path).delete());

    expect(await File(path).length(), greaterThan(1000));
    final text = await Process.run('pdftotext', [path, '-']);
    expect(text.stdout as String, contains('Accents : àéèêç'));
  });
}
