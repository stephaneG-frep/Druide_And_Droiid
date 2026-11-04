import 'package:flutter/material.dart';

import 'palette.dart';

/// Thèmes de base ; la personnalisation technomagique arrive en phase 2.
abstract final class AppTheme {
  static final dark = _build(
    ColorScheme.fromSeed(
      seedColor: Palette.emeraude,
      brightness: Brightness.dark,
      primary: Palette.emeraude,
      secondary: Palette.violet,
      tertiary: Palette.orange,
      surface: Palette.bleuNuit,
    ),
    scaffoldBackground: Palette.fondSombre,
  );

  static final light = _build(
    ColorScheme.fromSeed(
      seedColor: Palette.emeraude,
      secondary: Palette.violet,
      tertiary: Palette.orange,
    ),
  );

  static ThemeData _build(ColorScheme scheme, {Color? scaffoldBackground}) {
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
    );
  }
}
