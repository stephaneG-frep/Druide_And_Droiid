import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/palette.dart';
import '../../../design_system/code_panel.dart';
import '../../../design_system/console_panel.dart';
import '../../../design_system/dialogue_bubble.dart';
import '../../../design_system/mascot/maitre_and_droiid.dart';
import '../../../design_system/techno_card.dart';
import '../domain/course.dart';

final _inlinePattern = RegExp(r'\*\*(.+?)\*\*|`([^`]+)`');

/// Texte avec `**gras**` et `` `code` ``.
class RichLessonText extends StatelessWidget {
  const RichLessonText(this.text, {this.style, super.key});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final match in _inlinePattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      spans.add(
        match[1] != null
            ? TextSpan(
                text: match[1],
                style: const TextStyle(fontWeight: FontWeight.w700),
              )
            : TextSpan(
                text: match[2],
                style: const TextStyle(fontFamily: fontCode),
              ),
      );
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return Text.rich(
      TextSpan(children: spans),
      style: style ?? context.text.bodyLarge,
    );
  }
}

class LessonBlockView extends StatelessWidget {
  const LessonBlockView(this.block, {super.key});

  final LessonBlock block;

  @override
  Widget build(BuildContext context) {
    final techno = context.techno;

    return switch (block) {
      HeadingBlock(:final text) => SectionTitle(text),
      ParagraphBlock(:final text) => RichLessonText(text),
      ListBlock(:final items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          for (final item in items)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(Icons.auto_awesome, size: 16, color: techno.cyan),
                ),
                const SizedBox(width: 10),
                Expanded(child: RichLessonText(item)),
              ],
            ),
        ],
      ),
      CodeBlock(:final language, :final code, :final output) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          CodePanel(code: code, language: language),
          if (output != null)
            ConsolePanel(
              title: 'Résultat de ce programme, relevé à la rédaction',
              lines: [
                for (final line in output.split('\n'))
                  ConsoleLine(ConsoleLineKind.output, line),
              ],
            ),
        ],
      ),
      CalloutBlock(:final kind, :final text) => _Callout(kind, text),
      TipBlock(:final text) => DialogueBubble(
        origin: 'Conseil du cours',
        mood: MascotMood.encourageant,
        message: text,
      ),
      LayersBlock(:final title, :final layers) => _LayersDiagram(title, layers),
    };
  }
}

class _Callout extends StatelessWidget {
  const _Callout(this.kind, this.text);

  final CalloutKind kind;
  final String text;

  @override
  Widget build(BuildContext context) {
    final techno = context.techno;
    final (icon, color, label) = switch (kind) {
      CalloutKind.info => (Icons.lightbulb_outline, techno.cyan, 'À savoir'),
      CalloutKind.warning => (Icons.warning_amber, techno.orange, 'Attention'),
    };

    return TechnoCard(
      accent: color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.text.titleSmall!.copyWith(color: color),
                ),
                const SizedBox(height: 4),
                RichLessonText(text, style: context.text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Schéma d'une pile de couches, lisible aussi par un lecteur d'écran.
class _LayersDiagram extends StatelessWidget {
  const _LayersDiagram(this.title, this.layers);

  final String title;
  final List<DiagramLayer> layers;

  static const _tints = [
    Palette.emeraude,
    Palette.cyan,
    Palette.violet,
    Palette.orange,
  ];

  @override
  Widget build(BuildContext context) {
    return TechnoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          Text(title, style: context.text.titleSmall),
          for (final (index, layer) in layers.indexed)
            DecoratedBox(
              decoration: BoxDecoration(
                color: _tints[index % _tints.length].withValues(alpha: 0.16),
                border: Border(
                  left: BorderSide(
                    color: _tints[index % _tints.length],
                    width: 3,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(layer.name, style: context.text.labelLarge),
                    Text(layer.detail, style: context.text.bodySmall),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
