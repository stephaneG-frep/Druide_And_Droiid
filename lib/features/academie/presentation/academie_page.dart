import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/sections.dart';
import '../../../app/theme/app_theme.dart';
import '../../../design_system/adaptive_grid.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';
import '../../../design_system/xp_bar.dart';
import '../../progression/data/progress_repository.dart';
import '../data/course_repository.dart';
import '../data/favorites_repository.dart';
import '../domain/module_catalog.dart';
import '../domain/rewards.dart';
import 'level_color.dart';
import 'paths.dart';

/// Texte annonçant les modules déjà rédigés.
String pendingMessage(List<int> numbers) {
  if (numbers.isEmpty) return 'Les leçons sont en cours de rédaction.';
  final last = numbers.last;
  final where = numbers.length == 1
      ? 'le module $last'
      : 'les modules ${numbers.sublist(0, numbers.length - 1).join(', ')} '
            'et $last';
  return 'Des leçons sont disponibles dans $where. Pour les autres, seul le '
      'programme est consultable.';
}

class AcademiePage extends ConsumerWidget {
  const AcademiePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteModulesProvider).value ?? const {};
    final available = ref.watch(availableModulesProvider).value;

    return PageFrame(
      title: AppSection.academie.label,
      children: [
        Text(
          'Douze modules pour aller de zéro à expert. Consultez le programme '
          'de chacun.',
          style: context.text.bodyLarge,
        ),
        if (available != null && available.length < academyModules.length)
          PhaseNotice(
            message: pendingMessage([
              for (final module in academyModules)
                if (available.contains(module.id)) module.number,
            ]),
          ),
        if (favorites.isNotEmpty) ...[
          const SectionTitle('Vos favoris'),
          AdaptiveGrid(
            minItemWidth: 300,
            children: [
              for (final module in academyModules)
                if (favorites.contains(module.id)) CourseCard(module: module),
            ],
          ),
          const SectionTitle('Tous les modules'),
        ],
        AdaptiveGrid(
          minItemWidth: 300,
          children: [
            for (final module in academyModules) CourseCard(module: module),
          ],
        ),
      ],
    );
  }
}

/// Carte de cours d'un module.
class CourseCard extends ConsumerWidget {
  const CourseCard({required this.module, super.key});

  final AcademyModule module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final techno = context.techno;
    final color = levelColor(context, module.level);
    final course = ref.watch(courseProvider(module.id)).value?.course;
    final completed = ref.watch(completedLessonsProvider).value ?? const {};
    final best = ref.watch(bestAttemptsProvider).value ?? const {};
    final validated = best[evaluationQuizId(module.id)]?.passed ?? false;

    return TechnoCard(
      onTap: () => context.go(modulePath(module.id)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Text(
              module.number.toString().padLeft(2, '0'),
              style: context.text.headlineMedium!.copyWith(color: color),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(module.title, style: context.text.titleMedium),
                const SizedBox(height: 4),
                Text(
                  module.summary,
                  style: context.text.bodySmall!.copyWith(color: techno.muted),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    TechnoTag(label: module.level.label, color: color),
                    TechnoTag(
                      label: '${module.topics.length} notions',
                      color: techno.muted,
                    ),
                    if (validated)
                      TechnoTag(label: 'Validé', color: techno.emeraude),
                  ],
                ),
                if (course != null) ...[
                  const SizedBox(height: 8),
                  StepProgress(
                    done: course.lessons
                        .where((lesson) => completed.contains(lesson.id))
                        .length,
                    total: course.lessons.length,
                    unit: 'leçons',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
