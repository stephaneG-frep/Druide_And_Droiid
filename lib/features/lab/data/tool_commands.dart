import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../domain/lab_tools.dart';
import 'tool_detector.dart';

const commandTimeout = Duration(seconds: 30);

class CommandResult {
  const CommandResult(this.output, {this.failed = false});

  final String output;
  final bool failed;
}

abstract interface class ToolCommands {
  Future<CommandResult> run(LabCommand command);

  /// Ouvre une application. L'appelant a obtenu l'accord de l'utilisateur.
  Future<void> openAndroidStudio();
  Future<void> startEmulator(String avd);
}

/// Lance uniquement des commandes prévues, sans passer par un shell : aucun
/// texte saisi ne peut devenir une commande.
class LocalToolCommands implements ToolCommands {
  const LocalToolCommands(this.toolchain);

  final LabToolchain toolchain;

  Map<String, String> get _environment => {
    'PATH': '/usr/bin:/bin',
    'HOME': Platform.environment['HOME'] ?? '',
    'LANG': 'C.UTF-8',
    'DISPLAY': ?Platform.environment['DISPLAY'],
    'XAUTHORITY': ?Platform.environment['XAUTHORITY'],
    if (toolchain.javaHome != null) 'JAVA_HOME': toolchain.javaHome!,
    if (toolchain.sdkHome != null) 'ANDROID_HOME': toolchain.sdkHome!,
  };

  @override
  Future<CommandResult> run(LabCommand command) async {
    final executable = toolchain.path(command.tool);
    if (executable == null) {
      return CommandResult(
        '${command.tool.label} est introuvable.',
        failed: true,
      );
    }
    try {
      final result = await Process.run(
        executable,
        command.arguments,
        includeParentEnvironment: false,
        environment: _environment,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      ).timeout(commandTimeout);
      final text = '${result.stdout}${result.stderr}'.trimRight();
      return CommandResult(text, failed: result.exitCode != 0);
    } on Exception catch (error) {
      debugPrint('Commande $executable impossible : $error');
      return CommandResult(
        'La commande n\'a pas pu être lancée. Vérifiez que l\'outil est '
        'installé et accessible, puis réessayez.',
        failed: true,
      );
    }
  }

  Future<void> _detach(String executable, List<String> arguments) {
    return Process.start(
      executable,
      arguments,
      mode: ProcessStartMode.detached,
      includeParentEnvironment: false,
      environment: _environment,
    );
  }

  @override
  Future<void> openAndroidStudio() =>
      _detach(toolchain.path(LabTool.androidStudio)!, const []);

  @override
  Future<void> startEmulator(String avd) {
    if (parseAvds(avd).length != 1) {
      throw ArgumentError.value(avd, 'avd', 'Nom d\'appareil invalide');
    }
    return _detach(toolchain.path(LabTool.emulator)!, ['-avd', avd]);
  }
}
