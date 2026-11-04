import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'circuit_backdrop.dart';

const maxContentWidth = 1100.0;

/// Gabarit commun des écrans : barre de titre, fond et colonne centrée.
class PageFrame extends StatelessWidget {
  const PageFrame({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: CircuitBackdrop(
        child: LayoutBuilder(
          builder: (context, box) {
            final side = math.max(16.0, (box.maxWidth - maxContentWidth) / 2);
            return ListView.separated(
              padding: EdgeInsets.fromLTRB(side, 8, side, 24),
              itemCount: children.length,
              itemBuilder: (context, index) => children[index],
              separatorBuilder: (context, index) => const SizedBox(height: 16),
            );
          },
        ),
      ),
    );
  }
}
