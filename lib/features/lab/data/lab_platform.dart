import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sauvegarde/data/file_saver.dart';
import 'code_runner.dart';
import 'tool_commands.dart';
import 'tool_detector.dart';

/// Possibilités réelles de la plateforme. Sur Android, le Lab n'exécute rien :
/// aucun compilateur ne tourne sur le téléphone, et il ne fait pas semblant.
class LabCapabilities {
  const LabCapabilities({required this.canRunCode});

  final bool canRunCode;
}

final labCapabilitiesProvider = Provider<LabCapabilities>(
  (ref) => LabCapabilities(canRunCode: Platform.isLinux),
);

final labToolchainProvider = Provider<LabToolchain>(
  (ref) =>
      Platform.isLinux ? ToolDetector.system().detect() : const LabToolchain(),
);

final codeRunnerProvider = Provider<CodeRunner>(
  (ref) => LocalCodeRunner(ref.watch(labToolchainProvider)),
);

final toolCommandsProvider = Provider<ToolCommands>(
  (ref) => LocalToolCommands(ref.watch(labToolchainProvider)),
);

abstract interface class CodeExporter {
  /// Renvoie l'emplacement choisi, ou `null` si l'utilisateur renonce.
  Future<String?> export(String fileName, String code);
}

/// Passe par l'enregistreur commun, qui laisse choisir la destination.
class SystemCodeExporter implements CodeExporter {
  const SystemCodeExporter(this._saver);

  final FileSaver _saver;

  @override
  Future<String?> export(String fileName, String code) =>
      _saver.save(fileName, utf8.encode(code));
}

final codeExporterProvider = Provider<CodeExporter>(
  (ref) => SystemCodeExporter(ref.watch(fileSaverProvider)),
);
