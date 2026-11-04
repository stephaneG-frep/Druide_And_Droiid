import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';

enum ConsoleLineKind { command, output, success, error }

class ConsoleLine {
  const ConsoleLine(this.kind, this.text);

  final ConsoleLineKind kind;
  final String text;
}

/// Console pédagogique. [title] précise toujours la nature de ce qui est montré.
class ConsolePanel extends StatelessWidget {
  const ConsolePanel({required this.title, required this.lines, super.key});

  final String title;
  final List<ConsoleLine> lines;

  static const background = Color(0xFF060A14);
  static const titleColor = Color(0xFFB4BDD6);

  static Color lineColor(ConsoleLineKind kind) => switch (kind) {
    ConsoleLineKind.command => const Color(0xFF45DDFF),
    ConsoleLineKind.output => const Color(0xFFE6EAF6),
    ConsoleLineKind.success => const Color(0xFF3DE3AC),
    ConsoleLineKind.error => const Color(0xFFFF8095),
  };

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: background,
        shape: BeveledRectangleBorder(
          borderRadius: bevel,
          side: BorderSide(color: context.techno.border),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: context.text.labelMedium!.copyWith(color: titleColor),
            ),
            const SizedBox(height: 8),
            for (final line in lines)
              Text(
                line.kind == ConsoleLineKind.command
                    ? '\$ ${line.text}'
                    : line.text,
                style: TextStyle(
                  fontFamily: fontCode,
                  fontSize: 13.5,
                  height: 1.5,
                  color: lineColor(line.kind),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
