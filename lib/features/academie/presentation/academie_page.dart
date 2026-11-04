import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/sections.dart';
import '../../../app/theme/app_theme.dart';
import '../../../design_system/adaptive_grid.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';
import '../data/favorites_repository.dart';
import '../domain/module_catalog.dart';
import 'level_color.dart';

class AcademiePage extends ConsumerWidget {
  const AcademiePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteModulesProvider).value ?? const {};

    return PageFrame(
      title: AppSection.academie.label,
      children: [
        Text(
          'Douze modules pour aller de zéro à expert. Consultez le programme '
          'de chacun.',
          style: context.text.bodyLarge,
        ),
        const PhaseNotice(
          message:
              'Les leçons, quiz et exercices sont en cours de rédaction : '
              'seuls les programmes sont disponibles pour l\'instant.',
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
class CourseCard extends StatelessWidget {
  const CourseCard({required this.module, super.key});

  final AcademyModule module;

  @override
  Widget build(BuildContext context) {
    final techno = context.techno;
    final color = levelColor(context, module.level);

    return TechnoCard(
      onTap: () => context.go('${AppSection.academie.path}/${module.id}'),
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
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
