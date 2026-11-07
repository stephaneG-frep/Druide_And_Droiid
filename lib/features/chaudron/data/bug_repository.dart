import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/persistence/app_database.dart';
import '../../academie/data/course_repository.dart';
import '../domain/bug_rule.dart';
import '../domain/log_tools.dart';

class BugRepository {
  const BugRepository(this._database, this._clock);

  final AppDatabase _database;
  final DateTime Function() _clock;

  Stream<List<BugCaseRow>> watchAll() {
    final query = _database.select(_database.bugCases)
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]);
    return query.watch();
  }

  Stream<BugCaseRow?> watch(int id) {
    final query = _database.select(_database.bugCases)
      ..where((row) => row.id.equals(id));
    return query.watchSingleOrNull();
  }

  Future<int> create({
    required String errorText,
    required String description,
    required String code,
  }) {
    final now = _clock();
    return _database
        .into(_database.bugCases)
        .insert(
          BugCasesCompanion.insert(
            title: titleFromError(errorText, description),
            errorText: errorText,
            description: description,
            code: code,
            status: BugStatus.open.name,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> linkConversation(int id, int conversationId) {
    return _update(
      id,
      BugCasesCompanion(conversationId: Value(conversationId)),
    );
  }

  /// Un résultat réussi exige une trace de la vérification.
  Future<void> recordVerification(
    int id,
    BugStatus status,
    String result,
  ) async {
    final text = result.trim();
    if (status == BugStatus.verified && text.isEmpty) {
      throw ArgumentError.value(result, 'result', 'Vérification sans résultat');
    }
    await _update(
      id,
      BugCasesCompanion(status: Value(status.name), verification: Value(text)),
    );
  }

  Future<void> _update(int id, BugCasesCompanion changes) {
    return (_database.update(_database.bugCases)
          ..where((row) => row.id.equals(id)))
        .write(changes.copyWith(updatedAt: Value(_clock())));
  }

  Future<void> delete(int id) {
    return (_database.delete(
      _database.bugCases,
    )..where((row) => row.id.equals(id))).go();
  }
}

final bugRepositoryProvider = Provider<BugRepository>(
  (ref) =>
      BugRepository(ref.watch(appDatabaseProvider), ref.watch(clockProvider)),
);

final bugCasesProvider = StreamProvider<List<BugCaseRow>>(
  (ref) => ref.watch(bugRepositoryProvider).watchAll(),
  retry: (_, _) => null,
);

final bugCaseProvider = StreamProvider.family<BugCaseRow?, int>(
  (ref, id) => ref.watch(bugRepositoryProvider).watch(id),
  retry: (_, _) => null,
);

final bugRulesProvider = FutureProvider<List<BugRule>>((ref) async {
  final source = await ref
      .watch(assetBundleProvider)
      .loadString('assets/bugs/rules.json');
  return parseRules(jsonDecode(source) as Map<String, Object?>);
}, retry: (_, _) => null);
