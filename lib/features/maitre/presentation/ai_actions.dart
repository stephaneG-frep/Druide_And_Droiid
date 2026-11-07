import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/druide_toast.dart';
import '../data/ai_settings_repository.dart';
import '../data/conversation_repository.dart';
import '../domain/ai_provider.dart';
import '../domain/teaching.dart';
import 'ai_paths.dart';
import 'chat_controller.dart';

/// Demande l'accord avant le premier envoi vers un service externe.
Future<bool> ensureConsent(
  BuildContext context,
  WidgetRef ref,
  AiSettings settings,
  AiProviderConfig config,
) async {
  if (config.staysOnDevice || settings.consents.contains(config.kind)) {
    return true;
  }
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Envoyer vers ${config.kind.label} ?'),
      content: const Text(
        'Vos questions et l\'historique de la conversation seront envoyés à '
        'ce service, selon ses conditions. Selon votre abonnement, chaque '
        'réponse peut être facturée sur votre compte.\n\n'
        'N\'y mettez ni mot de passe, ni clé, ni donnée personnelle.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Refuser'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Accepter'),
        ),
      ],
    ),
  );
  if (accepted != true) return false;
  await ref.read(aiSettingsRepositoryProvider).grantConsent(config.kind);
  return true;
}

Future<int> _startConversation(
  WidgetRef ref,
  AiProviderConfig config,
  TeachingMode mode,
) {
  return ref
      .read(conversationRepositoryProvider)
      .create(
        title: mode.label,
        providerKind: config.kind.name,
        model: config.model,
        mode: mode,
      );
}

/// Ouvre une conversation, avec une question préparée mais non envoyée.
Future<void> openNewConversation(
  BuildContext context,
  WidgetRef ref,
  TeachingMode mode, {
  String? question,
}) async {
  final config =
      (await ref.read(aiSettingsRepositoryProvider).read()).activeConfig;
  if (config == null) return;
  final id = await _startConversation(ref, config, mode);
  if (context.mounted) context.go(conversationPath(id, question: question));
}

/// Envoie une demande de correction, après l'accord de l'utilisateur.
Future<void> askForCorrection(
  BuildContext context,
  WidgetRef ref, {
  required String statement,
  required String answer,
  required String reference,
}) async {
  if (answer.trim().isEmpty) {
    showDruideToast(
      context,
      'Écrivez d\'abord votre réponse.',
      kind: ToastKind.error,
    );
    return;
  }
  final settings = await ref.read(aiSettingsRepositoryProvider).read();
  final config = settings.activeConfig;
  if (config == null || !context.mounted) return;
  if (!await ensureConsent(context, ref, settings, config)) return;

  final id = await _startConversation(ref, config, TeachingMode.correct);
  final controller = ref.read(chatControllerProvider(id).notifier);
  final sending = controller.send(
    correctionMessage(
      statement: statement,
      answer: answer,
      reference: reference,
    ),
  );
  if (context.mounted) context.go(conversationPath(id));
  await sending;
}

/// Demande une relecture de code libre, après l'accord de l'utilisateur.
Future<void> askForReview(
  BuildContext context,
  WidgetRef ref, {
  required String language,
  required String code,
}) async {
  final settings = await ref.read(aiSettingsRepositoryProvider).read();
  final config = settings.activeConfig;
  if (config == null || !context.mounted) return;
  if (!await ensureConsent(context, ref, settings, config)) return;

  final id = await _startConversation(ref, config, TeachingMode.improve);
  final controller = ref.read(chatControllerProvider(id).notifier);
  final sending = controller.send(
    'Relis ce code $language et propose des améliorations.\n\n'
    '```$language\n$code\n```',
  );
  if (context.mounted) context.go(conversationPath(id));
  await sending;
}
