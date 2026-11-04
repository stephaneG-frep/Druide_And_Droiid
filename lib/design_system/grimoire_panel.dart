import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import 'motion.dart';
import 'techno_card.dart';

/// Page de grimoire qui se déplie et se replie.
class GrimoirePanel extends StatefulWidget {
  const GrimoirePanel({
    required this.title,
    required this.icon,
    required this.child,
    this.initiallyOpen = false,
    super.key,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final bool initiallyOpen;

  @override
  State<GrimoirePanel> createState() => _GrimoirePanelState();
}

class _GrimoirePanelState extends State<GrimoirePanel> {
  late var _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final techno = context.techno;
    final duration = MotionScope.duration(
      context,
      const Duration(milliseconds: 220),
    );

    return Semantics(
      expanded: _open,
      child: TechnoCard(
        accent: _open ? techno.violet : null,
        onTap: () => setState(() => _open = !_open),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(widget.icon, color: techno.violet),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(widget.title, style: context.text.titleSmall),
                ),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: duration,
                  child: Transform.rotate(
                    angle: math.pi / 2,
                    child: const Icon(Icons.chevron_right),
                  ),
                ),
              ],
            ),
            SmoothSize(
              child: _open
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: widget.child,
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}
