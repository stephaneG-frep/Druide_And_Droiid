import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../sections.dart';

class PlusPage extends StatelessWidget {
  const PlusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plus')),
      body: ListView(
        children: [
          for (final section in AppSection.secondary)
            ListTile(
              leading: Icon(section.icon),
              title: Text(section.label),
              subtitle: Text(section.description),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(section.path),
            ),
        ],
      ),
    );
  }
}
