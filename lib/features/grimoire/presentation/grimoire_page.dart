import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/sections.dart';
import '../../../app/theme/app_theme.dart';
import '../../../design_system/grimoire_panel.dart';
import '../../../design_system/page_frame.dart';
import '../domain/grimoire_topics.dart';

class GrimoirePage extends StatelessWidget {
  const GrimoirePage({super.key});

  @override
  Widget build(BuildContext context) {
    final requested = GrimoireTopic.byName(
      GoRouterState.of(context).uri.queryParameters['sujet'],
    );
    final open = requested ?? GrimoireTopic.navigation;

    return PageFrame(
      title: AppSection.grimoire.label,
      children: [
        Text(
          'Le Grimoire du Druide : tout ce qu\'il faut savoir pour utiliser '
          'l\'application.',
          style: context.text.bodyLarge,
        ),
        for (final topic in GrimoireTopic.values)
          GrimoirePanel(
            key: ValueKey('${topic.name}-${topic == open}'),
            title: topic.title,
            icon: topic.icon,
            initiallyOpen: topic == open,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                for (final paragraph in topic.paragraphs)
                  Text(paragraph, style: context.text.bodyMedium),
              ],
            ),
          ),
      ],
    );
  }
}
