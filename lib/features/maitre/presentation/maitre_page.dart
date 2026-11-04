import 'package:flutter/material.dart';

import '../../../app/sections.dart';
import '../../../app/theme/app_theme.dart';
import '../../../design_system/dialogue_bubble.dart';
import '../../../design_system/mascot/maitre_and_droiid.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';

const _capabilities = [
  'Expliquer les concepts Android à votre niveau',
  'Générer des exemples de code',
  'Corriger vos exercices',
  'Analyser des erreurs et des messages Logcat',
  'Aider à comprendre Gradle',
  'Diagnostiquer des problèmes Flutter',
  'Proposer des exercices personnalisés',
  'Accompagner vos projets',
  'Suggérer des améliorations de code',
];

class MaitrePage extends StatelessWidget {
  const MaitrePage({super.key});

  @override
  Widget build(BuildContext context) {
    final techno = context.techno;

    return PageFrame(
      title: AppSection.maitre.label,
      children: [
        const DialogueBubble(
          origin: 'Message préenregistré',
          mood: MascotMood.encourageant,
          message:
              'Bienvenue, jeune apprenti ! Mes circuits ne sont pas '
              'encore reliés à une IA : pour l\'instant, je ne peux pas vous '
              'répondre.',
        ),
        const PhaseNotice(
          message:
              'Le chat IA n\'est pas encore disponible. Vous pourrez '
              'bientôt choisir votre fournisseur : Anthropic Claude, OpenAI, '
              'Google Gemini, Ollama ou une API compatible.',
        ),
        const SectionTitle('Ce que je saurai faire'),
        TechnoCard(
          child: Column(
            children: [
              for (final capability in _capabilities)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.bolt, size: 18, color: techno.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(capability, style: context.text.bodyMedium),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
