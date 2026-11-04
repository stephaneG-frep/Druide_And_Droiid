import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/page_frame.dart';
import '../../design_system/techno_card.dart';
import '../sections.dart';
import '../theme/app_theme.dart';

class PlusPage extends StatelessWidget {
  const PlusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final techno = context.techno;

    return PageFrame(
      title: 'Plus',
      children: [
        for (final section in AppSection.secondary)
          TechnoCard(
            padding: EdgeInsets.zero,
            onTap: () => context.go(section.path),
            child: ListTile(
              leading: Icon(section.icon, color: techno.cyan),
              title: Text(section.label),
              subtitle: Text(section.description),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
      ],
    );
  }
}
