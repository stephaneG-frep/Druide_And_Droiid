import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../design_system/code_panel.dart';
import '../../academie/presentation/lesson_blocks.dart';
import '../domain/bug_rule.dart';

/// Les six parties d'une analyse, sous forme de fiche préenregistrée.
class BugRuleView extends StatelessWidget {
  const BugRuleView(this.rule, {super.key});

  final BugRule rule;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        _Section('Résumé du problème', [rule.summary]),
        _Section('Causes possibles', rule.causes),
        _Checklist('Vérifications recommandées', rule.checks),
        _Section('Corrections proposées', rule.fixes),
        if (rule.example case final example?)
          CodePanel(code: example.code, language: example.language),
        _Section('Explication pédagogique', [rule.lesson]),
        _Checklist('Procédure de validation', rule.validation),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.items);

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        Text(title, style: context.text.titleSmall),
        for (final item in items)
          RichLessonText(
            items.length > 1 ? '• $item' : item,
            style: context.text.bodyMedium,
          ),
      ],
    );
  }
}

/// Coches de travail : elles guident, mais ne prouvent rien.
class _Checklist extends StatefulWidget {
  const _Checklist(this.title, this.items);

  final String title;
  final List<String> items;

  @override
  State<_Checklist> createState() => _ChecklistState();
}

class _ChecklistState extends State<_Checklist> {
  final _done = <int>{};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.title, style: context.text.titleSmall),
        for (final (index, item) in widget.items.indexed)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            value: _done.contains(index),
            title: RichLessonText(item, style: context.text.bodyMedium),
            onChanged: (checked) => setState(() {
              if (checked ?? false) {
                _done.add(index);
              } else {
                _done.remove(index);
              }
            }),
          ),
      ],
    );
  }
}
