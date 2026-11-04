import 'package:flutter/material.dart';

import '../../../app/sections.dart';
import '../../../app/theme/app_theme.dart';
import '../../../design_system/adaptive_grid.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';
import '../../academie/presentation/level_color.dart';
import '../domain/project_catalog.dart';

class ProjetsPage extends StatelessWidget {
  const ProjetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: AppSection.projets.label,
      children: [
        Text(
          'Vingt projets progressifs pour passer de la théorie à de vraies '
          'applications.',
          style: context.text.bodyLarge,
        ),
        const PhaseNotice(
          message:
              'Les fiches de projet (étapes, code, tests et critères de '
              'réussite) ne sont pas encore disponibles.',
        ),
        for (final track in projectTracks) ...[
          SectionTitle(track.level.label),
          AdaptiveGrid(
            minItemWidth: 240,
            children: [
              for (final project in track.projects)
                TechnoCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.build_outlined,
                        color: levelColor(context, track.level),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(project, style: context.text.bodyMedium),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
