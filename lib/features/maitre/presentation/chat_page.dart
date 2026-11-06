import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/persistence/app_database.dart';
import '../../../design_system/arcane_button.dart';
import '../../../design_system/circuit_backdrop.dart';
import '../../../design_system/techno_card.dart';
import '../data/ai_settings_repository.dart';
import '../data/conversation_repository.dart';
import '../domain/ai_chat.dart';
import '../domain/ai_provider.dart';
import 'ai_actions.dart';
import 'ai_message_view.dart';
import 'chat_controller.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({required this.conversationId, this.question, super.key});

  final int conversationId;

  /// Question préparée par une autre page, jamais envoyée sans action.
  final String? question;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  late final _input = TextEditingController(text: widget.question);
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    final repository = ref.read(aiSettingsRepositoryProvider);
    final settings = await repository.read();
    final config = settings.activeConfig;
    if (config == null || !mounted) return;
    if (!await ensureConsent(context, ref, settings, config)) return;
    _input.clear();
    await ref
        .read(chatControllerProvider(widget.conversationId).notifier)
        .send(text);
  }

  void _followBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.conversationId;
    final conversation = ref.watch(conversationProvider(id)).value;
    final messages = ref.watch(conversationMessagesProvider(id));
    final chat = ref.watch(chatControllerProvider(id));
    final controller = ref.read(chatControllerProvider(id).notifier);
    final config = ref.watch(aiSettingsProvider).value?.activeConfig;
    _followBottom();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          conversation?.title ?? 'Conversation',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: CircuitBackdrop(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                children: [
                  const _AiNotice(),
                  if (chat.historyTrimmed) const _TrimmedNotice(),
                  for (final message in messages.value ?? <AiMessageRow>[])
                    _MessageBubble(message, config: config),
                  if (chat.responding) _PendingBubble(text: chat.partial),
                  if (chat.failure case final failure?) ...[
                    ErrorNotice(message: failure),
                    if (chat.canRetry)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ArcaneButton(
                            label: 'Réessayer',
                            icon: Icons.refresh,
                            onPressed: controller.retry,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 6,
                        enabled: config != null,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          labelText: config == null
                              ? 'Aucun fournisseur prêt'
                              : 'Votre question',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (chat.responding)
                      IconButton(
                        tooltip: 'Arrêter la réponse',
                        icon: const Icon(Icons.stop_circle_outlined),
                        onPressed: controller.stop,
                      )
                    else
                      IconButton(
                        tooltip: 'Envoyer',
                        icon: const Icon(Icons.send),
                        onPressed: config == null ? null : _send,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiNotice extends StatelessWidget {
  const _AiNotice();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        'Ces réponses sont générées par une IA. Elles peuvent contenir des '
        'erreurs : vérifiez-les, et relisez tout code avant de l\'utiliser.',
        style: context.text.bodySmall!.copyWith(color: context.techno.muted),
      ),
    );
  }
}

class _TrimmedNotice extends StatelessWidget {
  const _TrimmedNotice();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: PhaseNotice(
        message:
            'Cette conversation est longue : seuls les messages les plus '
            'récents ont été envoyés au modèle.',
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.fromUser, required this.child});

  final bool fromUser;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: fromUser ? 32 : 0,
        right: fromUser ? 0 : 16,
      ),
      child: TechnoCard(child: child),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble(this.message, {required this.config});

  final AiMessageRow message;
  final AiProviderConfig? config;

  String? get _notice => switch (message.stopReason) {
    'truncated' =>
      'Réponse coupée par la limite de longueur, réglable dans les paramètres.',
    'refused' => 'Le service a refusé de répondre à cette demande.',
    'interrupted' => 'Réponse interrompue avant sa fin.',
    _ => null,
  };

  String? get _usage {
    final input = message.inputTokens;
    final output = message.outputTokens;
    if (input == null && output == null) return null;
    final tokens =
        'Jetons : ${input ?? '?'} en entrée, ${output ?? '?'} en sortie';
    final cost = estimateCost(
      inputTokens: input,
      outputTokens: output,
      inputPricePerMillion: config?.inputPricePerMillion,
      outputPricePerMillion: config?.outputPricePerMillion,
    );
    return cost == null
        ? tokens
        : '$tokens · environ ${cost.toStringAsFixed(4)} \$ selon vos tarifs';
  }

  @override
  Widget build(BuildContext context) {
    final fromUser = message.role == AiRole.user.name;
    final muted = context.text.bodySmall!.copyWith(color: context.techno.muted);

    return _Bubble(
      fromUser: fromUser,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Text(
            fromUser ? 'Vous' : 'Maître And-Droiīd · IA',
            style: context.text.labelMedium,
          ),
          if (message.content.isNotEmpty) AiMessageView(message.content),
          if (_notice case final notice?)
            Text(notice, style: muted.copyWith(color: context.techno.orange)),
          if (_usage case final usage?) Text(usage, style: muted),
        ],
      ),
    );
  }
}

class _PendingBubble extends StatelessWidget {
  const _PendingBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _Bubble(
      fromUser: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Text('Maître And-Droiīd · IA', style: context.text.labelMedium),
          if (text.isEmpty)
            Text('Réflexion en cours…', style: context.text.bodyMedium)
          else
            AiMessageView(text),
        ],
      ),
    );
  }
}
