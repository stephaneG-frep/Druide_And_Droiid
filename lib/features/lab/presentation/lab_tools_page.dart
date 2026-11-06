import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../design_system/arcane_button.dart';
import '../../../design_system/code_highlighter.dart';
import '../../../design_system/code_panel.dart';
import '../../../design_system/console_panel.dart';
import '../../../design_system/druide_toast.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';
import '../data/lab_platform.dart';
import '../domain/lab_tools.dart';

class LabToolsPage extends ConsumerStatefulWidget {
  const LabToolsPage({super.key});

  @override
  ConsumerState<LabToolsPage> createState() => _LabToolsPageState();
}

class _LabToolsPageState extends ConsumerState<LabToolsPage> {
  LabCommand? _running;
  String? _title;
  List<ConsoleLine> _console = const [];
  List<String> _avds = const [];

  Future<void> _run(LabCommand command) async {
    setState(() => _running = command);
    final result = await ref.read(toolCommandsProvider).run(command);
    if (!mounted) return;
    setState(() {
      _running = null;
      _title = '${command.label} : résultat réel';
      _console = [
        ConsoleLine(
          result.failed ? ConsoleLineKind.error : ConsoleLineKind.output,
          result.output.isEmpty ? '(aucune sortie)' : result.output,
        ),
      ];
      if (command == LabCommand.listAvds && !result.failed) {
        _avds = parseAvds(result.output);
      }
    });
  }

  Future<bool> _confirm(String title, String message) async {
    final accepted = await showDialog<bool>(
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
            child: const Text('Lancer'),
          ),
        ],
      ),
    );
    return accepted ?? false;
  }

  Future<void> _launch(
    String title,
    String message,
    Future<void> Function() action,
  ) async {
    if (!await _confirm(title, message)) return;
    try {
      await action();
      if (mounted) showDruideToast(context, 'Lancement demandé.');
    } on Exception catch (error) {
      debugPrint('Lancement impossible : $error');
      if (mounted) {
        showDruideToast(
          context,
          'Le lancement a échoué.',
          kind: ToastKind.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final capabilities = ref.watch(labCapabilitiesProvider);
    final toolchain = ref.watch(labToolchainProvider);
    final commands = ref.read(toolCommandsProvider);
    final techno = context.techno;

    if (!capabilities.canRunCode) {
      return const PageFrame(
        title: 'Outils Linux',
        children: [
          PhaseNotice(message: 'Ces outils sont disponibles sur Linux.'),
        ],
      );
    }

    return PageFrame(
      title: 'Outils Linux',
      children: [
        Text(
          'Le Lab détecte vos outils et ne lance que les commandes ci-dessous. '
          'Il n\'installe rien à votre place.',
          style: context.text.bodyMedium,
        ),
        for (final tool in LabTool.values)
          TechnoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    Icon(
                      toolchain.has(tool)
                          ? Icons.check_circle
                          : Icons.help_outline,
                      size: 20,
                      color: toolchain.has(tool)
                          ? techno.emeraude
                          : techno.orange,
                    ),
                    Expanded(
                      child: Text(tool.label, style: context.text.titleSmall),
                    ),
                  ],
                ),
                Text(tool.role, style: context.text.bodySmall),
                if (toolchain.path(tool) case final path?)
                  SelectableText(
                    path,
                    style: context.text.bodySmall!.copyWith(
                      color: techno.muted,
                    ),
                  )
                else ...[
                  Text('Non détecté.', style: context.text.bodyMedium),
                  Text(tool.install, style: context.text.bodySmall),
                  CodePanel(code: tool.command, language: CodeLanguage.shell),
                ],
              ],
            ),
          ),
        const SectionTitle('Vérifications'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final command in LabCommand.values)
              if (toolchain.has(command.tool))
                ArcaneButton(
                  label: command.label,
                  secondary: true,
                  onPressed: _running == null ? () => _run(command) : null,
                ),
          ],
        ),
        if (_running != null) const LinearProgressIndicator(),
        if (_title case final title?)
          ConsolePanel(title: title, lines: _console),
        if (toolchain.has(LabTool.androidStudio) || _avds.isNotEmpty)
          const SectionTitle('Lancer une application'),
        if (toolchain.has(LabTool.androidStudio))
          ArcaneButton(
            label: 'Ouvrir Android Studio',
            icon: Icons.open_in_new,
            secondary: true,
            onPressed: () => _launch(
              'Ouvrir Android Studio ?',
              'L\'application démarre à part, avec vos droits.',
              commands.openAndroidStudio,
            ),
          ),
        for (final avd in _avds)
          ArcaneButton(
            label: 'Démarrer $avd',
            icon: Icons.phone_android,
            secondary: true,
            onPressed: () => _launch(
              'Démarrer $avd ?',
              'L\'émulateur utilise beaucoup de mémoire et de processeur.',
              () => commands.startEmulator(avd),
            ),
          ),
      ],
    );
  }
}
