import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:druide_and_droiid/core/persistence/app_database.dart';
import 'package:druide_and_droiid/features/academie/data/exercise_repository.dart';
import 'package:druide_and_droiid/features/academie/domain/course.dart';
import 'package:druide_and_droiid/features/academie/domain/module_catalog.dart';
import 'package:druide_and_droiid/features/chaudron/data/bug_repository.dart';
import 'package:druide_and_droiid/features/lab/data/lab_repository.dart';
import 'package:druide_and_droiid/features/maitre/data/conversation_repository.dart';
import 'package:druide_and_droiid/features/maitre/domain/ai_chat.dart';
import 'package:druide_and_droiid/features/maitre/domain/teaching.dart';
import 'package:druide_and_droiid/features/notes/data/notes_repository.dart';
import 'package:druide_and_droiid/features/notes/domain/note.dart';
import 'package:druide_and_droiid/features/progression/data/progress_repository.dart';
import 'package:druide_and_droiid/features/progression/domain/certificates.dart';
import 'package:druide_and_droiid/features/projets/data/project_repository.dart';
import 'package:druide_and_droiid/features/projets/domain/project.dart';
import 'package:druide_and_droiid/features/sauvegarde/data/auto_backup.dart';
import 'package:druide_and_droiid/features/sauvegarde/data/backup_repository.dart';
import 'package:druide_and_droiid/features/sauvegarde/data/document_exports.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_app.dart';

/// Remplit chaque partie de l'application avec des données reconnaissables.
Future<void> fill(AppDatabase database) async {
  DateTime now() => DateTime(2026, 11, 7, 10);
  final progress = ProgressRepository(database, now);
  await database.writeMeta('appearance.theme', 'light');
  await database.writeMeta('ai.active', 'ollama');
  await database.writeMeta('ai.key.anthropic', '1');
  await progress.completeLesson(lessonId: 'l1', moduleId: 'kotlin', xp: 20);
  await progress.recordQuizAttempt(
    quizId: 'lesson:l1',
    score: 3,
    maxScore: 3,
    passed: true,
    xp: 15,
  );
  await ExerciseRepository(database, progress, now).saveResult(
    exerciseId: 'ex1',
    moduleId: 'kotlin',
    text: 'Ma réponse accentuée : été',
    success: true,
  );
  await NotesRepository(database, now).create(title: 'Note', body: 'Corps');
  await database
      .into(database.favorites)
      .insert(
        FavoritesCompanion.insert(
          kind: 'module',
          targetId: 'kotlin',
          createdAt: now(),
        ),
      );
  final conversations = ConversationRepository(database, now);
  final id = await conversations.create(
    title: 'Question',
    providerKind: 'ollama',
    model: 'm',
    mode: TeachingMode.general,
  );
  await conversations.addUserMessage(id, 'Bonjour');
  await conversations.addAssistantMessage(
    id,
    'Salut',
    reason: AiStopReason.complete,
    inputTokens: 3,
    outputTokens: 2,
  );
  final lab = LabRepository(database, now);
  await lab.markSolved('kt-null', 'fun main() {}');
  await lab.addRevision('kt-null', 'ancien', 'Version enregistrée');
  await BugRepository(
    database,
    now,
  ).create(errorText: 'Duplicate class', description: '', code: '');
  final projects = ProjectRepository(database, now);
  await projects.toggleStep('calculatrice', 0);
  await projects.saveFinal('Tests', 12, 'preuve');
  await database
      .into(database.badgeUnlocks)
      .insert(
        BadgeUnlocksCompanion.insert(
          badgeId: 'premiere-lecon',
          unlockedAt: now(),
        ),
      );
}

Future<Map<String, List<Map<String, Object?>>>> dump(
  AppDatabase database,
) async {
  return {
    for (final table in database.allTables)
      table.actualTableName: [
        for (final row
            in await database
                .customSelect('SELECT * FROM "${table.actualTableName}"')
                .get())
          row.data,
      ],
  };
}

void main() {
  late AppDatabase source;
  late AppDatabase target;

  setUp(() {
    source = AppDatabase(NativeDatabase.memory());
    target = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await source.close();
    await target.close();
  });

  BackupRepository repositoryOf(AppDatabase database) =>
      BackupRepository(database, () => DateTime(2026, 11, 7, 12));

  test('chaque table de la base est couverte par le jeu d\'essai', () async {
    await fill(source);
    final tables = await dump(source);
    expect(
      tables.entries.where((entry) => entry.value.isEmpty).map((e) => e.key),
      isEmpty,
    );
  });

  test(
    'sauvegarder puis restaurer redonne exactement les mêmes données',
    () async {
      await fill(source);
      final json = jsonDecode(
        await repositoryOf(source).exportJson(),
      ) as Map<String, Object?>;

      await repositoryOf(target).restore(json);

      final before = await dump(source);
      final after = await dump(target);
      before['app_meta']!.removeWhere(
        (row) => (row['key']! as String).startsWith('ai.key.'),
      );
      expect(after, before);
    },
  );

  test('la présence d\'une clé d\'API n\'est jamais sauvegardée', () async {
    await fill(source);
    final text = await repositoryOf(source).exportJson();

    expect(text, isNot(contains('ai.key.')));
    expect(text, contains('ai.active'));
  });

  test('restaurer remplace les données actuelles', () async {
    await fill(source);
    final json = await repositoryOf(source).export();
    await NotesRepository(
      target,
      DateTime.now,
    ).create(title: 'À remplacer', body: '');

    await repositoryOf(target).restore(json);

    final notes = await target.select(target.notes).get();
    expect(notes.map((note) => note.title), ['Note']);
  });

  test('une sauvegarde invalide ne touche à rien', () async {
    await NotesRepository(
      target,
      DateTime.now,
    ).create(title: 'Gardée', body: '');
    final repository = repositoryOf(target);

    for (final bad in <Map<String, Object?>>[
      {'format': 'autre'},
      {'format': backupFormat, 'version': 99},
      {
        'format': backupFormat,
        'version': backupVersion,
        'schemaVersion': target.schemaVersion + 1,
        'tables': <String, Object?>{},
      },
      {
        'format': backupFormat,
        'version': backupVersion,
        'schemaVersion': 1,
        'tables': {'inconnue': <Object?>[]},
      },
    ]) {
      await expectLater(
        repository.restore(bad),
        throwsA(isA<BackupException>()),
      );
    }
    expect((await target.select(target.notes).get()).single.title, 'Gardée');
  });

  test('une erreur en cours de restauration annule tout', () async {
    await NotesRepository(
      target,
      DateTime.now,
    ).create(title: 'Gardée', body: '');
    final json = {
      'format': backupFormat,
      'version': backupVersion,
      'schemaVersion': target.schemaVersion,
      'tables': {
        'notes': [
          {'title': 'Sans dates', 'body': ''},
        ],
      },
    };

    await expectLater(repositoryOf(target).restore(json), throwsA(anything));
    expect((await target.select(target.notes).get()).single.title, 'Gardée');
  });

  test('une sauvegarde d\'une version plus ancienne se restaure', () async {
    final json = {
      'format': backupFormat,
      'version': backupVersion,
      'schemaVersion': 3,
      'createdAt': '2026-11-04T10:00:00Z',
      'tables': {
        'app_meta': [
          {'key': 'appearance.theme', 'value': 'dark'},
        ],
        'lesson_progress': [
          {'lesson_id': 'l1', 'module_id': 'kotlin', 'completed_at': 1},
        ],
      },
    };

    final summary = await repositoryOf(target).restore(json);

    expect(summary.schemaVersion, 3);
    expect(await target.readMeta('appearance.theme'), 'dark');
    expect(await target.select(target.lessonProgress).get(), hasLength(1));
  });

  test('l\'archive ZIP contient la sauvegarde et se restaure', () async {
    await fill(source);
    final bytes = await repositoryOf(source)
        .exportZip(extraFiles: {'notes.md': '# Note'});

    final archive = ZipDecoder().decodeBytes(bytes);
    expect(archive.findFile(backupJsonName), isNotNull);
    expect(archive.findFile('LISEZMOI.txt'), isNotNull);
    expect(archive.findFile('notes.md'), isNotNull);

    final restore = repositoryOf(target);
    await restore.restore(restore.decode(bytes));
    expect(await target.select(target.notes).get(), hasLength(1));
  });

  test('un fichier quelconque est refusé', () {
    final repository = repositoryOf(target);
    expect(
      () => repository.decode(utf8.encode('pas du json')),
      throwsA(isA<BackupException>()),
    );
    expect(
      () => repository.decode([0x50, 0x4b, 0x03, 0x04, 1, 2, 3]),
      throwsA(isA<BackupException>()),
    );
  });

  group('copies de sécurité', () {
    late Directory directory;
    var clock = DateTime(2026, 11, 7, 9);

    setUp(() {
      directory = Directory.systemTemp.createTempSync('druide_auto');
      clock = DateTime(2026, 11, 7, 9);
    });

    tearDown(() => directory.deleteSync(recursive: true));

    AutoBackups autos() => AutoBackups(
      BackupRepository(source, () => clock),
      () async => directory,
      () => clock,
    );

    test('une seule copie par jour', () async {
      expect(await autos().runIfDue(), isNotNull);
      expect(await autos().runIfDue(), isNull);
    });

    test('ne garde que les plus récentes', () async {
      for (var i = 0; i < keptAutoBackups + 3; i++) {
        clock = clock.add(const Duration(seconds: 1));
        final file = await autos().create();
        await file.setLastModified(clock);
      }
      expect(await autos().list(), hasLength(keptAutoBackups));
    });

    test('la copie avant restauration est mise à part', () async {
      await autos().create(beforeRestore: true);
      final list = await autos().list();
      expect(list.single.beforeRestore, isTrue);
      expect(await autos().runIfDue(), isNotNull);
    });
  });

  test('l\'application rouvre ses données après une fermeture', () async {
    final folder = Directory.systemTemp.createTempSync('druide_reopen');
    addTearDown(() => folder.deleteSync(recursive: true));
    final file = File('${folder.path}/base.sqlite');

    final first = AppDatabase(NativeDatabase(file));
    await fill(first);
    final before = await dump(first);
    await first.close();

    final second = AppDatabase(NativeDatabase(file));
    expect(await dump(second), before);
    await second.close();
  });

  group('PDF', () {
    final pdftotext =
        Platform.isLinux && File('/usr/bin/pdftotext').existsSync();

    Future<String> textOf(List<int> bytes) async {
      final folder = Directory.systemTemp.createTempSync('druide_pdf');
      addTearDown(() => folder.deleteSync(recursive: true));
      final pdf = File('${folder.path}/doc.pdf')..writeAsBytesSync(bytes);
      final result = await Process.run('pdftotext', [pdf.path, '-']);
      return result.stdout as String;
    }

    PdfExporter exporter() => PdfExporter(DiskAssetBundle());

    test('le PDF d\'un vrai module garde ses accents et son code', () async {
      final json = jsonDecode(
        File('assets/courses/kotlin.json').readAsStringSync(),
      ) as Map<String, Object?>;
      final course = Course.fromJson(json);
      final bytes = await exporter().course(moduleById('kotlin')!, course);

      expect(utf8.decode(bytes.take(5).toList()), '%PDF-');
      if (!pdftotext) return;
      final text = await textOf(bytes);
      expect(text, contains(course.lessons.first.title));
      expect(text, contains('Corrigés des exercices'));
      expect(text, contains('println'));
    }, skip: false);

    test('notes, projet et certificat se lisent', () async {
      final notes = await exporter().notes([
        Note(
          id: 1,
          title: 'Été à Paris',
          body: 'Contenu « entre guillemets »',
          moduleId: null,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ]);
      final project = parseProjects(
        jsonDecode(File('assets/projects/projects.json').readAsStringSync())
            as Map<String, Object?>,
      ).first;
      final fiche = await exporter().project(
        project,
        const ProjectState(doneSteps: {0}, proof: 'https://exemple.com'),
      );
      final certificate = await exporter().certificate(
        Certificate(
          id: 'kotlin',
          title: 'Kotlin',
          reason: 'Raison',
          date: DateTime(2026, 11, 7),
        ),
        'Ana',
      );

      for (final bytes in [notes, fiche, certificate]) {
        expect(utf8.decode(bytes.take(5).toList()), '%PDF-');
      }
      if (!pdftotext) return;
      expect(await textOf(notes), contains('Été à Paris'));
      expect(await textOf(fiche), contains(project.title));
      final text = await textOf(certificate);
      expect(text, contains('Ana'));
      expect(text, contains('certification'));
    });
  });

  test('le Markdown des exercices reprend l\'énoncé et la réponse', () {
    const exercise = Exercise(
      id: 'ex1',
      kind: ExerciseKind.self,
      prompt: 'Écrivez **un** programme',
      solution: 's',
      accepted: [],
      solutionLanguage: null,
    );
    final text = exercisesMarkdown(
      exercises: {'ex1': exercise},
      answers: {'ex1': 'ma réponse'},
      labCode: {'kt-null': 'fun main() {}'},
    );
    expect(text, contains('### Écrivez un programme'));
    expect(text, contains('ma réponse'));
    expect(text, contains('fun main() {}'));
  });

  test('le chargement des polices passe par le bundle', () async {
    final data = await DiskAssetBundle().load(
      'assets/fonts/AtkinsonHyperlegible-Regular.ttf',
    );
    expect(data, isA<ByteData>());
  });
}
