import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';
import '../domain/module_catalog.dart';
import 'level_color.dart';

/// Programme d'un module. Les leçons elles-mêmes arrivent en phases 4 et 5.
class ModulePage extends StatelessWidget {
  const ModulePage({required this.module, super.key});

  final AcademyModule module;

  @override
  Widget build(BuildContext context) {
    final techno = context.techno;

    return PageFrame(
      title: 'Module ${module.number}',
      children: [
        Text(module.title, style: context.text.headlineSmall),
        Text(module.summary, style: context.text.bodyLarge),
        Align(
          alignment: Alignment.centerLeft,
          child: TechnoTag(
            label: module.level.label,
            color: levelColor(context, module.level),
          ),
        ),
        const SectionTitle('Au programme'),
        TechnoCard(
          child: Column(
            children: [
              for (final topic in module.topics)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome, size: 18, color: techno.cyan),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(topic, style: context.text.bodyMedium),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const PhaseNotice(
          message: 'Les leçons de ce module ne sont pas encore rédigées.',
        ),
      ],
    );
  }
}
