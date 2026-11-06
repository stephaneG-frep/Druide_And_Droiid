import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/persistence/app_database.dart';
import '../domain/ai_chat.dart';
import '../domain/teaching.dart';

const _titleLength = 60;

class ConversationRepository {
  const ConversationRepository(this._database, this._clock);

  final AppDatabase _database;
  final DateTime Function() _clock;

  Stream<List<AiConversationRow>> watchAll() {
    final query = _database.select(_database.aiConversations)
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]);
    return query.watch();
  }

  Future<AiConversationRow> conversation(int id) {
    final query = _database.select(_database.aiConversations)
      ..where((row) => row.id.equals(id));
    return query.getSingle();
  }

  Stream<AiConversationRow?> watchConversation(int id) {
    final query = _database.select(_database.aiConversations)
      ..where((row) => row.id.equals(id));
    return query.watchSingleOrNull();
  }

  SimpleSelectStatement<$AiMessagesTable, AiMessageRow> _messages(int id) {
    return _database.select(_database.aiMessages)
      ..where((row) => row.conversationId.equals(id))
      ..orderBy([(row) => OrderingTerm.asc(row.id)]);
  }

  Stream<List<AiMessageRow>> watchMessages(int id) => _messages(id).watch();

  Future<List<AiMessageRow>> messages(int id) => _messages(id).get();

  Future<int> create({
    required String title,
    required String providerKind,
    required String model,
    required TeachingMode mode,
  }) {
    final now = _clock();
    return _database
        .into(_database.aiConversations)
        .insert(
          AiConversationsCompanion.insert(
            title: title,
            providerKind: providerKind,
            model: model,
            mode: mode.name,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> addUserMessage(int id, String text) {
    return _database.transaction(() async {
      final isFirst = (await messages(id)).isEmpty;
      await _add(id, AiRole.user, text);
      await _touch(id, title: isFirst ? titleFrom(text) : null);
    });
  }

  Future<void> addAssistantMessage(
    int id,
    String text, {
    required AiStopReason reason,
    int? inputTokens,
    int? outputTokens,
  }) {
    return _database.transaction(() async {
      await _add(
        id,
        AiRole.assistant,
        text,
        reason: reason,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
      );
      await _touch(id);
    });
  }

  Future<void> useProvider(int id, String providerKind, String model) {
    return (_database.update(
      _database.aiConversations,
    )..where((row) => row.id.equals(id))).write(
      AiConversationsCompanion(
        providerKind: Value(providerKind),
        model: Value(model),
      ),
    );
  }

  Future<void> _add(
    int id,
    AiRole role,
    String text, {
    AiStopReason? reason,
    int? inputTokens,
    int? outputTokens,
  }) {
    return _database
        .into(_database.aiMessages)
        .insert(
          AiMessagesCompanion.insert(
            conversationId: id,
            role: role.name,
            content: text,
            stopReason: Value(reason?.name),
            inputTokens: Value(inputTokens),
            outputTokens: Value(outputTokens),
            createdAt: _clock(),
          ),
        );
  }

  Future<void> _touch(int id, {String? title}) {
    return (_database.update(
      _database.aiConversations,
    )..where((row) => row.id.equals(id))).write(
      AiConversationsCompanion(
        updatedAt: Value(_clock()),
        title: title == null ? const Value.absent() : Value(title),
      ),
    );
  }

  Future<void> delete(int id) {
    return _database.transaction(() async {
      await (_database.delete(
        _database.aiMessages,
      )..where((row) => row.conversationId.equals(id))).go();
      await (_database.delete(
        _database.aiConversations,
      )..where((row) => row.id.equals(id))).go();
    });
  }

  Future<void> deleteAll() {
    return _database.transaction(() async {
      await _database.delete(_database.aiMessages).go();
      await _database.delete(_database.aiConversations).go();
    });
  }

  static String titleFrom(String text) {
    final line = text.trim().split('\n').first.trim();
    return line.length <= _titleLength
        ? line
        : '${line.substring(0, _titleLength)}…';
  }
}

final conversationRepositoryProvider = Provider<ConversationRepository>(
  (ref) => ConversationRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
  ),
);

final conversationsProvider = StreamProvider<List<AiConversationRow>>(
  (ref) => ref.watch(conversationRepositoryProvider).watchAll(),
  retry: (_, _) => null,
);

final conversationProvider = StreamProvider.family<AiConversationRow?, int>(
  (ref, id) => ref.watch(conversationRepositoryProvider).watchConversation(id),
  retry: (_, _) => null,
);

final conversationMessagesProvider =
    StreamProvider.family<List<AiMessageRow>, int>(
      (ref, id) => ref.watch(conversationRepositoryProvider).watchMessages(id),
      retry: (_, _) => null,
    );
