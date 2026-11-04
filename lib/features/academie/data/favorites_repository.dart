import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/persistence/app_database.dart';

enum FavoriteKind { module }

class FavoritesRepository {
  const FavoritesRepository(this._database, this._now);

  final AppDatabase _database;
  final DateTime Function() _now;

  Stream<Set<String>> watch(FavoriteKind kind) {
    final query = _database.select(_database.favorites)
      ..where((row) => row.kind.equals(kind.name));
    return query.watch().map((rows) => {for (final row in rows) row.targetId});
  }

  Future<void> setFavorite(
    FavoriteKind kind,
    String targetId, {
    required bool favorite,
  }) async {
    if (favorite) {
      await _database
          .into(_database.favorites)
          .insertOnConflictUpdate(
            FavoritesCompanion.insert(
              kind: kind.name,
              targetId: targetId,
              createdAt: _now(),
            ),
          );
    } else {
      await (_database.delete(_database.favorites)..where(
            (row) => row.kind.equals(kind.name) & row.targetId.equals(targetId),
          ))
          .go();
    }
  }
}

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
  ),
);

final favoriteModulesProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(favoritesRepositoryProvider).watch(FavoriteKind.module),
);
