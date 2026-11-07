import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/sections.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/persistence/app_database.dart';
import '../../../design_system/arcane_button.dart';
import '../../../design_system/dialogue_bubble.dart';
import '../../../design_system/druide_toast.dart';
import '../../../design_system/mascot/maitre_and_droiid.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';
import '../../lab/data/lab_platform.dart';
import '../../lab/domain/lab_tools.dart';
import '../data/bug_repository.dart';
import '../data/log_importer.dart';
import '../domain/bug_rule.dart';
import '../domain/log_tools.dart';
import 'chaudron_paths.dart';
import '../../grimoire/domain/grimoire_topics.dart';
import '../../grimoire/presentation/help_button.dart';

class ChaudronPage extends ConsumerStatefulWidget {
  const ChaudronPage({super.key});

  @override
  ConsumerState<ChaudronPage> createState() => _ChaudronPageState();
}

class _ChaudronPageState extends ConsumerState<ChaudronPage> {
  final _error = TextEditingController();
  final _description = TextEditingController();
  final _code = TextEditingController();
  String? _imported;
  bool _busy = false;

  @override
  void dispose() {
    _error.dispose();
    _description.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    setState(() => _busy = true);
    try {
      final log = await ref.read(logImporterProvider).pick();
      if (log != null && mounted) {
        setState(() {
          _error.text = log.text;
          _imported = log.truncated
              ? '${log.name} : fichier long, seule sa fin a été lue.'
              : log.name;
        });
      }
    } on Exception catch (error) {
      debugPrint('Import impossible : $error');
      if (mounted) {
        showDruideToast(
          context,
          'Ce fichier n\'a pas pu être lu.',
          kind: ToastKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importCrashes() async {
    setState(() => _busy = true);
    final result = await ref
        .read(toolCommandsProvider)
        .run(LabCommand.adbCrashLog);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!result.failed) {
        _error.text = result.output;
        _imported = 'Tampon des plantages de l\'appareil (adb logcat)';
      }
    });
    if (result.failed) {
      showDruideToast(context, result.output, kind: ToastKind.error);
    }
  }

  Future<void> _open() async {
    final error = _error.text.trim();
    final description = _description.text.trim();
    final code = _code.text.trim();
    if (error.isEmpty && description.isEmpty) {
      showDruideToast(
        context,
        'Collez une erreur ou décrivez le problème.',
        kind: ToastKind.error,
      );
      return;
    }
    final id = await ref
        .read(bugRepositoryProvider)
        .create(errorText: error, description: description, code: code);
    if (!mounted) return;
    _error.clear();
    _description.clear();
    _code.clear();
    setState(() => _imported = null);
    context.go(bugCasePath(id));
  }

  @override
  Widget build(BuildContext context) {
    final cases = ref.watch(bugCasesProvider);
    final canUseAdb =
        ref.watch(labCapabilitiesProvider).canRunCode &&
        ref.watch(labToolchainProvider).has(LabTool.adb);

    return PageFrame(
      title: AppSection.chaudron.label,
      actions: const [HelpButton(GrimoireTopic.logs)],
      children: [
        const DialogueBubble(
          origin: 'Message préenregistré',
          mood: MascotMood.pensif,
          message:
              'Un bug qui bouillonne ? Jetez-le dans mon chaudron, et '
              'examinons-le ensemble.',
        ),
        TechnoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              TextField(
                controller: _error,
                minLines: 3,
                maxLines: 10,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Message d\'erreur ou journal',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              if (_imported case final name?)
                Text('Importé : $name', style: context.text.bodySmall),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ArcaneButton(
                    label: 'Importer un fichier',
                    icon: Icons.upload_file,
                    secondary: true,
                    onPressed: _busy ? null : _import,
                  ),
                  if (canUseAdb)
                    ArcaneButton(
                      label: 'Lire les plantages (ADB)',
                      icon: Icons.phone_android,
                      secondary: true,
                      onPressed: _busy ? null : _importCrashes,
                    ),
                ],
              ),
              TextField(
                controller: _description,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Que se passe-t-il ?',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              TextField(
                controller: _code,
                minLines: 2,
                maxLines: 8,
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(fontFamily: fontCode, fontSize: 13.5),
                decoration: const InputDecoration(
                  labelText: 'Extrait de code (facultatif)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              ArcaneButton(
                label: 'Jeter dans le chaudron',
                icon: Icons.science_outlined,
                onPressed: _open,
              ),
            ],
          ),
        ),
        const SectionTitle('Diagnostics guidés'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final family in BugFamily.values)
              ActionChip(
                label: Text(family.label),
                onPressed: () => context.go(bugGuidePath(family)),
              ),
          ],
        ),
        const SectionTitle('Mes dossiers'),
        switch (cases) {
          AsyncData(:final value) when value.isEmpty => Text(
            'Aucun dossier pour l\'instant.',
            style: context.text.bodyMedium!.copyWith(
              color: context.techno.muted,
            ),
          ),
          AsyncData(:final value) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [for (final row in value) _CaseTile(row)],
          ),
          AsyncError() => const ErrorNotice(
            message: 'Les dossiers n\'ont pas pu être chargés.',
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ],
    );
  }
}

class _CaseTile extends StatelessWidget {
  const _CaseTile(this.row);

  final BugCaseRow row;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(bugCasePath(row.id)),
      child: TechnoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              row.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleSmall,
            ),
            Text(
              BugStatus.byName(row.status).label,
              style: context.text.bodySmall!.copyWith(
                color: context.techno.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
