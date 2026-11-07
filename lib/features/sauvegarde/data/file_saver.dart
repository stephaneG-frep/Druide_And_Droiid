import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract interface class FileSaver {
  /// Enregistre [bytes] où l'utilisateur le choisit. Renvoie l'emplacement, ou
  /// `null` s'il renonce.
  Future<String?> save(String fileName, List<int> bytes);
}

/// Sur Android, le sélecteur du système. Sur Linux, la boîte de dialogue native
/// de GTK ; si elle ne s'ouvre pas, le dossier Téléchargements.
class SystemFileSaver implements FileSaver {
  const SystemFileSaver();

  @override
  Future<String?> save(String fileName, List<int> bytes) async {
    final data = Uint8List.fromList(bytes);
    if (Platform.isAndroid) {
      final uri = await FilePicker.saveFile(fileName: fileName, bytes: data);
      return uri?.toString();
    }
    try {
      final location = await getSaveLocation(suggestedName: fileName);
      if (location == null) return null;
      await File(location.path).writeAsBytes(data, flush: true);
      return location.path;
    } on Exception {
      return saveInDownloads(fileName, data);
    }
  }
}

/// N'écrase jamais un fichier existant.
Future<String> saveInDownloads(String fileName, List<int> bytes) async {
  final base =
      await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
  final folder = await Directory(p.join(base.path, 'Druide And-Droiid'))
      .create(recursive: true);
  final name = p.basenameWithoutExtension(fileName);
  final extension = p.extension(fileName);
  var file = File(p.join(folder.path, fileName));
  for (var index = 2; await file.exists(); index++) {
    file = File(p.join(folder.path, '$name-$index$extension'));
  }
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

abstract interface class FileOpener {
  /// Contenu du fichier choisi, ou `null` si l'utilisateur renonce.
  Future<List<int>?> open();
}

class SystemFileOpener implements FileOpener {
  const SystemFileOpener();

  @override
  Future<List<int>?> open() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Sauvegardes',
          extensions: ['json', 'zip'],
          mimeTypes: ['application/json', 'application/zip'],
        ),
      ],
    );
    return file?.readAsBytes();
  }
}

final fileSaverProvider = Provider<FileSaver>((ref) => const SystemFileSaver());

final fileOpenerProvider = Provider<FileOpener>(
  (ref) => const SystemFileOpener(),
);
