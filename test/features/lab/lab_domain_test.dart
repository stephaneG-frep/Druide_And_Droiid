import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:druide_and_droiid/core/persistence/app_database.dart';
import 'package:druide_and_droiid/design_system/code_highlighter.dart';
import 'package:druide_and_droiid/features/lab/data/lab_repository.dart';
import 'package:druide_and_droiid/features/lab/data/tool_detector.dart';
import 'package:druide_and_droiid/features/lab/domain/lab_checks.dart';
import 'package:druide_and_droiid/features/lab/domain/lab_exercise.dart';
import 'package:druide_and_droiid/features/lab/domain/lab_tools.dart';
import 'package:druide_and_droiid/features/lab/domain/line_diff.dart';
import 'package:flutter_test/flutter_test.dart';

List<LabExercise> realExercises() => parseExercises(
  jsonDecode(File('assets/lab/exercises.json').readAsStringSync())
      as Map<String, Object?>,
);

void main() {
  group('exercices', () {
    test(
      'couvrent Kotlin, Java, Dart et XML, avec des identifiants uniques',
      () {
        final exercises = realExercises();
        expect(exercises.map((e) => e.id).toSet().length, exercises.length);
        for (final language in labLanguages) {
          expect(
            exercises.where((exercise) => exercise.language == language).length,
            greaterThanOrEqualTo(4),
            reason: language.name,
          );
        }
      },
    );

    test('chacun a un moyen réel de vérifier la réussite', () {
      for (final exercise in realExercises()) {
        expect(exercise.solution, isNotEmpty);
        if (exercise.language == CodeLanguage.xml) {
          expect(exercise.required, isNotEmpty, reason: exercise.id);
          final check = checkXml(exercise.solution!, exercise.required);
          expect(check.complete, isTrue, reason: exercise.id);
          expect(
            checkXml(exercise.starter, exercise.required).complete,
            isFalse,
            reason: exercise.id,
          );
        } else {
          expect(exercise.expectedOutput, isNotEmpty, reason: exercise.id);
        }
      }
    });

    test('une feuille libre n\'a pas de corrigé', () {
      final sheet = LabExercise.free(CodeLanguage.java);
      expect(sheet.isFree, isTrue);
      expect(sheet.fileName, 'Main.java');
    });
  });

  group('vérifications', () {
    test('ignore les espaces de fin', () {
      expect(outputMatches('a  \nb\n\n', 'a\nb'), isTrue);
      expect(outputMatches('a\nc', 'a\nb'), isFalse);
    });

    test('un XML cassé donne une erreur lisible', () {
      final check = checkXml('<a><b></a>', const []);
      expect(check.wellFormed, isFalse);
      expect(check.error, isNotEmpty);
    });

    test('signale un élément manquant', () {
      final check = checkXml('<a />', const ['<b']);
      expect(check.wellFormed, isTrue);
      expect(check.missing, ['<b']);
    });
  });

  group('comparaison', () {
    test('repère ajouts et suppressions', () {
      final lines = diffLines('a\nb\nc', 'a\nx\nc\nd');
      expect(lines.map((line) => line.kind), [
        DiffKind.same,
        DiffKind.removed,
        DiffKind.added,
        DiffKind.same,
        DiffKind.added,
      ]);
    });

    test('deux textes identiques ne diffèrent pas', () {
      expect(
        diffLines('a\nb', 'a\nb').every((line) => line.kind == DiffKind.same),
        isTrue,
      );
    });

    test('un très long texte ne bloque pas', () {
      final big = List.filled(maxDiffLines + 1, 'x').join('\n');
      expect(diffLines(big, 'y').length, maxDiffLines + 2);
    });
  });

  test('la coloration conserve exactement le texte de l\'éditeur', () {
    for (final exercise in realExercises()) {
      for (final code in [exercise.starter, exercise.solution!, '"non fermé']) {
        final tokens = highlightCode(code, exercise.language);
        expect(tokens.map((token) => token.text).join(), code);
      }
    }
  });

  group('détection des outils', () {
    LabToolchain detect(Set<String> present, Map<String, String> environment) {
      return ToolDetector(
        environment: {'HOME': '/h', ...environment},
        exists: present.contains,
      ).detect();
    }

    test('trouve les outils dans le PATH', () {
      final tools = detect({'/u/bin/adb', '/u/bin/gradle'}, {'PATH': '/u/bin'});
      expect(tools.path(LabTool.adb), '/u/bin/adb');
      expect(tools.path(LabTool.gradle), '/u/bin/gradle');
      expect(tools.has(LabTool.java), isFalse);
    });

    test('trouve Android Studio et son JDK sans PATH', () {
      final tools = detect({
        '/opt/android-studio/bin/studio.sh',
        '/opt/android-studio/jbr',
        '/opt/android-studio/jbr/bin/java',
        '/opt/android-studio/plugins/Kotlin/kotlinc/bin/kotlinc',
      }, const {});
      expect(tools.has(LabTool.androidStudio), isTrue);
      expect(tools.javaHome, '/opt/android-studio/jbr');
      expect(tools.has(LabTool.kotlinc), isTrue);
    });

    test('préfère le SDK déclaré', () {
      final tools = detect(
        {
          '/sdk',
          '/sdk/platform-tools/adb',
          '/sdk/emulator/emulator',
          '/h/Android/Sdk',
        },
        {'ANDROID_HOME': '/sdk'},
      );
      expect(tools.sdkHome, '/sdk');
      expect(tools.path(LabTool.emulator), '/sdk/emulator/emulator');
    });

    test('rien de présent : tout reste à installer', () {
      final tools = detect(const {}, const {});
      expect(tools.paths, isEmpty);
      for (final tool in LabTool.values) {
        expect(tool.install, isNotEmpty);
        expect(tool.command, isNotEmpty);
      }
    });
  });

  test('ne retient que de vrais noms d\'appareils virtuels', () {
    final avds = parseAvds(
      'INFO | Storing crashdata in: /tmp\nPixel_9\nmedium_phone\n; rm -rf /\n',
    );
    expect(avds, ['Pixel_9', 'medium_phone']);
  });

  group('dépôt', () {
    late AppDatabase database;
    late LabRepository repository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repository = LabRepository(database, DateTime.now);
    });

    tearDown(() => database.close());

    test('enregistre le brouillon et sa réussite', () async {
      await repository.saveDraft('a', 'un');
      await repository.saveDraft('a', 'deux');
      expect((await repository.draft('a'))!.code, 'deux');
      expect((await repository.draft('a'))!.solved, isFalse);

      await repository.markSolved('a', 'trois');
      final draft = await repository.draft('a');
      expect(draft!.solved, isTrue);
      expect(draft.code, 'trois');
    });

    test('une version identique n\'est pas dupliquée', () async {
      await repository.addRevision('a', 'code', 'Un');
      await repository.addRevision('a', 'code', 'Deux');
      expect(await repository.watchRevisions('a').first, hasLength(1));
    });

    test('garde les versions récentes, par exercice', () async {
      for (var i = 0; i < maxRevisions + 5; i++) {
        await repository.addRevision('a', 'code $i', 'Version');
      }
      await repository.addRevision('b', 'autre', 'Version');

      final revisions = await repository.watchRevisions('a').first;
      expect(revisions, hasLength(maxRevisions));
      expect(revisions.first.code, 'code ${maxRevisions + 4}');
      expect(await repository.watchRevisions('b').first, hasLength(1));
    });
  });
}
