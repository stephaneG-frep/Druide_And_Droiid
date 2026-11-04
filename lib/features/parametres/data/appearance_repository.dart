import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/persistence/app_database.dart';
import '../../../design_system/motion.dart';
import '../domain/appearance.dart';

class AppearanceRepository {
  const AppearanceRepository(this._database);

  final AppDatabase _database;

  static const _themeKey = 'appearance.theme';
  static const _motionKey = 'appearance.motion';

  Future<Appearance> load() async {
    final theme = await _database.readMeta(_themeKey);
    final motion = await _database.readMeta(_motionKey);

    return Appearance(
      themeMode:
          ThemeMode.values.asNameMap()[theme] ?? Appearance.defaults.themeMode,
      motion:
          MotionLevel.values.asNameMap()[motion] ?? Appearance.defaults.motion,
    );
  }

  Future<void> save(Appearance appearance) async {
    await _database.writeMeta(_themeKey, appearance.themeMode.name);
    await _database.writeMeta(_motionKey, appearance.motion.name);
  }
}

final appearanceRepositoryProvider = Provider<AppearanceRepository>(
  (ref) => AppearanceRepository(ref.watch(appDatabaseProvider)),
);
