import 'package:flutter/material.dart';

import '../../../app/sections.dart';
import '../../../app/theme/app_theme.dart';
import '../../../design_system/dialogue_bubble.dart';
import '../../../design_system/mascot/maitre_and_droiid.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';

const _families = [
  'Erreurs Gradle',
  'Problèmes SDK',
  'Erreurs ADB',
  'APK incompatibles',
  'Problèmes ABI',
  'Crashs au démarrage',
  'Blocages sur splash screen',
  'Erreurs de permissions',
  'Problèmes de dépendances',
  'Erreurs Flutter/Dart',
];

const _reportSteps = [
  'Un résumé du problème',
  'Les causes possibles',
  'Les vérifications recommandées',
  'Les corrections proposées',
  'Une explication pédagogique',
  'Une procédure de validation',
];

class ChaudronPage extends StatelessWidget {
  const ChaudronPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: AppSection.chaudron.label,
      children: [
        const DialogueBubble(
          origin: 'Message préenregistré',
          mood: MascotMood.pensif,
          message:
              'Un bug qui bouillonne ? Bientôt, vous pourrez le jeter '
              'dans mon chaudron pour que nous l\'examinions ensemble.',
        ),
        const PhaseNotice(
          message:
              'L\'analyse des erreurs et des logs n\'est pas encore '
              'disponible.',
        ),
        const SectionTitle('Les pannes prévues'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final family in _families)
              TechnoTag(label: family, color: context.techno.orange),
          ],
        ),
        const SectionTitle('Ce que contiendra chaque analyse'),
        TechnoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (index, step) in _reportSteps.indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    '${index + 1}. $step',
                    style: context.text.bodyMedium,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
