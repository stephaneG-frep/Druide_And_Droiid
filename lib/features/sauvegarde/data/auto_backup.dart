import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/clock.dart';
import 'backup_repository.dart';

const keptAutoBackups = 5;
const autoBackupInterval = Duration(hours: 24);

class AutoBackupFile {
  const AutoBackupFile(this.file, this.date, {required this.beforeRestore});

  final File file;
  final DateTime date;
  final bool beforeRestore;
}

/// Copies de sécurité dans le dossier privé de l'application. Elles protègent
/// d'une fausse manipulation, pas d'une désinstallation : pour cela, il faut
/// exporter une sauvegarde ailleurs.
class AutoBackups {
  const AutoBackups(this._backups, this._folder, this._clock);

  final BackupRepository _backups;
  final Future<Directory> Function() _folder;
  final DateTime Function() _clock;

  Future<Directory> _directory() async {
    final base = await _folder();
    return Directory(p.join(base.path, 'sauvegardes')).create(recursive: true);
  }

  Future<List<AutoBackupFile>> list() async {
    final directory = await _directory();
    final files = <AutoBackupFile>[];
    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      files.add(
        AutoBackupFile(
          entity,
          await entity.lastModified(),
          beforeRestore: p.basename(entity.path).startsWith('avant-'),
        ),
      );
    }
    return files..sort((a, b) => b.date.compareTo(a.date));
  }

  String _stamp(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}${two(date.month)}${two(date.day)}-'
        '${two(date.hour)}${two(date.minute)}${two(date.second)}';
  }

  Future<File> create({bool beforeRestore = false}) async {
    final directory = await _directory();
    final prefix = beforeRestore ? 'avant-restauration' : 'auto';
    final file = File(
      p.join(directory.path, '$prefix-${_stamp(_clock())}.json'),
    );
    await file.writeAsString(await _backups.exportJson(), flush: true);
    await _prune();
    return file;
  }

  /// Crée une copie si la dernière date de plus d'un jour.
  Future<File?> runIfDue() async {
    final latest = (await list()).where((item) => !item.beforeRestore);
    if (latest.isNotEmpty &&
        _clock().difference(latest.first.date) < autoBackupInterval) {
      return null;
    }
    return create();
  }

  Future<void> _prune() async {
    final all = await list();
    for (final kind in [true, false]) {
      final group = all.where((item) => item.beforeRestore == kind).toList();
      for (final old in group.skip(keptAutoBackups)) {
        await old.file.delete();
      }
    }
  }
}

final autoBackupsProvider = Provider<AutoBackups>(
  (ref) => AutoBackups(
    ref.watch(backupRepositoryProvider),
    getApplicationSupportDirectory,
    ref.watch(clockProvider),
  ),
);

final autoBackupListProvider = FutureProvider<List<AutoBackupFile>>(
  (ref) => ref.watch(autoBackupsProvider).list(),
  retry: (_, _) => null,
);
