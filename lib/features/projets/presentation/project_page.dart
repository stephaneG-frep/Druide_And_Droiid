import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/shell/not_found_page.dart';
import '../../../app/theme/app_theme.dart';
import '../../../design_system/arcane_button.dart';
import '../../../design_system/code_panel.dart';
import '../../../design_system/console_panel.dart';
import '../../../design_system/druide_toast.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';
import '../../academie/domain/module_catalog.dart';
import '../../academie/presentation/lesson_blocks.dart';
import '../../academie/presentation/paths.dart';
import '../../academie/presentation/quiz_runner.dart';
import '../../maitre/data/ai_settings_repository.dart';
import '../../maitre/domain/teaching.dart';
import '../../maitre/presentation/ai_actions.dart';
import '../../progression/presentation/reward_toast.dart';
import '../data/project_repository.dart';
import '../domain/project.dart';
import '../../sauvegarde/presentation/pdf_action.dart';
import '../../sauvegarde/data/document_exports.dart';
import '../../grimoire/domain/grimoire_topics.dart';
import '../../grimoire/presentation/help_button.dart';

const _passPercent = 80;

class ProjectPage extends ConsumerWidget {
  const ProjectPage({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);

    return switch (projects) {
      AsyncData(:final value) => () {
        final project = value.where((item) => item.id == projectId).firstOrNull;
        return project == null
            ? NotFoundPage(uri: GoRouterState.of(context).uri)
            : _ProjectContent(key: ValueKey(project.id), project: project);
      }(),
      AsyncError() => const PageFrame(
        title: 'Projet',
        children: [ErrorNotice(message: 'Ce projet n\'a pas pu être chargé.')],
      ),
      _ => const PageFrame(
        title: 'Projet',
        children: [Center(child: CircularProgressIndicator())],
      ),
    };
  }
}

class _ProjectContent extends ConsumerStatefulWidget {
  const _ProjectContent({required this.project, super.key});

  final Project project;

  @override
  ConsumerState<_ProjectContent> createState() => _ProjectContentState();
}

class _ProjectContentState extends ConsumerState<_ProjectContent> {
  final _proof = TextEditingController();
  bool _proofLoaded = false;

  Project get _project => widget.project;
  ProjectRepository get _repository => ref.read(projectRepositoryProvider);

  @override
  void dispose() {
    _proof.dispose();
    super.dispose();
  }

  Future<void> _saveProof() async {
    await _repository.saveProof(_project.id, _proof.text.trim());
    if (mounted) showDruideToast(context, 'Preuve enregistrée.');
  }

  Future<void> _complete(ProjectState state) async {
    await _repository.saveProof(_project.id, _proof.text.trim());
    final saved = await _repository.read(_project.id);
    final missing = saved.missing(_project);
    if (!mounted) return;
    if (missing.isNotEmpty) {
      showDruideToast(
        context,
        'Il manque : ${missing.join(', ')}.',
        kind: ToastKind.error,
      );
      return;
    }
    await _repository.complete(_project);
    if (mounted) {
      showDruideToast(context, 'Projet terminé, bravo !');
      await rewardAndCelebrate(context, ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(projectStatesProvider).value?[_project.id] ??
        const ProjectState();
    final hasTeacher = ref.watch(
      aiSettingsProvider.select(
        (settings) => settings.value?.activeConfig != null,
      ),
    );
    if (!_proofLoaded && ref.watch(projectStatesProvider).hasValue) {
      _proofLoaded = true;
      _proof.text = state.proof;
    }
    final techno = context.techno;
    final modules = [for (final id in _project.modules) ?moduleById(id)];

    return PageFrame(
      title: _project.title,
      actions: [
        PdfExportButton(
          fileName: 'projet-${_project.id}.pdf',
          build: (ref) =>
              ref.read(pdfExporterProvider).project(_project, state),
        ),
        const HelpButton(GrimoireTopic.projets),
      ],
      children: [
        TechnoTag(label: _project.stack, color: techno.cyan),
        const SectionTitle('Objectif'),
        Text(_project.objective, style: context.text.bodyLarge),
        const SectionTitle('Prérequis'),
        for (final item in _project.prerequisites)
          RichLessonText('• $item', style: context.text.bodyMedium),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final module in modules)
              ActionChip(
                label: Text(module.title),
                onPressed: () => context.go(modulePath(module.id)),
              ),
          ],
        ),
        const PhaseNotice(
          message:
              'Ce projet se réalise dans Android Studio ou votre éditeur, pas '
              'dans cette application. Elle vous guide et garde votre suivi.',
        ),
        const SectionTitle('Étapes'),
        for (final (index, step) in _project.steps.indexed)
          _StepCard(
            number: index + 1,
            step: step,
            done: state.doneSteps.contains(index),
            onToggle: () => _repository.toggleStep(_project.id, index),
          ),
        const SectionTitle('Test'),
        RichLessonText(_project.testIntro, style: context.text.bodyMedium),
        CodePanel(code: _project.test.code, language: _project.test.language),
        if (_project.test.output case final output?)
          ConsolePanel(
            title: 'Sortie attendue, vérifiée à la rédaction',
            lines: [ConsoleLine(ConsoleLineKind.output, output)],
          ),
        const SectionTitle('Questionnaire'),
        if (state.quizPassed)
          Text(
            'Questionnaire réussi.',
            style: context.text.titleSmall!.copyWith(color: techno.emeraude),
          ),
        QuizRunner(
          questions: _project.quiz,
          passPercent: _passPercent,
          onSubmitted: (score) {
            final total = _project.quiz.length;
            final passed = score * 100 >= total * _passPercent;
            if (passed || !state.quizPassed) {
              _repository.setQuizPassed(_project.id, passed: passed);
            }
          },
        ),
        const SectionTitle('Critères de réussite'),
        TechnoCard(
          child: Column(
            children: [
              for (final (index, criterion) in _project.criteria.indexed)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: state.doneCriteria.contains(index),
                  title: RichLessonText(
                    criterion,
                    style: context.text.bodyMedium,
                  ),
                  onChanged: (_) =>
                      _repository.toggleCriterion(_project.id, index),
                ),
            ],
          ),
        ),
        const SectionTitle('Validation'),
        TechnoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Text(
                'Cette validation repose sur votre honnêteté : l\'application '
                'ne peut pas juger votre code. Notez une preuve consultable.',
                style: context.text.bodySmall,
              ),
              TextField(
                controller: _proof,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Preuve',
                  hintText: 'Adresse du dépôt, résultat des tests…',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              TextButton(
                onPressed: _saveProof,
                child: const Text('Enregistrer la preuve'),
              ),
              if (state.completed)
                Text(
                  'Projet terminé (autoévaluation).',
                  style: context.text.titleSmall!.copyWith(
                    color: techno.emeraude,
                  ),
                )
              else
                ArcaneButton(
                  label: 'Valider le projet',
                  icon: Icons.verified_outlined,
                  onPressed: () => _complete(state),
                ),
              if (hasTeacher)
                TextButton.icon(
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('Demander au Maître'),
                  onPressed: () => openNewConversation(
                    context,
                    ref,
                    TeachingMode.project,
                    question:
                        'Aide-moi à avancer sur le projet « ${_project.title} ».',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.step,
    required this.done,
    required this.onToggle,
  });

  final int number;
  final ProjectStep step;
  final bool done;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TechnoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Text('$number. ${step.title}', style: context.text.titleSmall),
          RichLessonText(step.text, style: context.text.bodyMedium),
          if (step.code case final code?)
            CodePanel(code: code.code, language: code.language),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: done,
            title: RichLessonText(
              'Vérifié : ${step.verify}',
              style: context.text.bodySmall,
            ),
            onChanged: (_) => onToggle(),
          ),
        ],
      ),
    );
  }
}
