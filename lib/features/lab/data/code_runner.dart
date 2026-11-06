import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../design_system/code_highlighter.dart';
import '../domain/lab_exercise.dart';
import '../domain/lab_tools.dart';
import 'tool_detector.dart';

const maxOutputBytes = 64 * 1024;
const compileTimeout = Duration(seconds: 120);
const runTimeout = Duration(seconds: 10);

/// Java et Dart compilent et exécutent d'un seul geste.
const combinedTimeout = Duration(seconds: 30);

class RunResult {
  const RunResult({
    this.output = '',
    this.errors = '',
    this.exitCode,
    this.compileFailed = false,
    this.timedOut = false,
    this.truncated = false,
    this.cancelled = false,
    this.unavailable,
  });

  final String output;
  final String errors;
  final int? exitCode;
  final bool compileFailed;
  final bool timedOut;
  final bool truncated;
  final bool cancelled;

  /// Pourquoi rien n'a été lancé.
  final String? unavailable;

  bool get succeeded => exitCode == 0 && !timedOut && !truncated && !cancelled;
}

class RunCancel {
  Process? _process;
  bool cancelled = false;

  void cancel() {
    cancelled = true;
    _process?.kill(ProcessSignal.sigkill);
  }
}

abstract interface class CodeRunner {
  Future<RunResult> run(
    LabExercise exercise,
    String code, {
    RunCancel? cancel,
    void Function(String step)? onStep,
  });
}

/// Lance le code avec les vrais outils de la machine. Ce n'est pas un bac à
/// sable : le code garde les droits de l'utilisateur. Les limites réduisent les
/// accidents (boucle sans fin, sortie sans fin, fichier énorme, variables
/// d'environnement secrètes), pas un code malveillant.
class LocalCodeRunner implements CodeRunner {
  const LocalCodeRunner(
    this.toolchain, {
    this.buildLimit = compileTimeout,
    this.runLimit = runTimeout,
    this.combinedLimit = combinedTimeout,
  });

  final LabToolchain toolchain;
  final Duration buildLimit;
  final Duration runLimit;
  final Duration combinedLimit;

  @override
  Future<RunResult> run(
    LabExercise exercise,
    String code, {
    RunCancel? cancel,
    void Function(String step)? onStep,
  }) async {
    final missing = _missingTool(exercise.language);
    if (missing != null) {
      return RunResult(unavailable: '${missing.label} est introuvable.');
    }

    final folder = await Directory.systemTemp.createTemp('druide_lab_');
    try {
      await File('${folder.path}/${exercise.fileName}').writeAsString(code);
      return switch (exercise.language) {
        CodeLanguage.kotlin => await _kotlin(folder, cancel, onStep),
        CodeLanguage.java => await _java(folder, cancel, onStep),
        CodeLanguage.dart => await _dart(folder, cancel, onStep),
        _ => const RunResult(unavailable: 'Ce langage ne s\'exécute pas.'),
      };
    } finally {
      await folder.delete(recursive: true);
    }
  }

  LabTool? _missingTool(CodeLanguage language) {
    final needed = switch (language) {
      CodeLanguage.kotlin => [LabTool.java, LabTool.kotlinc],
      CodeLanguage.java => [LabTool.java],
      CodeLanguage.dart => [LabTool.dart],
      _ => <LabTool>[],
    };
    return needed.where((tool) => !toolchain.has(tool)).firstOrNull;
  }

  Future<RunResult> _kotlin(
    Directory folder,
    RunCancel? cancel,
    void Function(String step)? onStep,
  ) async {
    onStep?.call('Compilation Kotlin, souvent une quinzaine de secondes…');
    final build = await _execute(
      toolchain.path(LabTool.kotlinc)!,
      ['Main.kt', '-include-runtime', '-d', 'main.jar'],
      folder,
      buildLimit,
      cancel,
    );
    if (!build.succeeded) return _compileFailure(build);
    onStep?.call('Exécution…');
    return _execute(
      toolchain.path(LabTool.java)!,
      ['-jar', 'main.jar'],
      folder,
      runLimit,
      cancel,
    );
  }

  Future<RunResult> _java(
    Directory folder,
    RunCancel? cancel,
    void Function(String step)? onStep,
  ) {
    onStep?.call('Compilation et exécution…');
    return _execute(
      toolchain.path(LabTool.java)!,
      ['Main.java'],
      folder,
      combinedLimit,
      cancel,
    );
  }

  Future<RunResult> _dart(
    Directory folder,
    RunCancel? cancel,
    void Function(String step)? onStep,
  ) {
    onStep?.call('Exécution…');
    return _execute(
      toolchain.path(LabTool.dart)!,
      ['main.dart'],
      folder,
      combinedLimit,
      cancel,
    );
  }

  RunResult _compileFailure(RunResult build) => RunResult(
    output: build.output,
    errors: build.errors,
    exitCode: build.exitCode,
    compileFailed: !build.timedOut && !build.cancelled,
    timedOut: build.timedOut,
    truncated: build.truncated,
    cancelled: build.cancelled,
  );

  Future<RunResult> _execute(
    String executable,
    List<String> arguments,
    Directory folder,
    Duration timeout,
    RunCancel? cancel,
  ) async {
    if (cancel?.cancelled ?? false) return const RunResult(cancelled: true);

    // Un environnement minimal : les variables du parent, dont d'éventuelles
    // clés, ne sont pas transmises au code.
    final process = await Process.start(
      '/bin/sh',
      ['-c', 'ulimit -f 40960; exec "\$@"', 'sh', executable, ...arguments],
      workingDirectory: folder.path,
      includeParentEnvironment: false,
      environment: {
        'PATH': '/usr/bin:/bin',
        'HOME': folder.path,
        'LANG': 'C.UTF-8',
        if (toolchain.javaHome != null) 'JAVA_HOME': toolchain.javaHome!,
        'JAVA_TOOL_OPTIONS': '-Dfile.encoding=UTF-8',
      },
    );
    cancel?._process = process;
    unawaited(process.stdin.close());

    var timedOut = false;
    var truncated = false;
    final timer = Timer(timeout, () {
      timedOut = true;
      process.kill(ProcessSignal.sigkill);
    });

    var received = 0;
    Future<String> read(Stream<List<int>> stream) async {
      final bytes = <int>[];
      await for (final chunk in stream) {
        received += chunk.length;
        if (received > maxOutputBytes) {
          truncated = true;
          process.kill(ProcessSignal.sigkill);
          continue;
        }
        bytes.addAll(chunk);
      }
      return utf8.decode(bytes, allowMalformed: true);
    }

    final output = read(process.stdout);
    final errors = read(process.stderr);
    final code = await process.exitCode;
    timer.cancel();

    return RunResult(
      output: await output,
      errors: (await errors)
          .split('\n')
          .where((line) => !line.startsWith('Picked up JAVA_TOOL_OPTIONS'))
          .join('\n')
          .trimRight(),
      exitCode: code,
      timedOut: timedOut,
      truncated: truncated,
      cancelled: cancel?.cancelled ?? false,
    );
  }
}
