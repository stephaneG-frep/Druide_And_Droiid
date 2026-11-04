import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/mascot/maitre_and_droiid.dart';
import '../sections.dart';

/// Taille à partir de laquelle la barre basse cède la place au rail latéral.
/// La hauteur minimale écarte les téléphones en paysage, où le rail déborderait.
const wideLayoutMinWidth = 840.0;
const wideLayoutMinHeight = 560.0;

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
    final size = MediaQuery.sizeOf(context);
    final isWide =
        size.width >= wideLayoutMinWidth && size.height >= wideLayoutMinHeight;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                selectedIndex: shell.currentIndex,
                onDestinationSelected: _select,
                labelType: NavigationRailLabelType.all,
                leading: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: MaitreAndDroiid(width: 52),
                ),
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
