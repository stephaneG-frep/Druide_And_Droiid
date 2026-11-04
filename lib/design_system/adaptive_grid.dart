import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Grille dont le nombre de colonnes suit la largeur disponible.
/// Les éléments d'une même ligne partagent la même hauteur.
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({
    required this.minItemWidth,
    required this.children,
    this.spacing = 12,
    this.maxColumns,
    super.key,
  });

  final double minItemWidth;
  final double spacing;

  /// Plafond de colonnes : évite un vide à droite quand les éléments sont peu nombreux.
  final int? maxColumns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final fitting = math.max(
          1,
          ((box.maxWidth + spacing) / (minItemWidth + spacing)).floor(),
        );
        final columns = math.min(fitting, maxColumns ?? fitting);
        final rows = <Widget>[];

        for (var start = 0; start < children.length; start += columns) {
          final end = math.min(start + columns, children.length);
          if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < columns; index++) ...[
                    if (index > 0) SizedBox(width: spacing),
                    Expanded(
                      child: start + index < end
                          ? children[start + index]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}
