import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/sections.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/persistence/app_database.dart';
import '../../../design_system/arcane_button.dart';
import '../../../design_system/dialogue_bubble.dart';
import '../../../design_system/mascot/maitre_and_droiid.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';
import '../data/ai_settings_repository.dart';
import '../data/conversation_repository.dart';
import '../domain/ai_provider.dart';
import '../domain/teaching.dart';
import 'ai_actions.dart';
import 'ai_paths.dart';

class MaitrePage extends ConsumerWidget {
  const MaitrePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(aiSettingsProvider);

    return switch (settings) {
      AsyncData(:final value) when value.activeConfig != null => _Workspace(
        config: value.activeConfig!,
      ),
      AsyncError() => PageFrame(
        title: AppSection.maitre.label,
        children: const [
          ErrorNotice(
            message: 'Les réglages du Maître n\'ont pas pu être lus.',
          ),
        ],
      ),
      AsyncData() => const _NoProvider(),
      _ => PageFrame(
        title: AppSection.maitre.label,
        children: const [Center(child: CircularProgressIndicator())],
      ),
    };
  }
}

class _NoProvider extends StatelessWidget {
  const _NoProvider();

  @override
  Widget build(BuildContext context) {
    final techno = context.techno;

    return PageFrame(
      title: AppSection.maitre.label,
      children: [
        const DialogueBubble(
          origin: 'Message préenregistré',
          mood: MascotMood.encourageant,
          message:
              'Bienvenue, jeune apprenti ! Mes circuits ne sont reliés à '
              'aucune IA pour l\'instant : je ne peux donc pas vous répondre.',
        ),
        TechnoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Text(
                'Choisissez un fournisseur : Anthropic Claude, OpenAI, Google '
                'Gemini, Ollama ou une API compatible. Votre clé reste dans '
                'le stockage sécurisé de votre appareil.',
                style: context.text.bodyMedium,
              ),
              ArcaneButton(
                label: 'Configurer le Maître',
                icon: Icons.settings_outlined,
                onPressed: () => context.go(aiSettingsPath),
              ),
            ],
          ),
        ),
        Text(
          'Les cours, les quiz, les exercices et leurs corrigés restent '
          'disponibles sans IA.',
          style: context.text.bodySmall!.copyWith(color: techno.muted),
        ),
        const SectionTitle('Ce que je peux faire, une fois relié'),
        TechnoCard(
          child: Column(
            children: [
              for (final mode in TeachingMode.values.skip(1))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.bolt, size: 18, color: techno.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(mode.label, style: context.text.bodyMedium),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Workspace extends ConsumerStatefulWidget {
  const _Workspace({required this.config});

  final AiProviderConfig config;

  @override
  ConsumerState<_Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends ConsumerState<_Workspace> {
  TeachingMode _mode = TeachingMode.general;

  Future<void> _deleteAll() async {
    final confirmed = await _confirm(
      context,
      title: 'Supprimer toutes les conversations ?',
      message: 'Tout l\'historique sera effacé de cet appareil.',
    );
    if (confirmed) {
      await ref.read(conversationRepositoryProvider).deleteAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider);
    final level = ref.watch(aiSettingsProvider).value?.level;

    return PageFrame(
      title: AppSection.maitre.label,
      actions: [
        IconButton(
          tooltip: 'Réglages du Maître',
          icon: const Icon(Icons.tune),
          onPressed: () => context.go(aiSettingsPath),
        ),
      ],
      children: [
        TechnoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Text(
                '${widget.config.kind.label} · ${widget.config.model}',
                style: context.text.titleSmall,
              ),
              DropdownButtonFormField<TeachingMode>(
                initialValue: _mode,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Que voulez-vous faire ?',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final mode in TeachingMode.values)
                    DropdownMenuItem(value: mode, child: Text(mode.label)),
                ],
                onChanged: (mode) => setState(() => _mode = mode ?? _mode),
              ),
              DropdownButtonFormField<LearnerLevel>(
                key: ValueKey(level),
                initialValue: level ?? LearnerLevel.debutant,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Votre niveau',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final level in LearnerLevel.values)
                    DropdownMenuItem(value: level, child: Text(level.label)),
                ],
                onChanged: (level) {
                  if (level != null) {
                    ref.read(aiSettingsRepositoryProvider).setLevel(level);
                  }
                },
              ),
              ArcaneButton(
                label: 'Nouvelle conversation',
                icon: Icons.add_comment_outlined,
                onPressed: () => openNewConversation(context, ref, _mode),
              ),
            ],
          ),
        ),
        const SectionTitle('Conversations'),
        switch (conversations) {
          AsyncData(:final value) when value.isEmpty => const _NoConversation(),
          AsyncData(:final value) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              for (final conversation in value) _ConversationTile(conversation),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _deleteAll,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Tout supprimer'),
                ),
              ),
            ],
          ),
          AsyncError() => const ErrorNotice(
            message: 'L\'historique n\'a pas pu être chargé.',
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ],
    );
  }
}

class _NoConversation extends StatelessWidget {
  const _NoConversation();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Aucune conversation pour l\'instant.',
      style: context.text.bodyMedium!.copyWith(color: context.techno.muted),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile(this.conversation);

  final AiConversationRow conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TechnoCard(
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => context.go(conversationPath(conversation.id)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall,
                    ),
                    Text(
                      TeachingMode.byName(conversation.mode).label,
                      style: context.text.bodySmall!.copyWith(
                        color: context.techno.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Supprimer la conversation',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirmed = await _confirm(
                context,
                title: 'Supprimer cette conversation ?',
                message: 'Ses messages seront effacés de cet appareil.',
              );
              if (confirmed) {
                await ref
                    .read(conversationRepositoryProvider)
                    .delete(conversation.id);
              }
            },
          ),
        ],
      ),
    );
  }
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
