import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/sections.dart';
import '../../../app/theme/app_theme.dart';
import '../../../design_system/adaptive_grid.dart';
import '../../../design_system/arcane_button.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';
import '../../academie/domain/module_catalog.dart';
import '../../academie/presentation/level_color.dart';
import '../data/project_repository.dart';
import '../domain/final_grid.dart';
import '../domain/project.dart';
import 'project_paths.dart';
import '../../grimoire/domain/grimoire_topics.dart';
import '../../grimoire/presentation/help_button.dart';

class ProjetsPage extends ConsumerWidget {
  const ProjetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    final states = ref.watch(projectStatesProvider).value ?? const {};
    final entries = ref.watch(finalEntriesProvider).value ?? const {};

    return PageFrame(
      title: AppSection.projets.label,
      actions: const [HelpButton(GrimoireTopic.projets)],
      children: [
        Text(
          'Vingt projets progressifs pour passer de la théorie à de vraies '
          'applications. Chacun se réalise dans votre propre environnement, '
          'puis se valide ici avec une preuve.',
          style: context.text.bodyLarge,
        ),
        switch (projects) {
          AsyncData(:final value) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              _Summary(projects: value, states: states),
              for (final level in ModuleLevel.values)
                if (value.any((project) => project.level == level)) ...[
                  SectionTitle(level.label),
                  AdaptiveGrid(
                    minItemWidth: 240,
                    children: [
                      for (final project in value)
                        if (project.level == level)
                          _ProjectTile(
                            project,
                            state: states[project.id] ?? const ProjectState(),
                          ),
                    ],
                  ),
                ],
            ],
          ),
          AsyncError() => const ErrorNotice(
            message: 'Les projets n\'ont pas pu être chargés.',
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
        const SectionTitle('Évaluation finale'),
        TechnoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Text(
                'Votre propre application, notée sur 100 avec une preuve pour '
                'chaque critère. Total actuel : '
                '${evaluateFinal(entries).total} sur 100.',
                style: context.text.bodyMedium,
              ),
              ArcaneButton(
                label: 'Ouvrir ma grille',
                icon: Icons.assignment_outlined,
                secondary: true,
                onPressed: () => context.go(finalProjectPath),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.projects, required this.states});

  final List<Project> projects;
  final Map<String, ProjectState> states;

  @override
  Widget build(BuildContext context) {
    final done = projects
        .where((project) => states[project.id]?.completed ?? false)
        .length;
    return Text(
      '$done projets terminés sur ${projects.length}',
      style: context.text.titleSmall,
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile(this.project, {required this.state});

  final Project project;
  final ProjectState state;

  String get _status {
    if (state.completed) return 'Terminé';
    if (!state.started) return project.stack;
    return '${state.doneSteps.length} sur ${project.steps.length} étapes';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(projectPath(project.id)),
      child: TechnoCard(
        child: Row(
          spacing: 12,
          children: [
            Icon(
              state.completed ? Icons.check_circle : Icons.build_outlined,
              color: state.completed
                  ? context.techno.emeraude
                  : levelColor(context, project.level),
              size: 20,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(project.title, style: context.text.bodyMedium),
                  Text(
                    _status,
                    style: context.text.bodySmall!.copyWith(
                      color: context.techno.muted,
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
