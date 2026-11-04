import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';

/// Badge hexagonal de progression, éteint tant qu'il n'est pas obtenu.
class RuneBadge extends StatelessWidget {
  const RuneBadge({
    required this.icon,
    required this.label,
    required this.unlocked,
    this.caption,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool unlocked;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final techno = context.techno;
    final color = unlocked ? techno.emeraude : techno.muted;

    return Semantics(
      container: true,
      label: '$label, ${unlocked ? 'obtenu' : 'verrouillé'}',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 68,
              child: CustomPaint(
                painter: _HexagonPainter(color, filled: unlocked),
                child: Center(
                  child: Icon(
                    unlocked ? icon : Icons.lock_outline,
                    color: color,
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: context.text.labelMedium,
            ),
            if (caption != null)
              Text(
                caption!,
                textAlign: TextAlign.center,
                style: context.text.labelSmall!.copyWith(color: techno.muted),
              ),
          ],
        ),
      ),
    );
  }
}

class _HexagonPainter extends CustomPainter {
  const _HexagonPainter(this.color, {required this.filled});

  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 2;
    final hexagon = Path()
      ..addPolygon([
        for (var i = 0; i < 6; i++)
          center + Offset.fromDirection(math.pi / 6 + i * math.pi / 3, radius),
      ], true);

    if (filled) {
      canvas.drawPath(hexagon, Paint()..color = color.withValues(alpha: 0.18));
    }
    canvas.drawPath(
      hexagon,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_HexagonPainter oldDelegate) {
    return color != oldDelegate.color || filled != oldDelegate.filled;
  }
}
