import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/sections.dart';
import '../../../app/theme/app_theme.dart';
import '../domain/grimoire_topics.dart';

String grimoirePath(GrimoireTopic topic) =>
    '${AppSection.grimoire.path}?sujet=${topic.name}';

/// Aide contextuelle : la rubrique du Grimoire qui concerne cet écran.
class HelpButton extends StatelessWidget {
  const HelpButton(this.topic, {super.key});

  final GrimoireTopic topic;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Aide',
      icon: const Icon(Icons.help_outline),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheet) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Text(topic.title, style: sheet.text.titleLarge),
                for (final paragraph in topic.paragraphs)
                  Text(paragraph, style: sheet.text.bodyMedium),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(sheet);
                      context.go(grimoirePath(topic));
                    },
                    child: const Text('Ouvrir le Grimoire'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
