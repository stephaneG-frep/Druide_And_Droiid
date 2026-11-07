import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';
import '../data/bug_repository.dart';
import '../domain/bug_rule.dart';
import 'bug_rule_view.dart';

class BugGuidePage extends ConsumerWidget {
  const BugGuidePage({required this.family, super.key});

  final BugFamily family;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(bugRulesProvider);

    return PageFrame(
      title: family.label,
      children: [
        Text(
          'Fiches rédigées à l\'avance, sans IA. Choisissez celle qui ressemble '
          'à votre panne, puis suivez ses vérifications dans l\'ordre.',
          style: context.text.bodyMedium,
        ),
        switch (rules) {
          AsyncData(:final value) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              for (final rule in value.where((rule) => rule.family == family))
                TechnoCard(
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(rule.title, style: context.text.titleSmall),
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    children: [BugRuleView(rule)],
                  ),
                ),
            ],
          ),
          AsyncError() => const ErrorNotice(
            message: 'Les fiches n\'ont pas pu être chargées.',
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ],
    );
  }
}
