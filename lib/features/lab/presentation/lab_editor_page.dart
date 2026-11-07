import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/sections.dart';
import '../../../app/shell/not_found_page.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/autosave.dart';
import '../../../core/persistence/app_database.dart';
import '../../../design_system/arcane_button.dart';
import '../../../design_system/code_highlighter.dart';
import '../../../design_system/console_panel.dart';
import '../../../design_system/druide_toast.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';
import '../../academie/presentation/lesson_blocks.dart';
import '../../maitre/data/ai_settings_repository.dart';
import '../../maitre/presentation/ai_actions.dart';
import '../../progression/presentation/reward_toast.dart';
import '../data/code_runner.dart';
import '../data/lab_platform.dart';
import '../data/lab_repository.dart';
import '../domain/lab_checks.dart';
import '../domain/lab_exercise.dart';
import 'code_editor.dart';
import 'diff_view.dart';

class LabDraftSaver extends Autosaver {
  LabDraftSaver(this._repository, this.exerciseId, this.code)
    : super(debounce: const Duration(milliseconds: 300));

  final LabRepository _repository;
  final String exerciseId;
  String code;

  void update(String text) {
    code = text;
    markDirty();
  }

  @override
  Future<bool> persist() async {
    await _repository.saveDraft(exerciseId, code);
    return true;
  }
}

LabExercise? _freeSheet(String id) {
  for (final language in labLanguages) {
    final free = LabExercise.free(language);
    if (free.id == id) return free;
  }
  return null;
}

class LabEditorPage extends ConsumerWidget {
  const LabEditorPage({required this.exerciseId, super.key});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(labExercisesProvider);
    final uri = GoRouterState.of(context).uri;

    return switch (exercises) {
      AsyncData(:final value) => () {
        final exercise =
            value.where((item) => item.id == exerciseId).firstOrNull ??
            _freeSheet(exerciseId);
        return exercise == null
            ? NotFoundPage(uri: uri)
            : _Editor(key: ValueKey(exercise.id), exercise: exercise);
      }(),
      AsyncError() => PageFrame(
        title: 'Lab',
        children: const [
          ErrorNotice(message: 'Cet exercice n\'a pas pu être chargé.'),
        ],
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({required this.exercise, super.key});

  final LabExercise exercise;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> with WidgetsBindingObserver {
  late final _code = CodeEditingController(language: widget.exercise.language);
  late final LabDraftSaver _saver;
  bool _loaded = false;
  bool _running = false;
  RunCancel? _cancel;
  String? _step;
  String _consoleTitle = '';
  List<ConsoleLine> _console = const [];

  LabExercise get _exercise => widget.exercise;
  LabRepository get _repository => ref.read(labRepositoryProvider);
  bool get _isXml => _exercise.language == CodeLanguage.xml;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _saver = LabDraftSaver(
      ref.read(labRepositoryProvider),
      _exercise.id,
      _exercise.starter,
    );
    unawaited(_load());
  }

  Future<void> _load() async {
    final draft = await _repository.draft(_exercise.id);
    if (!mounted) return;
    setState(() {
      _code.text = draft?.code ?? _exercise.starter;
      _saver.code = _code.text;
      _loaded = true;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(_saver.flush());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancel?.cancel();
    unawaited(_saver.flush().whenComplete(_saver.dispose));
    _code.dispose();
    super.dispose();
  }

  void _showConsole(String title, List<ConsoleLine> lines) {
    setState(() {
      _consoleTitle = title;
      _console = lines;
    });
  }

  Future<void> _markSolved() async {
    await _repository.markSolved(_exercise.id, _code.text);
    if (mounted) {
      showDruideToast(context, 'Exercice réussi !');
      await rewardAndCelebrate(context, ref);
    }
  }

  Future<void> _checkXml() async {
    final check = checkXml(_code.text, _exercise.required);
    final lines = <ConsoleLine>[
      if (check.wellFormed)
        const ConsoleLine(ConsoleLineKind.success, 'XML bien formé.')
      else
        ConsoleLine(ConsoleLineKind.error, 'XML invalide : ${check.error}'),
      for (final element in check.missing)
        ConsoleLine(ConsoleLineKind.error, 'Élément attendu : $element'),
    ];
    _showConsole('Analyse réelle du XML, sans compilation Android', lines);
    if (check.complete && !_exercise.isFree) await _markSolved();
  }

  Future<bool> _confirmRun() async {
    if (await _repository.runAcknowledged()) return true;
    if (!mounted) return false;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exécuter du code sur cet ordinateur ?'),
        content: const Text(
          'Le code s\'exécute avec vos droits : il pourrait lire ou effacer '
          'vos fichiers. Le Lab limite sa durée et sa sortie, mais ce n\'est '
          'pas un bac à sable.\n\n'
          'N\'exécutez que du code que vous avez lu et compris, y compris '
          'celui proposé par une IA.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('J\'ai compris'),
          ),
        ],
      ),
    );
    if (accepted != true) return false;
    await _repository.acknowledgeRun();
    return true;
  }

  Future<void> _run() async {
    if (!await _confirmRun() || !mounted) return;
    await _saver.flush();
    await _repository.addRevision(_exercise.id, _code.text, 'Avant exécution');

    final cancel = RunCancel();
    setState(() {
      _running = true;
      _cancel = cancel;
      _step = 'Préparation…';
      _console = const [];
    });
    final result = await ref
        .read(codeRunnerProvider)
        .run(
          _exercise,
          _code.text,
          cancel: cancel,
          onStep: (step) {
            if (mounted) setState(() => _step = step);
          },
        );
    if (!mounted) return;
    setState(() {
      _running = false;
      _cancel = null;
      _step = null;
    });
    await _report(result);
  }

  Future<void> _report(RunResult result) async {
    final expected = _exercise.expectedOutput;
    final matches =
        expected != null &&
        result.succeeded &&
        outputMatches(result.output, expected);
    final lines = <ConsoleLine>[
      if (result.unavailable case final reason?)
        ConsoleLine(ConsoleLineKind.error, reason),
      if (result.output.isNotEmpty)
        ConsoleLine(ConsoleLineKind.output, result.output.trimRight()),
      if (result.errors.isNotEmpty)
        ConsoleLine(ConsoleLineKind.error, result.errors),
      if (result.compileFailed)
        const ConsoleLine(ConsoleLineKind.error, 'La compilation a échoué.'),
      if (result.timedOut)
        const ConsoleLine(
          ConsoleLineKind.error,
          'Arrêté : le programme a dépassé le temps autorisé.',
        ),
      if (result.truncated)
        const ConsoleLine(
          ConsoleLineKind.error,
          'Arrêté : le programme écrit trop de texte.',
        ),
      if (result.cancelled)
        const ConsoleLine(ConsoleLineKind.error, 'Exécution arrêtée.'),
      if (!result.succeeded &&
          !result.compileFailed &&
          result.exitCode != null &&
          !result.timedOut &&
          !result.truncated &&
          !result.cancelled)
        ConsoleLine(
          ConsoleLineKind.error,
          'Le programme s\'est arrêté avec le code ${result.exitCode}.',
        ),
      if (matches)
        const ConsoleLine(
          ConsoleLineKind.success,
          'La sortie correspond à la sortie attendue.',
        )
      else if (expected != null && result.succeeded) ...[
        const ConsoleLine(
          ConsoleLineKind.error,
          'La sortie diffère de la sortie attendue :',
        ),
        ConsoleLine(ConsoleLineKind.output, expected),
      ],
    ];
    _showConsole('Résultat réel de l\'exécution', lines);
    if (matches) await _markSolved();
  }

  Future<void> _saveVersion() async {
    await _repository.addRevision(
      _exercise.id,
      _code.text,
      'Version enregistrée',
    );
    if (mounted) showDruideToast(context, 'Version enregistrée.');
  }

  Future<void> _restore(String code, String label) async {
    await _repository.addRevision(
      _exercise.id,
      _code.text,
      'Avant retour en arrière',
    );
    _code.text = code;
    _saver.update(code);
    if (mounted) showDruideToast(context, label);
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revenir au code de départ ?'),
        content: const Text(
          'Votre code actuel restera disponible dans l\'historique.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _restore(_exercise.starter, 'Code de départ rétabli.');
    }
  }

  Future<void> _export() async {
    try {
      final path = await ref
          .read(codeExporterProvider)
          .export(_exercise.fileName, _code.text);
      if (path != null && mounted) {
        showDruideToast(context, 'Exporté : $path');
      }
    } on Exception catch (error) {
      debugPrint('Export impossible : $error');
      if (mounted) {
        showDruideToast(
          context,
          'Le fichier n\'a pas pu être exporté.',
          kind: ToastKind.error,
        );
      }
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _code.text));
    if (mounted) showDruideToast(context, 'Code copié.');
  }

  void _showSheet(Widget Function(BuildContext context) builder) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        builder: (context, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [builder(context)],
        ),
      ),
    );
  }

  Future<void> _compareWithSolution() async {
    final solution = _exercise.solution;
    if (solution == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Afficher le corrigé ?'),
        content: const Text(
          'Il vaut mieux chercher un peu avant de le regarder. D\'autres '
          'solutions peuvent aussi être justes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuer à chercher'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Afficher'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _showSheet(
      (context) => DiffView(
        before: _code.text,
        after: solution,
        beforeLabel: 'Votre code',
        afterLabel: 'Corrigé',
      ),
    );
  }

  void _showHistory() {
    _showSheet(
      (context) => _History(
        exerciseId: _exercise.id,
        current: _code.text,
        onRestore: (revision) {
          Navigator.pop(context);
          unawaited(_restore(revision.code, 'Version rétablie.'));
        },
      ),
    );
  }

  void _askTeacher() {
    if (_exercise.isFree) {
      unawaited(
        askForReview(
          context,
          ref,
          language: _exercise.language.name,
          code: _code.text,
        ),
      );
    } else {
      unawaited(
        askForCorrection(
          context,
          ref,
          statement: _exercise.statement,
          answer: _code.text,
          reference: _exercise.solution!,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final capabilities = ref.watch(labCapabilitiesProvider);
    final hasTeacher = ref.watch(
      aiSettingsProvider.select(
        (settings) => settings.value?.activeConfig != null,
      ),
    );
    final solved =
        ref.watch(labDraftsProvider).value?[_exercise.id]?.solved ?? false;
    final canRun = capabilities.canRunCode && !_isXml;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppSection.lab.path)),
        title: Text(_exercise.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RichLessonText(_exercise.statement, style: context.text.bodyLarge),
          if (solved) ...[
            const SizedBox(height: 8),
            Text(
              'Exercice réussi.',
              style: context.text.titleSmall!.copyWith(
                color: context.techno.emeraude,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_loaded)
            CodeEditor(controller: _code, onChanged: _saver.update)
          else
            const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_isXml)
                ArcaneButton(
                  label: 'Analyser le XML',
                  icon: Icons.rule,
                  onPressed: _checkXml,
                ),
              if (canRun && !_running)
                ArcaneButton(
                  label: 'Exécuter',
                  icon: Icons.play_arrow,
                  onPressed: _run,
                ),
              if (_running)
                ArcaneButton(
                  label: 'Arrêter',
                  icon: Icons.stop,
                  secondary: true,
                  onPressed: () => _cancel?.cancel(),
                ),
              if (!canRun && !_isXml && !_exercise.isFree && !solved)
                ArcaneButton(
                  label: 'Je valide moi-même',
                  icon: Icons.check,
                  secondary: true,
                  onPressed: _markSolved,
                ),
            ],
          ),
          if (!canRun && !_isXml) ...[
            const SizedBox(height: 8),
            Text(
              'L\'exécution n\'est pas disponible sur cette plateforme.',
              style: context.text.bodySmall!.copyWith(
                color: context.techno.muted,
              ),
            ),
          ],
          if (_step case final step?) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
            const SizedBox(height: 4),
            Text(step, style: context.text.bodySmall),
          ],
          if (_console.isNotEmpty) ...[
            const SizedBox(height: 12),
            ConsolePanel(title: _consoleTitle, lines: _console),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 4,
            children: [
              if (!_exercise.isFree)
                TextButton.icon(
                  onPressed: _compareWithSolution,
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('Comparer au corrigé'),
                ),
              if (hasTeacher)
                TextButton.icon(
                  onPressed: _askTeacher,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: Text(
                    _exercise.isFree
                        ? 'Relecture par le Maître'
                        : 'Corriger avec le Maître',
                  ),
                ),
              TextButton.icon(
                onPressed: _saveVersion,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Enregistrer une version'),
              ),
              TextButton.icon(
                onPressed: _showHistory,
                icon: const Icon(Icons.history),
                label: const Text('Historique'),
              ),
              TextButton.icon(
                onPressed: _export,
                icon: const Icon(Icons.save_alt),
                label: const Text('Exporter'),
              ),
              TextButton.icon(
                onPressed: _copy,
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copier'),
              ),
              TextButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Réinitialiser'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _History extends ConsumerWidget {
  const _History({
    required this.exerciseId,
    required this.current,
    required this.onRestore,
  });

  final String exerciseId;
  final String current;
  final ValueChanged<LabRevisionRow> onRestore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revisions = ref.watch(labRevisionsProvider(exerciseId));
    final list = revisions.value ?? const <LabRevisionRow>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Text('Historique', style: context.text.titleMedium),
        if (list.isEmpty)
          const Text('Aucune version enregistrée pour l\'instant.'),
        for (final revision in list)
          TechnoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                Text(revision.label, style: context.text.titleSmall),
                Text(
                  _date(revision.createdAt),
                  style: context.text.bodySmall!.copyWith(
                    color: context.techno.muted,
                  ),
                ),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Comparer à mon code actuel'),
                  children: [
                    DiffView(
                      before: revision.code,
                      after: current,
                      beforeLabel: 'Cette version',
                      afterLabel: 'Code actuel',
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => onRestore(revision),
                    icon: const Icon(Icons.restore),
                    label: const Text('Revenir à cette version'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _date(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} à '
        '${two(date.hour)}:${two(date.minute)}';
  }
}
