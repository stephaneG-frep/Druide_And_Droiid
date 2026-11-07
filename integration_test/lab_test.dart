import 'dart:convert';
import 'dart:io';

import 'package:druide_and_droiid/design_system/code_highlighter.dart';
import 'package:druide_and_droiid/features/lab/data/code_runner.dart';
import 'package:druide_and_droiid/features/sauvegarde/data/file_saver.dart';
import 'package:druide_and_droiid/features/lab/data/tool_detector.dart';
import 'package:druide_and_droiid/features/lab/domain/lab_checks.dart';
import 'package:druide_and_droiid/features/lab/domain/lab_exercise.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

/// Compilateurs et système de fichiers réels, depuis l'application Linux.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<List<LabExercise>> exercises() async {
    final source = await rootBundle.loadString('assets/lab/exercises.json');
    return parseExercises(jsonDecode(source) as Map<String, Object?>);
  }

  test('chaque langage exécutable réussit un exercice', () async {
    final runner = LocalCodeRunner(ToolDetector.system().detect());
    final all = await exercises();

    for (final language in [
      CodeLanguage.kotlin,
      CodeLanguage.java,
      CodeLanguage.dart,
    ]) {
      final exercise = all.firstWhere((item) => item.language == language);
      final good = await runner.run(exercise, exercise.solution!);
      expect(good.succeeded, isTrue, reason: '$language ${good.errors}');
      expect(outputMatches(good.output, exercise.expectedOutput!), isTrue);

      final bad = await runner.run(exercise, exercise.starter);
      expect(outputMatches(bad.output, exercise.expectedOutput!), isFalse);
    }
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('une erreur Kotlin revient avec le message du compilateur', () async {
    final runner = LocalCodeRunner(ToolDetector.system().detect());
    final sheet = LabExercise.free(CodeLanguage.kotlin);

    final result = await runner.run(sheet, 'fun main() { val a: Int = "x" }');

    expect(result.compileFailed, isTrue);
    expect(result.errors, contains('Main.kt'));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('l\'export de repli écrit un vrai fichier sans écraser', () async {
    final name = 'essai-${DateTime.now().microsecondsSinceEpoch}.kt';

    final first = await saveInDownloads(
      name,
      utf8.encode('fun main() {} // été'),
    );
    final second = await saveInDownloads(name, utf8.encode('deuxième'));
    expect(first, isNot(second));

    final directory = await getDownloadsDirectory();
    expect(first, startsWith(directory!.path));
    for (final path in [first, second]) {
      addTearDown(() => File(path).delete());
    }
    expect(await File(first).readAsString(), 'fun main() {} // été');
  });
}
