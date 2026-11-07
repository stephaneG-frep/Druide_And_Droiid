import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';
import '../data/gamification_repository.dart';
import '../domain/badges.dart';
import '../domain/learner_stats.dart';

String describeSource(String source, LearningCatalog? catalog) {
  final parts = source.split(':');
  final id = parts.last;
  return switch (parts.first) {
    'lesson' => 'Leçon : ${catalog?.lessonTitles[id] ?? id}',
    'quiz' when parts[1] == 'lesson' =>
      'Quiz : ${catalog?.lessonTitles[id] ?? id}',
    'quiz' when parts[1] == 'eval' => 'Évaluation du module',
    'quiz' => 'Question flash',
    'exercise' => 'Exercice réussi',
    'lab' => 'Exercice du Lab',
    'project' => 'Projet terminé',
    'bug' => 'Bug vérifié',
    'final' => 'Évaluation finale',
    'challenge' => 'Défi accompli',
    _ => 'Récompense',
  };
}

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  String _date(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(learnerStatsProvider).value ?? const LearnerStats();
    final catalog = ref.watch(learningCatalogProvider).value;
    final entries = <(DateTime, String, String)>[
      for (final event in stats.xpEvents)
        (
          event.at,
          describeSource(event.source, catalog),
          '+${event.amount} XP',
        ),
      for (final MapEntry(:key, :value) in stats.badges.entries)
        (
          value,
          'Badge : ${badges.where((badge) => badge.id == key).firstOrNull?.title ?? key}',
          '',
        ),
    ]..sort((a, b) => b.$1.compareTo(a.$1));

    return PageFrame(
      title: 'Historique',
      children: [
        if (entries.isEmpty)
          Text(
            'Rien pour l\'instant : votre aventure commence ici.',
            style: context.text.bodyMedium,
          ),
        for (final (date, label, amount) in entries)
          TechnoCard(
            child: Row(
              spacing: 12,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: context.text.bodyMedium),
                      Text(
                        _date(date),
                        style: context.text.bodySmall!.copyWith(
                          color: context.techno.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (amount.isNotEmpty)
                  Text(amount, style: context.text.titleSmall),
              ],
            ),
          ),
      ],
    );
  }
}
