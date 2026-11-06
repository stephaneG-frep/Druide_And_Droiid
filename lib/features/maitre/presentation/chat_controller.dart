import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/security/secret_store.dart';
import '../data/ai_clients.dart';
import '../data/ai_settings_repository.dart';
import '../data/conversation_repository.dart';
import '../domain/ai_chat.dart';
import '../domain/ai_provider.dart';
import '../domain/teaching.dart';

/// Limite de l'historique envoyé, en caractères : assez pour un long échange,
/// sans laisser le coût de chaque question grimper sans fin.
const maxHistoryChars = 48000;

typedef AiClientBuilder = Future<AiClient> Function(AiProviderConfig config);

/// Remplaçable en test : aucun appel réel, donc aucun crédit consommé.
final aiClientBuilderProvider = Provider<AiClientBuilder>((ref) {
  final settings = ref.watch(aiSettingsRepositoryProvider);
  return (config) async {
    final key = config.kind.acceptsKey
        ? await settings.readKey(config.kind)
        : null;
    return createAiClient(
      config: config,
      apiKey: key,
      clientFactory: http.Client.new,
    );
  };
});

class ChatState {
  const ChatState({
    this.responding = false,
    this.partial = '',
    this.failure,
    this.canRetry = false,
    this.historyTrimmed = false,
  });

  final bool responding;
  final String partial;
  final String? failure;
  final bool canRetry;

  /// Les messages les plus anciens n'ont pas été envoyés au modèle.
  final bool historyTrimmed;
}

class ChatController extends Notifier<ChatState> {
  ChatController(this.conversationId);

  final int conversationId;

  AiClient? _client;
  StreamSubscription<AiEvent>? _subscription;
  Completer<void>? _finished;
  final _text = StringBuffer();
  int? _inputTokens;
  int? _outputTokens;
  AiStopReason? _reason;

  ConversationRepository get _repository =>
      ref.read(conversationRepositoryProvider);

  @override
  ChatState build() {
    ref.onDispose(() {
      _client?.abort();
      unawaited(_subscription?.cancel());
    });
    return const ChatState();
  }

  Future<void> send(String text) async {
    final question = text.trim();
    if (question.isEmpty || state.responding) return;
    await _repository.addUserMessage(conversationId, question);
    await _respond();
  }

  /// Relance la dernière question sans la dupliquer.
  Future<void> retry() async {
    if (!state.responding) await _respond();
  }

  /// Arrête la réponse et garde ce qui a déjà été reçu.
  Future<void> stop() async {
    final subscription = _subscription;
    if (subscription == null) return;
    _client?.abort();
    unawaited(subscription.cancel());
    _reason = AiStopReason.interrupted;
    await _finish();
  }

  Future<void> _respond() async {
    _text.clear();
    _inputTokens = null;
    _outputTokens = null;
    _reason = null;
    state = const ChatState(responding: true);

    try {
      final settings = await ref.read(aiSettingsRepositoryProvider).read();
      final config = settings.activeConfig;
      if (config == null) {
        state = const ChatState(
          failure: 'Aucun fournisseur prêt. Vérifiez les réglages du Maître.',
        );
        return;
      }
      final conversation = await _repository.conversation(conversationId);
      await _repository.useProvider(
        conversationId,
        config.kind.name,
        config.model,
      );
      final rows = await _repository.messages(conversationId);
      final history = [
        for (final row in rows)
          if (row.content.isNotEmpty)
            AiMessage(
              row.role == AiRole.user.name ? AiRole.user : AiRole.assistant,
              row.content,
            ),
      ];
      final kept = trimHistory(history, maxChars: maxHistoryChars);
      final trimmed = kept.length < history.length;
      state = ChatState(responding: true, historyTrimmed: trimmed);

      final client = await ref.read(aiClientBuilderProvider)(config);
      _client = client;
      final finished = Completer<void>();
      _finished = finished;
      _subscription = client
          .chat(
            AiRequest(
              model: config.model,
              system: systemPrompt(
                level: settings.level,
                mode: TeachingMode.byName(conversation.mode),
              ),
              messages: kept,
              maxOutputTokens: config.maxOutputTokens,
            ),
          )
          .listen(
            _onEvent,
            onError: (Object error, StackTrace _) => unawaited(_fail(error)),
            onDone: () => unawaited(_finish()),
            cancelOnError: true,
          );
      await finished.future;
    } on AiFailure catch (failure) {
      await _fail(failure);
    } on SecretStoreUnavailable catch (error) {
      await _fail(error);
    }
  }

  void _onEvent(AiEvent event) {
    switch (event) {
      case AiTextDelta(:final text):
        _text.write(text);
        state = ChatState(
          responding: true,
          partial: _text.toString(),
          historyTrimmed: state.historyTrimmed,
        );
      case AiUsage(:final inputTokens, :final outputTokens):
        _inputTokens = inputTokens;
        _outputTokens = outputTokens;
      case AiDone(:final reason):
        _reason = reason;
    }
  }

  Future<void> _fail(Object error) async {
    final failure = switch (error) {
      AiFailure() => error,
      _ => null,
    };
    await _save(_text.isEmpty ? null : AiStopReason.interrupted);
    state = ChatState(
      failure: switch (error) {
        AiFailure(:final message) => message,
        SecretStoreUnavailable(:final message) => message,
        _ => AiFailureKind.invalidResponse.message,
      },
      canRetry: failure?.kind.retryable ?? false,
      historyTrimmed: state.historyTrimmed,
    );
    _complete();
  }

  Future<void> _finish() async {
    final reason = _reason ?? AiStopReason.interrupted;
    await _save(reason);
    state = ChatState(historyTrimmed: state.historyTrimmed);
    _complete();
  }

  Future<void> _save(AiStopReason? reason) async {
    if (reason == null) return;
    final text = _text.toString();
    if (text.isEmpty && reason != AiStopReason.refused) return;
    await _repository.addAssistantMessage(
      conversationId,
      text,
      reason: reason,
      inputTokens: _inputTokens,
      outputTokens: _outputTokens,
    );
    _text.clear();
  }

  void _complete() {
    _subscription = null;
    final finished = _finished;
    _finished = null;
    if (finished != null && !finished.isCompleted) finished.complete();
  }
}

final chatControllerProvider =
    NotifierProvider.family<ChatController, ChatState, int>(ChatController.new);
