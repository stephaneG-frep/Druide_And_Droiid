import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../app/theme/palette.dart';

enum MascotMood { neutre, joyeux, pensif, surpris, encourageant }

/// Dessine Maître And-Droiīd dans un repère de 200 × 240.
///
/// [animation] varie de 0 à 1 en boucle : clignement, scintillement de la barbe
/// et pulsation du bâton. Sans animation, la mascotte reste immobile.
class MascotPainter extends CustomPainter {
  MascotPainter({required this.mood, this.animation})
    : super(repaint: animation);

  final MascotMood mood;
  final Animation<double>? animation;

  static const aspectRatio = 200 / 240;

  static const _hoodLight = Color(0xFF7B52F5);
  static const _hoodDark = Color(0xFF352080);
  static const _robeLight = Color(0xFF4A2FA8);
  static const _robeDark = Color(0xFF211551);
  static const _metalLight = Color(0xFFDCE5F5);
  static const _metalDark = Color(0xFF8C9CC0);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation?.value ?? 0;
    canvas.scale(size.width / 200, size.height / 240);

    _paintStaff(canvas, t);
    _paintRobe(canvas);
    _paintHood(canvas);
    _paintFace(canvas);
    _paintEyes(canvas, _eyeOpening(t));
    _paintMouth(canvas);
    _paintBeard(canvas, t);
    _paintHand(canvas);
  }

  /// Fermeture rapide des paupières sur une courte fenêtre de la boucle.
  double _eyeOpening(double t) {
    const start = 0.9;
    const end = 0.96;
    if (t < start || t > end) return 1;
    final progress = (t - start) / (end - start);
    return (2 * progress - 1).abs().clamp(0.08, 1.0);
  }

  void _paintStaff(Canvas canvas, double t) {
    const orb = Offset(172, 42);
    final pulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi);

    canvas.drawLine(
      const Offset(172, 54),
      const Offset(172, 236),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.orange, Color(0xFF7A4A12)],
        ).createShader(const Rect.fromLTWH(168, 54, 8, 182))
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    for (final y in [96.0, 132.0, 204.0]) {
      canvas.drawLine(
        Offset(168, y),
        Offset(176, y),
        Paint()
          ..color = Palette.cyan
          ..strokeWidth = 2,
      );
    }

    canvas.drawCircle(
      orb,
      lerpDouble(15, 19, pulse)!,
      Paint()
        ..color = Palette.cyan.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawCircle(
      orb,
      11,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Colors.white, Palette.cyan, Color(0xFF0079B8)],
          stops: [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: orb, radius: 11)),
    );

    final claw = Paint()
      ..color = Palette.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: orb, radius: 14),
      0.25 * math.pi,
      0.5 * math.pi,
      false,
      claw,
    );
    canvas.drawLine(const Offset(160, 52), const Offset(166, 58), claw);
    canvas.drawLine(const Offset(184, 52), const Offset(178, 58), claw);
  }

  void _paintRobe(Canvas canvas) {
    final robe = Path()
      ..moveTo(42, 238)
      ..cubicTo(46, 196, 58, 160, 100, 150)
      ..cubicTo(142, 160, 154, 196, 158, 238)
      ..close();
    canvas.drawPath(
      robe,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_robeLight, _robeDark],
        ).createShader(const Rect.fromLTWH(42, 150, 116, 88)),
    );

    final trace = Paint()
      ..color = Palette.emeraude.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final node = Paint()..color = Palette.emeraude;
    for (final points in const [
      [Offset(62, 238), Offset(62, 214), Offset(74, 202)],
      [Offset(138, 238), Offset(138, 220), Offset(126, 208)],
      [Offset(100, 238), Offset(100, 212)],
    ]) {
      canvas.drawPath(Path()..addPolygon(points, false), trace);
      canvas.drawCircle(points.last, 2.6, node);
    }
  }

  void _paintHood(Canvas canvas) {
    final hood = Path()
      ..moveTo(44, 128)
      ..cubicTo(32, 88, 50, 40, 90, 16)
      ..cubicTo(100, 8, 118, 2, 130, 10)
      ..cubicTo(120, 14, 120, 22, 128, 34)
      ..cubicTo(152, 58, 168, 98, 156, 128)
      ..cubicTo(150, 148, 128, 160, 100, 160)
      ..cubicTo(72, 160, 50, 148, 44, 128)
      ..close();
    canvas.drawPath(
      hood,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_hoodLight, _hoodDark],
        ).createShader(const Rect.fromLTWH(32, 2, 136, 158)),
    );

    final opening = Rect.fromCenter(
      center: const Offset(100, 100),
      width: 92,
      height: 96,
    );
    canvas.drawOval(opening, Paint()..color = Palette.fondSombre);
    canvas.drawOval(
      opening,
      Paint()
        ..color = Palette.emeraude
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );

    // Gemme frontale de la capuche.
    final gem = Path()
      ..moveTo(100, 34)
      ..lineTo(108, 43)
      ..lineTo(100, 51)
      ..lineTo(92, 43)
      ..close();
    canvas.drawPath(gem, Paint()..color = Palette.orange);
    canvas.drawPath(
      gem,
      Paint()
        ..color = const Color(0xFFFFE0AE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  void _paintFace(Canvas canvas) {
    final face = RRect.fromRectAndRadius(
      const Rect.fromLTWH(66, 66, 68, 64),
      const Radius.circular(20),
    );
    canvas.drawRRect(
      face,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_metalLight, _metalDark],
        ).createShader(face.outerRect),
    );

    // Oreillettes électroniques.
    for (final x in [62.0, 138.0]) {
      canvas.drawCircle(Offset(x, 98), 7, Paint()..color = Palette.orange);
      canvas.drawCircle(Offset(x, 98), 3, Paint()..color = Palette.fondSombre);
    }
  }

  void _paintEyes(Canvas canvas, double opening) {
    const left = Offset(84, 92);
    const right = Offset(116, 92);
    final socket = Paint()..color = Palette.bleuNuit;
    canvas.drawCircle(left, 12.5, socket);
    canvas.drawCircle(right, 12.5, socket);

    final arc = Paint()
      ..color = Palette.emeraude
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    switch (mood) {
      case MascotMood.neutre:
        _paintLed(canvas, left, 8, opening);
        _paintLed(canvas, right, 8, opening);
      case MascotMood.joyeux:
        _paintHappyEye(canvas, left, arc);
        _paintHappyEye(canvas, right, arc);
      case MascotMood.pensif:
        _paintLed(canvas, left, 8, opening * 0.55, pupil: const Offset(3, -3));
        _paintLed(canvas, right, 8, opening, pupil: const Offset(3, -3));
      case MascotMood.surpris:
        _paintLed(canvas, left, 10, opening, pupilSize: 2);
        _paintLed(canvas, right, 10, opening, pupilSize: 2);
      case MascotMood.encourageant:
        _paintLed(canvas, left, 8, opening);
        _paintHappyEye(canvas, right, arc);
    }
  }

  void _paintLed(
    Canvas canvas,
    Offset center,
    double radius,
    double opening, {
    Offset pupil = Offset.zero,
    double pupilSize = 3,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1, opening);
    canvas.drawCircle(
      Offset.zero,
      radius + 3,
      Paint()
        ..color = Palette.cyan.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(Offset.zero, radius, Paint()..color = Palette.cyan);
    canvas.drawCircle(pupil, pupilSize, Paint()..color = Palette.fondSombre);
    canvas.restore();
  }

  void _paintHappyEye(Canvas canvas, Offset center, Paint paint) {
    canvas.drawArc(
      Rect.fromCenter(center: center.translate(0, 3), width: 15, height: 13),
      math.pi,
      math.pi,
      false,
      paint,
    );
  }

  void _paintMouth(Canvas canvas) {
    final paint = Paint()
      ..color = Palette.fondSombre
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    switch (mood) {
      case MascotMood.neutre:
        canvas.drawLine(const Offset(90, 117), const Offset(110, 117), paint);
      case MascotMood.joyeux || MascotMood.encourageant:
        canvas.drawArc(
          const Rect.fromLTWH(86, 106, 28, 15),
          0.1 * math.pi,
          0.8 * math.pi,
          false,
          paint,
        );
      case MascotMood.pensif:
        canvas.drawLine(const Offset(92, 119), const Offset(108, 115), paint);
      case MascotMood.surpris:
        canvas.drawCircle(const Offset(100, 117), 5, paint);
    }
  }

  void _paintBeard(Canvas canvas, double t) {
    const fibers = 9;
    for (var i = 0; i < fibers; i++) {
      final offset = i - (fibers - 1) / 2;
      final root = Offset(100 + offset * 6, 126);
      final tip = Offset(100 + offset * 10.5, 196 - offset.abs() * 8);
      final sway = offset * 6;

      final fiber = Path()
        ..moveTo(root.dx, root.dy)
        ..quadraticBezierTo(
          root.dx + sway,
          (root.dy + tip.dy) / 2,
          tip.dx,
          tip.dy,
        );
      canvas.drawPath(
        fiber,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Palette.emeraude, Palette.cyan],
          ).createShader(Rect.fromPoints(root, tip.translate(1, 0)))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round,
      );

      // Une onde lumineuse parcourt les extrémités des fibres.
      final wave = 0.5 + 0.5 * math.sin((t + i / fibers) * 2 * math.pi);
      canvas.drawCircle(
        tip,
        5,
        Paint()
          ..color = Palette.cyan.withValues(alpha: 0.15 + 0.4 * wave)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(tip, 2.6, Paint()..color = Colors.white);
    }
  }

  void _paintHand(Canvas canvas) {
    final arm = Path()
      ..moveTo(138, 178)
      ..quadraticBezierTo(152, 186, 170, 164)
      ..lineTo(172, 180)
      ..quadraticBezierTo(150, 202, 134, 194)
      ..close();
    canvas.drawPath(arm, Paint()..color = _robeLight);

    final hand = RRect.fromRectAndRadius(
      const Rect.fromLTWH(163, 156, 18, 24),
      const Radius.circular(7),
    );
    canvas.drawRRect(hand, Paint()..color = _metalLight);
    canvas.drawRRect(
      hand,
      Paint()
        ..color = _metalDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(MascotPainter oldDelegate) {
    return mood != oldDelegate.mood || animation != oldDelegate.animation;
  }
}
