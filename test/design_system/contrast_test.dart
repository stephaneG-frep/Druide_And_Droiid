import 'dart:math' as math;

import 'package:druide_and_droiid/app/theme/app_theme.dart';
import 'package:druide_and_droiid/app/theme/palette.dart';
import 'package:druide_and_droiid/app/theme/techno_colors.dart';
import 'package:druide_and_droiid/design_system/code_panel.dart';
import 'package:druide_and_droiid/design_system/console_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  return (math.max(first, second) + 0.05) / (math.min(first, second) + 0.05);
}

void expectReadable(Color text, Color background, String name) {
  expect(contrast(text, background), greaterThanOrEqualTo(4.5), reason: name);
}

void main() {
  for (final (name, theme) in [
    ('sombre', AppTheme.dark),
    ('clair', AppTheme.light),
  ]) {
    group('thème $name', () {
      final techno = theme.extension<TechnoColors>()!;
      final scheme = theme.colorScheme;
      final surfaces = {
        'fond': theme.scaffoldBackgroundColor,
        'carte haut': techno.cardTop,
        'carte bas': techno.cardBottom,
        'navigation': scheme.surfaceContainer,
        'héros début': techno.heroStart,
        'héros fin': techno.heroEnd,
      };
      final texts = {
        'texte': scheme.onSurface,
        'secondaire': techno.muted,
        'émeraude': techno.emeraude,
        'violet': techno.violet,
        'orange': techno.orange,
        'cyan': techno.cyan,
        'danger': techno.danger,
      };

      for (final surface in surfaces.entries) {
        test('texte lisible sur ${surface.key}', () {
          for (final text in texts.entries) {
            expectReadable(text.value, surface.value, text.key);
          }
        });
      }

      test('étiquette teintée lisible sur une carte', () {
        for (final text in texts.entries) {
          final tint = text.value.withValues(alpha: 0.12);
          final background = Color.alphaBlend(tint, techno.cardTop);
          expectReadable(text.value, background, text.key);
        }
      });
    });
  }

  test('texte du bouton principal lisible sur tout son dégradé', () {
    expectReadable(Palette.fondSombre, Palette.emeraude, 'début');
    expectReadable(Palette.fondSombre, Palette.cyan, 'fin');
  });

  test('coloration du code lisible', () {
    for (final entry in codeTokenColors.entries) {
      expectReadable(entry.value, codeBackground, entry.key.name);
    }
  });

  test('console lisible', () {
    expectReadable(ConsolePanel.titleColor, ConsolePanel.background, 'titre');
    for (final kind in ConsoleLineKind.values) {
      expectReadable(
        ConsolePanel.lineColor(kind),
        ConsolePanel.background,
        kind.name,
      );
    }
  });
}
