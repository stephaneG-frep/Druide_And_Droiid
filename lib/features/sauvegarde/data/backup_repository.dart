import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/persistence/app_database.dart';

const backupFormat = 'druide-and-droiid-sauvegarde';
const backupVersion = 1;
const backupJsonName = 'sauvegarde.json';

/// Réglages jamais sauvegardés. Les clés vivent dans le coffre du système et
/// n'entrent jamais en base : seule leur présence y est notée, et elle ne doit
/// pas survivre à une restauration sur un appareil où la clé manque.
const _excludedMetaPrefixes = ['ai.key.'];

class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => 'BackupException: $message';
}

class BackupSummary {
  const BackupSummary({
    required this.createdAt,
    required this.schemaVersion,
    required this.counts,
  });

  final DateTime createdAt;
  final int schemaVersion;
  final Map<String, int> counts;

  int get total => counts.values.fold(0, (sum, count) => sum + count);
}

/// Sauvegarde toutes les tables, ligne par ligne, telles qu'en base. Restaurer
/// remplace tout : c'est l'état exact du jour de la sauvegarde.
class BackupRepository {
  const BackupRepository(this._database, this._clock);

  final AppDatabase _database;
  final DateTime Function() _clock;

  Future<Map<String, Object?>> export() async {
    final tables = <String, Object?>{};
    for (final table in _database.allTables) {
      final name = table.actualTableName;
      final rows = await _database
          .customSelect('SELECT * FROM "$name"', readsFrom: {table})
          .get();
      tables[name] = [
        for (final row in rows)
          if (!_excluded(name, row.data)) row.data,
      ];
    }
    return {
      'format': backupFormat,
      'version': backupVersion,
      'schemaVersion': _database.schemaVersion,
      'createdAt': _clock().toUtc().toIso8601String(),
      'tables': tables,
    };
  }

  bool _excluded(String table, Map<String, Object?> row) =>
      table == 'app_meta' &&
      _excludedMetaPrefixes.any(
        (prefix) => (row['key'] as String?)?.startsWith(prefix) ?? false,
      );

  Future<String> exportJson() async =>
      const JsonEncoder.withIndent(' ').convert(await export());

  /// Lit et vérifie une sauvegarde, sans rien modifier.
  BackupSummary inspect(Map<String, Object?> json) {
    if (json['format'] != backupFormat) {
      throw const BackupException(
        'Ce fichier n\'est pas une sauvegarde de Druide And-Droiīd.',
      );
    }
    if (json['version'] != backupVersion) {
      throw const BackupException('Ce format de sauvegarde est inconnu.');
    }
    final schema = json['schemaVersion'];
    if (schema is! int || schema > _database.schemaVersion) {
      throw const BackupException(
        'Cette sauvegarde vient d\'une version plus récente de l\'application. '
        'Mettez l\'application à jour avant de la restaurer.',
      );
    }
    final tables = json['tables'];
    if (tables is! Map) {
      throw const BackupException('Cette sauvegarde est incomplète.');
    }
    final known = {
      for (final table in _database.allTables) table.actualTableName,
    };
    final counts = <String, int>{};
    for (final MapEntry(:key, :value) in tables.entries) {
      if (!known.contains(key)) {
        throw BackupException('Table inconnue dans la sauvegarde : $key');
      }
      if (value is! List || value.any((row) => row is! Map)) {
        throw BackupException('La table $key est illisible.');
      }
      counts[key as String] = value.length;
    }
    final created = DateTime.tryParse(json['createdAt'] as String? ?? '');
    return BackupSummary(
      createdAt: created?.toLocal() ?? DateTime(1970),
      schemaVersion: schema,
      counts: counts,
    );
  }

  /// Remplace toutes les données par celles de la sauvegarde, d'un seul bloc :
  /// en cas d'erreur, rien ne change.
  Future<BackupSummary> restore(Map<String, Object?> json) async {
    final summary = inspect(json);
    final tables = json['tables']! as Map<String, Object?>;

    await _database.transaction(() async {
      for (final table in _database.allTables.toList().reversed) {
        await _database.customStatement(
          'DELETE FROM "${table.actualTableName}"',
        );
      }
      for (final table in _database.allTables) {
        final name = table.actualTableName;
        final columns = {for (final column in table.$columns) column.name};
        for (final row in (tables[name] as List<Object?>?) ?? const []) {
          final values = <String, Object?>{
            for (final MapEntry(:key, :value) in (row! as Map).entries)
              if (columns.contains(key)) key as String: value,
          };
          if (name == 'app_meta' && _excluded(name, values)) continue;
          if (values.isEmpty) continue;
          final names = values.keys.map((key) => '"$key"').join(', ');
          final marks = List.filled(values.length, '?').join(', ');
          await _database.customInsert(
            'INSERT INTO "$name" ($names) VALUES ($marks)',
            variables: [for (final value in values.values) Variable(value)],
            updates: {table},
          );
        }
      }
    });
    return summary;
  }

  /// Archive : la sauvegarde, plus des copies lisibles des notes et du code.
  Future<List<int>> exportZip({
    Map<String, String> extraFiles = const {},
  }) async {
    final archive = Archive()
      ..addFile(ArchiveFile.string(backupJsonName, await exportJson()))
      ..addFile(
        ArchiveFile.string(
          'LISEZMOI.txt',
          'Sauvegarde de Druide And-Droiīd.\n\n'
              'Pour restaurer : Plus, Paramètres, Sauvegardes, Restaurer, puis '
              'choisissez cette archive.\n\n'
              'Les autres fichiers sont des copies lisibles. Seul $backupJsonName '
              'sert à la restauration.\n\n'
              'Les clés d\'API ne sont jamais incluses : saisissez-les de nouveau '
              'après une restauration.\n',
        ),
      );
    for (final MapEntry(:key, :value) in extraFiles.entries) {
      archive.addFile(ArchiveFile.string(key, value));
    }
    return ZipEncoder().encode(archive);
  }

  /// Accepte une sauvegarde JSON ou une archive ZIP.
  Map<String, Object?> decode(List<int> bytes) {
    final isZip = bytes.length > 4 && bytes[0] == 0x50 && bytes[1] == 0x4b;
    String text;
    if (isZip) {
      final Archive archive;
      try {
        archive = ZipDecoder().decodeBytes(bytes);
      } on Object {
        throw const BackupException('Cette archive est illisible.');
      }
      final file = archive.findFile(backupJsonName);
      if (file == null) {
        throw const BackupException(
          'Cette archive ne contient pas de sauvegarde.',
        );
      }
      text = utf8.decode(file.content as List<int>, allowMalformed: true);
    } else {
      text = utf8.decode(bytes, allowMalformed: true);
    }
    try {
      final json = jsonDecode(text);
      if (json is Map<String, Object?>) return json;
    } on FormatException {
      // Traité ci-dessous.
    }
    throw const BackupException(
      'Ce fichier n\'est pas une sauvegarde lisible.',
    );
  }
}

final backupRepositoryProvider = Provider<BackupRepository>(
  (ref) => BackupRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
  ),
);
