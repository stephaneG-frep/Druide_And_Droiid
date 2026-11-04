import 'package:flutter/material.dart';

import '../sections.dart';

/// État d'attente assumé : annonce la phase qui livrera réellement la rubrique.
class SectionPlaceholderPage extends StatelessWidget {
  const SectionPlaceholderPage({required this.section, super.key});

  final AppSection section;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(section.label)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(section.icon, size: 64),
              const SizedBox(height: 16),
              Text(
                section.description,
                style: textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Cette rubrique n\'est pas encore disponible : '
                'elle arrive en phase ${section.plannedPhase}.',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
