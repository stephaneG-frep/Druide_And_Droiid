import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../app/theme/palette.dart';
import 'motion.dart';

/// Bouton principal technomagique, biseauté et lumineux.
class ArcaneButton extends StatefulWidget {
  const ArcaneButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Variante contour, pour les actions de second rang.
  final bool secondary;

  @override
  State<ArcaneButton> createState() => _ArcaneButtonState();
}

class _ArcaneButtonState extends State<ArcaneButton> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final techno = context.techno;
    final foreground = widget.secondary ? techno.emeraude : Palette.fondSombre;
    final shape = BeveledRectangleBorder(
      borderRadius: bevel,
      side: widget.secondary
          ? BorderSide(color: techno.emeraude, width: 1.5)
          : BorderSide.none,
    );

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: MotionScope.duration(
        context,
        const Duration(milliseconds: 100),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: ShapeDecoration(
            shape: shape,
            gradient: widget.secondary
                ? null
                : const LinearGradient(
                    colors: [Palette.emeraude, Palette.cyan],
                  ),
          ),
          child: InkWell(
            customBorder: shape,
            onTap: widget.onPressed,
            onHighlightChanged: (value) => setState(() => _pressed = value),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: foreground, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        style: context.text.labelLarge!.copyWith(
                          color: foreground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
