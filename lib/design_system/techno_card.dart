import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';

/// Carte biseautée de base, cliquable lorsque [onTap] est fourni.
class TechnoCard extends StatelessWidget {
  const TechnoCard({
    required this.child,
    this.onTap,
    this.accent,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? accent;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final techno = context.techno;
    final shape = BeveledRectangleBorder(
      borderRadius: bevel,
      side: BorderSide(color: accent ?? techno.border),
    );

    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: ShapeDecoration(
          shape: shape,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [techno.cardTop, techno.cardBottom],
          ),
        ),
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Petite étiquette colorée : niveau, statut, catégorie.
class TechnoTag extends StatelessWidget {
  const TechnoTag({required this.label, this.color, super.key});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.techno.cyan;

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: tint.withValues(alpha: 0.12),
        shape: BeveledRectangleBorder(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(6),
            bottomLeft: Radius.circular(6),
          ),
          side: BorderSide(color: tint.withValues(alpha: 0.6)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: context.text.labelSmall!.copyWith(color: tint),
        ),
      ),
    );
  }
}

/// Signale honnêtement ce qui n'est pas encore disponible.
class PhaseNotice extends StatelessWidget {
  const PhaseNotice({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final techno = context.techno;

    return TechnoCard(
      accent: techno.orange,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hourglass_top, color: techno.orange, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: context.text.bodyMedium)),
        ],
      ),
    );
  }
}

/// Signale une erreur que l'utilisateur doit voir.
class ErrorNotice extends StatelessWidget {
  const ErrorNotice({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final techno = context.techno;

    return TechnoCard(
      accent: techno.danger,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: techno.danger, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: context.text.bodyMedium)),
        ],
      ),
    );
  }
}

/// Titre de bloc à l'intérieur d'un écran.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(title, style: context.text.titleLarge),
      ),
    );
  }
}
