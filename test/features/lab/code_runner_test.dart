import 'dart:io';

import 'package:druide_and_droiid/design_system/code_highlighter.dart';
import 'package:druide_and_droiid/features/lab/data/code_runner.dart';
import 'package:druide_and_droiid/features/lab/data/tool_commands.dart';
import 'package:druide_and_droiid/features/lab/data/tool_detector.dart';
import 'package:druide_and_droiid/features/lab/domain/lab_exercise.dart';
import 'package:druide_and_droiid/features/lab/domain/lab_tools.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lance le vrai Dart de la machine : ces tests prouvent les limites réelles.
void main() {
  final toolchain = ToolDetector.system().detect();
  final hasDart = toolchain.has(LabTool.dart);
  final sheet = LabExercise.free(CodeLanguage.dart);

  LocalCodeRunner runner({Duration limit = const Duration(seconds: 20)}) =>
      LocalCodeRunner(toolchain, combinedLimit: limit);

  group('exécution réelle', skip: hasDart ? null : 'Dart introuvable', () {
    test('renvoie la sortie du programme', () async {
      final result = await runner().run(sheet, "void main() { print('Été'); }");

      expect(result.succeeded, isTrue);
      expect(result.output.trim(), 'Été');
    });

    test('une erreur de compilation reste visible', () async {
      final result = await runner().run(sheet, 'void main() { print( }');

      expect(result.succeeded, isFalse);
      expect(result.errors, isNotEmpty);
    });

    test('une boucle sans fin est arrêtée', () async {
      final result = await runner(limit: const Duration(seconds: 3))
          .run(sheet, 'void main() { while (true) {} }');

      expect(result.timedOut, isTrue);
      expect(result.succeeded, isFalse);
    });

    test('une sortie sans fin est coupée', () async {
      final result = await runner().run(
        sheet,
        "void main() { while (true) { print('x' * 1000); } }",
      );

      expect(result.truncated, isTrue);
      expect(result.output.length, lessThanOrEqualTo(maxOutputBytes));
    });

    test('l\'utilisateur peut arrêter le programme', () async {
      final cancel = RunCancel();
      final running = runner(limit: const Duration(seconds: 15))
          .run(sheet, 'void main() { while (true) {} }', cancel: cancel);
      await Future<void>.delayed(const Duration(seconds: 1));
      cancel.cancel();

      final result = await running;
      expect(result.cancelled, isTrue);
    });

    test('le code ne reçoit pas l\'environnement du parent', () async {
      final result = await runner().run(sheet, '''
import 'dart:io';
void main() { print(Platform.environment.keys.join(',')); }
''');
      final keys = result.output.trim().split(',').toSet();

      expect(keys, contains('PATH'));
      expect(
        keys.intersection(
          Platform.environment.keys.toSet()
            ..remove('PATH')
            ..remove('PWD')
            ..remove('HOME')
            ..remove('LANG')
            ..remove('JAVA_HOME'),
        ),
        isEmpty,
      );
    });

    test('le dossier de travail disparaît après l\'exécution', () async {
      final result = await runner().run(sheet, '''
import 'dart:io';
void main() { print(Directory.current.path); }
''');

      expect(Directory(result.output.trim()).existsSync(), isFalse);
    });
  });

  test('un outil manquant est annoncé, sans rien lancer', () async {
    final result = await const LocalCodeRunner(LabToolchain())
        .run(sheet, 'void main() {}');

    expect(result.unavailable, contains('Dart'));
  });

  test('un nom d\'appareil suspect est refusé', () {
    const commands = LocalToolCommands(
      LabToolchain(paths: {LabTool.emulator: '/bin/true'}),
    );
    expect(() => commands.startEmulator('a; rm -rf /'), throwsArgumentError);
  });

  test('une commande prévue passe sans shell', () async {
    const commands = LocalToolCommands(
      LabToolchain(paths: {LabTool.adb: '/bin/echo'}),
    );
    final result = await commands.run(LabCommand.adbDevices);

    expect(result.output, 'devices -l');
    expect(result.failed, isFalse);
  });

  test('une commande dont l\'outil manque échoue proprement', () async {
    const commands = LocalToolCommands(LabToolchain());
    final result = await commands.run(LabCommand.adbVersion);

    expect(result.failed, isTrue);
  });
}
