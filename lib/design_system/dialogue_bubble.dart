import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import 'mascot/maitre_and_droiid.dart';
import 'techno_card.dart';

/// Fenêtre de dialogue de la mascotte.
///
/// [origin] dit toujours d'où vient le texte : un message rédigé à l'avance ne
/// doit jamais passer pour une réponse d'IA.
class DialogueBubble extends StatelessWidget {
  const DialogueBubble({
    required this.message,
    required this.origin,
    this.mood = MascotMood.neutre,
    super.key,
  });

  final String message;
  final String origin;
  final MascotMood mood;

  @override
  Widget build(BuildContext context) {
    final techno = context.techno;

    return TechnoCard(
      accent: techno.violet,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MaitreAndDroiid(width: 72, mood: mood),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Maître And-Droiīd', style: context.text.titleSmall),
                const SizedBox(height: 4),
                TechnoTag(label: origin, color: techno.violet),
                const SizedBox(height: 8),
                Text(message, style: context.text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
