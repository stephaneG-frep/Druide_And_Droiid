import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';

/// Pistes de circuit imprimé discrètes, dessinées une fois derrière le contenu.
class CircuitBackdrop extends StatelessWidget {
  const CircuitBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CircuitPainter(context.techno.circuit),
      child: child,
    );
  }
}

class _CircuitPainter extends CustomPainter {
  const _CircuitPainter(this.color);

  final Color color;

  static const _cell = 48.0;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final line = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final node = Paint()..color = color.withValues(alpha: 0.7);
    final traces = (size.width * size.height / 42000).ceil().clamp(6, 60);

    for (var i = 0; i < traces; i++) {
      var point = Offset(
        (random.nextDouble() * size.width / _cell).floorToDouble() * _cell,
        (random.nextDouble() * size.height / _cell).floorToDouble() * _cell,
      );
      final path = Path()..moveTo(point.dx, point.dy);
      canvas.drawCircle(point, 2.5, node);

      for (var segment = 0; segment < 3; segment++) {
        final length = _cell * (1 + random.nextInt(3));
        point += switch (random.nextInt(3)) {
          0 => Offset(length, 0),
          1 => Offset(0, length),
          _ => Offset(length, length),
        };
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, line);
      canvas.drawCircle(point, 3, node);
    }
  }

  @override
  bool shouldRepaint(_CircuitPainter oldDelegate) => color != oldDelegate.color;
}
