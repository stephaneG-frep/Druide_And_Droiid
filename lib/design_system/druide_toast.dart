import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';

enum ToastKind { success, error }

/// Notification visuelle brève, annoncée aussi aux lecteurs d'écran.
void showDruideToast(
  BuildContext context,
  String message, {
  ToastKind kind = ToastKind.success,
}) {
  final techno = context.techno;
  final (icon, color) = switch (kind) {
    ToastKind.success => (Icons.auto_awesome, techno.emeraude),
    ToastKind.error => (Icons.error_outline, techno.danger),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
