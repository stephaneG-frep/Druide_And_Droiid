import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Au-delà, seule la fin du fichier est lue : les erreurs récentes y sont.
const maxImportBytes = 2 * 1024 * 1024;

class ImportedLog {
  const ImportedLog(this.name, this.text, {required this.truncated});

  final String name;
  final String text;
  final bool truncated;
}

abstract interface class LogImporter {
  /// Renvoie `null` si l'utilisateur renonce.
  Future<ImportedLog?> pick();
}

/// `file_selector` ouvre une boîte de dialogue native, sans outil externe.
class SystemLogImporter implements LogImporter {
  const SystemLogImporter();

  @override
  Future<ImportedLog?> pick() async {
    final file = await openFile();
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final truncated = bytes.length > maxImportBytes;
    final kept = truncated
        ? bytes.sublist(bytes.length - maxImportBytes)
        : bytes;
    return ImportedLog(
      file.name,
      utf8.decode(kept, allowMalformed: true),
      truncated: truncated,
    );
  }
}

final logImporterProvider = Provider<LogImporter>(
  (ref) => const SystemLogImporter(),
);
