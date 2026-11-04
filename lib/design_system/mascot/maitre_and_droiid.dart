import 'package:flutter/material.dart';

import '../motion.dart';
import 'mascot_painter.dart';

export 'mascot_painter.dart' show MascotMood;

/// Maître And-Droiīd. Son animation ne tourne qu'au niveau [MotionLevel.full].
class MaitreAndDroiid extends StatefulWidget {
  const MaitreAndDroiid({
    this.width = 120,
    this.mood = MascotMood.neutre,
    super.key,
  });

  final double width;
  final MascotMood mood;

  @override
  State<MaitreAndDroiid> createState() => _MaitreAndDroiidState();
}

class _MaitreAndDroiidState extends State<MaitreAndDroiid>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MotionScope.of(context) == MotionLevel.full) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Maître And-Droiīd, druide robot',
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(widget.width, widget.width / MascotPainter.aspectRatio),
          painter: MascotPainter(mood: widget.mood, animation: _controller),
        ),
      ),
    );
  }
}
