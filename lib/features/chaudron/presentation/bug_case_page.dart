import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/sections.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/persistence/app_database.dart';
import '../../../design_system/arcane_button.dart';
import '../../../design_system/console_panel.dart';
import '../../../design_system/druide_toast.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';
import '../../maitre/data/ai_settings_repository.dart';
import '../../maitre/domain/teaching.dart';
import '../../maitre/presentation/ai_actions.dart';
import '../../maitre/presentation/ai_paths.dart';
import '../data/bug_repository.dart';
import '../domain/bug_rule.dart';
import '../domain/log_tools.dart';
import 'bug_rule_view.dart';

class BugCasePage extends ConsumerWidget {
  const BugCasePage({required this.caseId, super.key});

  final int caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bugCase = ref.watch(bugCaseProvider(caseId));

    return switch (bugCase) {
      AsyncData(:final value?) => _CaseContent(
        key: ValueKey(value.id),
        row: value,
      ),
      AsyncError() => const PageFrame(
        title: 'Dossier',
        children: [ErrorNotice(message: 'Ce dossier n\'a pas pu être chargé.')],
      ),
      AsyncData() => const PageFrame(
        title: 'Dossier',
        children: [Text('Ce dossier n\'existe plus.')],
      ),
      _ => const PageFrame(
        title: 'Dossier',
        children: [Center(child: CircularProgressIndicator())],
      ),
    };
  }
}

class _CaseContent extends ConsumerStatefulWidget {
  const _CaseContent({required this.row, super.key});

  final BugCaseRow row;

  @override
  ConsumerState<_CaseContent> createState() => _CaseContentState();
}

class _CaseContentState extends ConsumerState<_CaseContent> {
  late final _result = TextEditingController(text: widget.row.verification);

  BugCaseRow get _row => widget.row;

  @override
  void dispose() {
    _result.dispose();
    super.dispose();
  }

  Future<void> _askAi(List<BugRule> matches) async {
    final raw = diagnosisMessage(
      description: _row.description,
      log: extractRelevant(_row.errorText),
      code: _row.code,
      knownPanes: [for (final rule in matches) rule.title],
    );
    final redaction = redactSecrets(raw);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vérifiez ce qui sera envoyé'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                Text(
                  '${redaction.count} élément(s) masqué(s) automatiquement. '
                  'Ce filtre est imparfait : relisez avant d\'envoyer.',
                  style: context.text.bodySmall,
                ),
                if (_row.errorText.length > maxDiagnosisChars)
                  Text(
                    'Journal long : seules les lignes utiles sont envoyées.',
                    style: context.text.bodySmall,
                  ),
                SelectableText(
                  redaction.text,
                  style: const TextStyle(fontFamily: fontCode, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final conversation = await askForDiagnosis(
      context,
      ref,
      message: redaction.text,
    );
    if (conversation == null || !mounted) return;
    await ref
        .read(bugRepositoryProvider)
        .linkConversation(_row.id, conversation);
    if (mounted) context.go(conversationPath(conversation));
  }

  Future<void> _record(BugStatus status) async {
    final result = _result.text.trim();
    if (status == BugStatus.verified && result.isEmpty) {
      showDruideToast(
        context,
        'Notez d\'abord le résultat de votre vérification.',
        kind: ToastKind.error,
      );
      return;
    }
    await ref
        .read(bugRepositoryProvider)
        .recordVerification(_row.id, status, result);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce dossier ?'),
        content: const Text(
          'La conversation avec le Maître, s\'il y en a une, reste disponible '
          'dans l\'historique.',
        ),
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
    if (confirmed != true || !mounted) return;
    await ref.read(bugRepositoryProvider).delete(_row.id);
    if (mounted) context.go(AppSection.chaudron.path);
  }

  @override
  Widget build(BuildContext context) {
    final rules = ref.watch(bugRulesProvider).value ?? const <BugRule>[];
    final matches = matchRules(rules, '${_row.errorText}\n${_row.description}');
    final hasTeacher = ref.watch(
      aiSettingsProvider.select(
        (settings) => settings.value?.activeConfig != null,
      ),
    );
    final status = BugStatus.byName(_row.status);
    final techno = context.techno;

    return PageFrame(
      title: 'Dossier',
      actions: [
        IconButton(
          tooltip: 'Supprimer le dossier',
          icon: const Icon(Icons.delete_outline),
          onPressed: _delete,
        ),
      ],
      children: [
        Text(_row.title, style: context.text.titleMedium),
        if (_row.description.isNotEmpty)
          Text(_row.description, style: context.text.bodyMedium),
        if (_row.errorText.isNotEmpty)
          ConsolePanel(
            title: 'Votre message d\'erreur',
            lines: [
              ConsoleLine(
                ConsoleLineKind.output,
                _row.errorText.length > 1500
                    ? '${_row.errorText.substring(0, 1500)}\n[…]'
                    : _row.errorText,
              ),
            ],
          ),
        const SectionTitle('Analyse par l\'IA'),
        TechnoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              if (!hasTeacher)
                Text(
                  'Aucun fournisseur IA n\'est configuré. Les fiches '
                  'ci-dessous restent disponibles.',
                  style: context.text.bodyMedium,
                )
              else ...[
                Text(
                  'L\'IA répond en six parties. Vous pourrez relire ce qui part '
                  'avant l\'envoi.',
                  style: context.text.bodyMedium,
                ),
                ArcaneButton(
                  label: 'Demander une analyse IA',
                  icon: Icons.auto_awesome_outlined,
                  onPressed: () => _askAi(matches),
                ),
              ],
              if (_row.conversationId case final id?)
                TextButton.icon(
                  onPressed: () => context.go(conversationPath(id)),
                  icon: const Icon(Icons.forum_outlined),
                  label: const Text('Ouvrir l\'analyse'),
                ),
            ],
          ),
        ),
        const SectionTitle('Fiches reconnues'),
        Text(
          'Recherche de mots-clés dans des fiches rédigées à l\'avance. Ce '
          'n\'est pas une IA, et elle peut se tromper.',
          style: context.text.bodySmall!.copyWith(color: techno.muted),
        ),
        if (matches.isEmpty)
          Text(
            'Aucune panne connue n\'a été reconnue dans ce texte.',
            style: context.text.bodyMedium,
          )
        else
          for (final (index, rule) in matches.indexed)
            TechnoCard(
              child: ExpansionTile(
                initiallyExpanded: index == 0,
                tilePadding: EdgeInsets.zero,
                title: Text(rule.title, style: context.text.titleSmall),
                subtitle: Text(rule.family.label),
                childrenPadding: const EdgeInsets.only(bottom: 8),
                children: [BugRuleView(rule)],
              ),
            ),
        const SectionTitle('Vérification'),
        TechnoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Text(
                'État : ${status.label}',
                style: context.text.titleSmall!.copyWith(
                  color: switch (status) {
                    BugStatus.verified => techno.emeraude,
                    BugStatus.stillBroken => techno.danger,
                    BugStatus.open => techno.orange,
                  },
                ),
              ),
              Text(
                'Une analyse ne prouve rien. Lancez la procédure de validation, '
                'puis notez ce que vous avez observé.',
                style: context.text.bodySmall,
              ),
              TextField(
                controller: _result,
                minLines: 2,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Résultat de votre vérification',
                  hintText: 'Commande lancée et résultat observé',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ArcaneButton(
                    label: 'La vérification réussit',
                    icon: Icons.check,
                    onPressed: () => _record(BugStatus.verified),
                  ),
                  ArcaneButton(
                    label: 'Toujours en panne',
                    icon: Icons.report_problem_outlined,
                    secondary: true,
                    onPressed: () => _record(BugStatus.stillBroken),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
