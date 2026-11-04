import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../sections.dart';

/// Largeur à partir de laquelle la barre basse cède la place au rail latéral.
const wideLayoutBreakpoint = 840.0;

/// Coque de navigation : barre basse sur téléphone, rail latéral sur ordinateur.
class AppShell extends StatelessWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  static final _tabs = [
    for (final section in AppSection.primary) (section.label, section.icon),
    ('Plus', Icons.more_horiz),
  ];

  void _select(int index) {
    // Retoucher l'onglet courant ramène à sa racine.
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= wideLayoutBreakpoint;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                selectedIndex: shell.currentIndex,
                onDestinationSelected: _select,
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final (label, icon) in _tabs)
                    NavigationRailDestination(
                      icon: Icon(icon),
                      label: Text(label),
                    ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: shell),
          ],
        ),
      );
    }

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _select,
        destinations: [
          for (final (label, icon) in _tabs)
            NavigationDestination(icon: Icon(icon), label: label),
        ],
      ),
    );
  }
}
