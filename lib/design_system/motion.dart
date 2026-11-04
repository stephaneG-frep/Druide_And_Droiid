import 'package:flutter/widgets.dart';

/// Niveau d'animation choisi dans les Paramètres.
enum MotionLevel {
  /// Transitions et animations d'ambiance de la mascotte.
  full,

  /// Transitions raccourcies, aucune animation en boucle.
  reduced,

  /// Aucune animation.
  none,
}

/// Diffuse le niveau d'animation effectif à l'arbre de widgets.
class MotionScope extends InheritedWidget {
  const MotionScope({required this.level, required super.child, super.key});

  final MotionLevel level;

  static MotionLevel of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MotionScope>();
    return scope?.level ?? MotionLevel.full;
  }

  /// Adapte une durée au niveau d'animation courant.
  static Duration duration(BuildContext context, Duration full) {
    return switch (of(context)) {
      MotionLevel.full => full,
      MotionLevel.reduced => full * 0.5,
      MotionLevel.none => Duration.zero,
    };
  }

  @override
  bool updateShouldNotify(MotionScope oldWidget) => level != oldWidget.level;
}

/// Anime les changements de taille de [child] selon le niveau d'animation.
/// `AnimatedSize` n'accepte pas une durée nulle.
class SmoothSize extends StatelessWidget {
  const SmoothSize({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = MotionScope.duration(
      context,
      const Duration(milliseconds: 220),
    );
    if (duration == Duration.zero) return child;

    return AnimatedSize(
      duration: duration,
      alignment: Alignment.topCenter,
      child: child,
    );
  }
}
