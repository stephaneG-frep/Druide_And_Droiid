import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/sections.dart';
import '../../../app/theme/app_theme.dart';
import '../../../design_system/adaptive_grid.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/rune_badge.dart';
import '../../../design_system/techno_card.dart';
import '../../../design_system/xp_bar.dart';
import '../domain/progression.dart';

class ProgressionPage extends ConsumerWidget {
  const ProgressionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final rank = progress.rank;

    return PageFrame(
      title: AppSection.progression.label,
      children: [
        TechnoCard(
          accent: context.techno.emeraude,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Votre grade', style: context.text.bodyMedium),
              Text(rank.title, style: context.text.headlineSmall),
              const SizedBox(height: 12),
              XpBar(
                xp: progress.xp,
                floor: rank.minXp,
                ceiling: rank.next?.minXp ?? rank.minXp,
              ),
            ],
          ),
        ),
        const PhaseNotice(
          message:
              'Le gain d\'expérience et les défis ne sont pas encore '
              'actifs. Les seuils des grades sont provisoires.',
        ),
        const SectionTitle('Les huit grades'),
        AdaptiveGrid(
          minItemWidth: 130,
          maxColumns: 4,
          children: [
            for (final grade in Rank.values)
              RuneBadge(
                icon: grade.icon,
                label: grade.title,
                caption: '${grade.minXp} XP',
                unlocked: progress.xp >= grade.minXp,
              ),
          ],
        ),
      ],
    );
  }
}
