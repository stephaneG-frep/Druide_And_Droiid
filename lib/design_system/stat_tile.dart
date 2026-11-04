import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import 'techno_card.dart';

/// Tuile chiffrée de tableau de bord.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.icon,
    required this.value,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final techno = context.techno;

    return Semantics(
      container: true,
      label: '$label : $value',
      child: ExcludeSemantics(
        child: TechnoCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: techno.cyan, size: 22),
              const SizedBox(height: 8),
              Text(value, style: context.text.headlineSmall),
              Text(
                label,
                style: context.text.bodySmall!.copyWith(color: techno.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
