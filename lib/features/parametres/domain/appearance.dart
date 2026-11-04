import 'package:flutter/material.dart';

import '../../../design_system/motion.dart';

class Appearance {
  const Appearance({required this.themeMode, required this.motion});

  /// Le thème sombre porte l'identité de l'application.
  static const defaults = Appearance(
    themeMode: ThemeMode.dark,
    motion: MotionLevel.full,
  );

  final ThemeMode themeMode;
  final MotionLevel motion;

  Appearance copyWith({ThemeMode? themeMode, MotionLevel? motion}) {
    return Appearance(
      themeMode: themeMode ?? this.themeMode,
      motion: motion ?? this.motion,
    );
  }
}
