import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/sections.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/persistence/app_database.dart';
import '../../../design_system/arcane_button.dart';
import '../../../design_system/code_highlighter.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';
import '../data/lab_platform.dart';
import '../data/lab_repository.dart';
import '../domain/lab_exercise.dart';
import 'lab_paths.dart';

class LabPage extends ConsumerWidget {
  const LabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(labExercisesProvider);
    final drafts = ref.watch(labDraftsProvider).value ?? const {};
    final canRun = ref.watch(labCapabilitiesProvider).canRunCode;

    return PageFrame(
      title: AppSection.lab.label,
      children: [
        Text(
          canRun
              ? 'Votre paillasse de code : écrivez, exécutez avec les vrais '
                    'compilateurs de cette machine, puis comparez.'
              : 'Votre paillasse de code : écrivez, enregistrez, comparez et '
                    'exportez.',
          style: context.text.bodyLarge,
        ),
        if (!canRun)
          const PhaseNotice(
            message:
                'Sur téléphone, le code Kotlin, Java et Dart ne s\'exécute '
                'pas : aucun compilateur n\'y tourne. Le Lab ne simule rien. '
                'Comparez avec le corrigé, ou lancez le code sur Linux. Le XML '
                'est réellement analysé.',
          ),
        if (canRun)
          ArcaneButton(
            label: 'Outils Linux',
            icon: Icons.build_outlined,
            secondary: true,
            onPressed: () => context.go(labToolsPath),
          ),
        switch (exercises) {
          AsyncData(:final value) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              for (final language in labLanguages)
                _LanguageSection(
                  language: language,
                  exercises: value
                      .where((exercise) => exercise.language == language)
                      .toList(),
                  drafts: drafts,
                ),
            ],
          ),
          AsyncError() => const ErrorNotice(
            message: 'Les exercices du Lab n\'ont pas pu être chargés.',
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ],
    );
  }
}

class _LanguageSection extends StatelessWidget {
  const _LanguageSection({
    required this.language,
    required this.exercises,
    required this.drafts,
  });

  final CodeLanguage language;
  final List<LabExercise> exercises;
  final Map<String, LabDraft> drafts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        SectionTitle(language.label),
        for (final exercise in exercises)
          _ExerciseTile(exercise, draft: drafts[exercise.id]),
        _ExerciseTile(
          LabExercise.free(language),
          draft: drafts['libre-${language.name}'],
        ),
      ],
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile(this.exercise, {required this.draft});

  final LabExercise exercise;
  final LabDraft? draft;

  @override
  Widget build(BuildContext context) {
    final techno = context.techno;
    final solved = draft?.solved ?? false;

    return InkWell(
      onTap: () => context.go(labEditorPath(exercise.id)),
      child: TechnoCard(
        child: Row(
          spacing: 12,
          children: [
            Icon(
              exercise.isFree
                  ? Icons.edit_note
                  : solved
                  ? Icons.check_circle
                  : Icons.science_outlined,
              color: solved ? techno.emeraude : techno.cyan,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise.title, style: context.text.titleSmall),
                  Text(
                    solved ? '${exercise.level} · réussi' : exercise.level,
                    style: context.text.bodySmall!.copyWith(
                      color: techno.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
