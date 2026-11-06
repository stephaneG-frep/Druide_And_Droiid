import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/persistence/app_database.dart';
import '../../../core/security/secret_store.dart';
import '../domain/ai_provider.dart';

const _prefix = 'ai.';
const _activeKey = '${_prefix}active';
const _levelKey = '${_prefix}level';
const _configPrefix = '${_prefix}config.';
const _keyFlagPrefix = '${_prefix}key.';
const _consentPrefix = '${_prefix}consent.';

/// Les réglages vont en base, les clés dans le coffre. La base ne retient que
/// la présence d'une clé : afficher un écran ne sollicite pas le trousseau.
class AiSettingsRepository {
  const AiSettingsRepository(this._database, this._secrets);

  final AppDatabase _database;
  final SecretStore _secrets;

  SimpleSelectStatement<$AppMetaTable, AppMetaData> get _rows =>
      _database.select(_database.appMeta)
        ..where((row) => row.key.like('$_prefix%'));

  Stream<AiSettings> watch() => _rows.watch().map(_settingsFrom);

  Future<AiSettings> read() => _rows.get().then(_settingsFrom);

  AiSettings _settingsFrom(List<AppMetaData> rows) {
    final values = {for (final row in rows) row.key: row.value};
    return AiSettings(
      active: AiProviderKind.byName(values[_activeKey]),
      level: LearnerLevel.byName(values[_levelKey]),
      configs: {
        for (final kind in AiProviderKind.values)
          if (values['$_configPrefix${kind.name}'] case final encoded?)
            kind: AiProviderConfig.fromJson(
              kind,
              jsonDecode(encoded) as Map<String, Object?>,
            ),
      },
      keysSaved: {
        for (final kind in AiProviderKind.values)
          if (values.containsKey('$_keyFlagPrefix${kind.name}')) kind,
      },
      consents: {
        for (final kind in AiProviderKind.values)
          if (values.containsKey('$_consentPrefix${kind.name}')) kind,
      },
    );
  }

  Future<void> saveConfig(AiProviderConfig config) =>
      _database.writeMeta('$_configPrefix${config.kind.name}', config.encode());

  Future<void> setActive(AiProviderKind kind) =>
      _database.writeMeta(_activeKey, kind.name);

  Future<void> setLevel(LearnerLevel level) =>
      _database.writeMeta(_levelKey, level.name);

  Future<void> grantConsent(AiProviderKind kind) =>
      _database.writeMeta('$_consentPrefix${kind.name}', '1');

  Future<void> saveKey(AiProviderKind kind, String key) async {
    await _secrets.write(_secretName(kind), key);
    await _database.writeMeta('$_keyFlagPrefix${kind.name}', '1');
  }

  Future<void> deleteKey(AiProviderKind kind) async {
    await _secrets.delete(_secretName(kind));
    await (_database.delete(
      _database.appMeta,
    )..where((row) => row.key.equals('$_keyFlagPrefix${kind.name}'))).go();
  }

  Future<String?> readKey(AiProviderKind kind) =>
      _secrets.read(_secretName(kind));

  String _secretName(AiProviderKind kind) => 'ai_key_${kind.name}';
}

final aiSettingsRepositoryProvider = Provider<AiSettingsRepository>(
  (ref) => AiSettingsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(secretStoreProvider),
  ),
);

final aiSettingsProvider = StreamProvider<AiSettings>(
  (ref) => ref.watch(aiSettingsRepositoryProvider).watch(),
  retry: (_, _) => null,
);
