import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../app/theme/palette.dart';
import 'motion.dart';

/// Barre d'expérience entre [floor] et [ceiling] points.
class XpBar extends StatelessWidget {
  const XpBar({
    required this.xp,
    required this.floor,
    required this.ceiling,
    super.key,
  });

  final int xp;
  final int floor;
  final int ceiling;

  @override
  Widget build(BuildContext context) {
    final techno = context.techno;
    final progress = ceiling <= floor
        ? 1.0
        : ((xp - floor) / (ceiling - floor)).clamp(0.0, 1.0);

    return Semantics(
      label: 'Expérience',
      value: '$xp points sur $ceiling',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ClipPath(
              clipper: const ShapeBorderClipper(
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(7),
                    bottomLeft: Radius.circular(7),
                  ),
                ),
              ),
              child: SizedBox(
                height: 14,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: techno.border),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: MotionScope.duration(
                        context,
                        const Duration(milliseconds: 600),
                      ),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: value,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Palette.emeraude, Palette.cyan],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$xp / $ceiling XP',
              style: context.text.labelSmall!.copyWith(color: techno.muted),
            ),
          ],
        ),
      ),
    );
  }
}
