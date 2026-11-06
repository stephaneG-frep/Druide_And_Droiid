import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../design_system/code_panel.dart';
import '../domain/line_diff.dart';

/// Comparaison lisible sans couleur : chaque ligne porte aussi un signe.
class DiffView extends StatelessWidget {
  const DiffView({
    required this.before,
    required this.after,
    required this.beforeLabel,
    required this.afterLabel,
    super.key,
  });

  final String before;
  final String after;
  final String beforeLabel;
  final String afterLabel;

  @override
  Widget build(BuildContext context) {
    final lines = diffLines(before, after);
    final identical = lines.every((line) => line.kind == DiffKind.same);
    final techno = context.techno;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Text('− $beforeLabel', style: context.text.bodySmall),
        Text('+ $afterLabel', style: context.text.bodySmall),
        if (identical)
          Text('Aucune différence.', style: context.text.bodyMedium)
        else
          DecoratedBox(
            decoration: ShapeDecoration(
              color: codeBackground,
              shape: BeveledRectangleBorder(
                borderRadius: bevel,
                side: BorderSide(color: techno.border),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              child: SelectableText.rich(
                TextSpan(
                  style: const TextStyle(
                    fontFamily: fontCode,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  children: [
                    for (final line in lines)
                      TextSpan(
                        text: '${_sign(line.kind)} ${line.text}\n',
                        style: TextStyle(color: _color(line.kind)),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _sign(DiffKind kind) => switch (kind) {
    DiffKind.same => ' ',
    DiffKind.added => '+',
    DiffKind.removed => '−',
  };

  Color _color(DiffKind kind) => switch (kind) {
    DiffKind.same => const Color(0xFFB4BDD6),
    DiffKind.added => const Color(0xFF3DE3AC),
    DiffKind.removed => const Color(0xFFFF8095),
  };
}
