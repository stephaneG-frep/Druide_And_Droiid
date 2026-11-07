import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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

class SystemCodeExporter implements CodeExporter {
  const SystemCodeExporter();

  @override
  Future<String?> export(String fileName, String code) async {
    final bytes = Uint8List.fromList(utf8.encode(code));
    if (Platform.isAndroid) {
      final uri = await FilePicker.saveFile(fileName: fileName, bytes: bytes);
      return uri?.toString();
    }

    // Pas de boîte de dialogue : sur Linux, elle dépend d'outils souvent absents.
    final base =
        await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final folder = await Directory(p.join(base.path, 'Druide And-Droiid'))
        .create(recursive: true);
    final file = await _unusedFile(folder, fileName);
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// N'écrase jamais un fichier déjà exporté.
  Future<File> _unusedFile(Directory folder, String fileName) async {
    final name = p.basenameWithoutExtension(fileName);
    final extension = p.extension(fileName);
    var file = File(p.join(folder.path, fileName));
    for (var index = 2; await file.exists(); index++) {
      file = File(p.join(folder.path, '$name-$index$extension'));
    }
    return file;
  }
}

final codeExporterProvider = Provider<CodeExporter>(
  (ref) => const SystemCodeExporter(),
);
