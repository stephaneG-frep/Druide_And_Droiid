import 'package:flutter/material.dart';

import 'palette.dart';

/// Couleurs propres à l'univers technomagique, déclinées par thème.
///
/// Les accents sont lisibles comme du texte sur les surfaces de leur thème :
/// c'est pourquoi le thème clair utilise des teintes plus sombres que la palette.
@immutable
class TechnoColors extends ThemeExtension<TechnoColors> {
  const TechnoColors({
    required this.emeraude,
    required this.violet,
    required this.orange,
    required this.cyan,
    required this.danger,
    required this.muted,
    required this.cardTop,
    required this.cardBottom,
    required this.border,
    required this.circuit,
    required this.heroStart,
    required this.heroEnd,
  });

  final Color emeraude;
  final Color violet;
  final Color orange;
  final Color cyan;
  final Color danger;

  /// Texte secondaire.
  final Color muted;
  final Color cardTop;
  final Color cardBottom;
  final Color border;

  /// Pistes du circuit imprimé en arrière-plan.
  final Color circuit;
  final Color heroStart;
  final Color heroEnd;

  static const dark = TechnoColors(
    emeraude: Palette.emeraude,
    violet: Color(0xFFB9A3FF),
    orange: Palette.orange,
    cyan: Palette.cyan,
    danger: Color(0xFFFF8095),
    muted: Color(0xFFB4BDD6),
    cardTop: Color(0xFF1A2240),
    cardBottom: Color(0xFF131A30),
    border: Color(0xFF34406A),
    circuit: Color(0xFF2A3A6B),
    heroStart: Color(0xFF2A1E63),
    heroEnd: Color(0xFF0F2A3D),
  );

  static const light = TechnoColors(
    emeraude: Color(0xFF00704C),
    violet: Color(0xFF5B35D5),
    orange: Color(0xFF8A4F00),
    cyan: Color(0xFF00657C),
    danger: Color(0xFFB3123A),
    muted: Color(0xFF4A5472),
    cardTop: Color(0xFFFFFFFF),
    cardBottom: Color(0xFFF3F0FF),
    border: Color(0xFFC9C6E6),
    circuit: Color(0xFFD5D2F0),
    heroStart: Color(0xFFE6DEFF),
    heroEnd: Color(0xFFD3F5EE),
  );

  @override
  TechnoColors copyWith() => this;

  @override
  TechnoColors lerp(ThemeExtension<TechnoColors>? other, double t) {
    return t < 0.5 || other == null ? this : other as TechnoColors;
  }
}
