import 'package:flutter/material.dart';

import '../../../app/sections.dart';
import '../../../app/theme/app_theme.dart';
import '../../../design_system/grimoire_panel.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';

class GrimoirePage extends StatelessWidget {
  const GrimoirePage({super.key});

  @override
  Widget build(BuildContext context) {
    final body = context.text.bodyMedium;

    return PageFrame(
      title: AppSection.grimoire.label,
      children: [
        GrimoirePanel(
          title: 'Se déplacer dans l\'application',
          icon: Icons.explore_outlined,
          initiallyOpen: true,
          child: Text(
            'Utilisez la barre du bas sur téléphone, ou le rail à gauche sur '
            'ordinateur. L\'onglet Plus regroupe le Chaudron des Bugs, les '
            'Projets, la Progression, ce Grimoire et les Paramètres. Toucher '
            'à nouveau l\'onglet actif ramène à sa page de départ.',
            style: body,
          ),
        ),
        GrimoirePanel(
          title: 'Consulter le programme de l\'Académie',
          icon: Icons.school_outlined,
          child: Text(
            'Dans l\'onglet Académie, touchez un module pour lire son '
            'programme. Les leçons ne sont pas encore disponibles.',
            style: body,
          ),
        ),
        GrimoirePanel(
          title: 'Changer l\'apparence',
          icon: Icons.palette_outlined,
          child: Text(
            'Dans Plus, puis Paramètres, choisissez le thème sombre, clair ou '
            'celui du système. Vous pouvez aussi réduire ou désactiver les '
            'animations. Vos choix sont conservés au redémarrage.',
            style: body,
          ),
        ),
        const PhaseNotice(
          message:
              'Le Grimoire s\'enrichira à mesure que les fonctionnalités '
              'arriveront.',
        ),
      ],
    );
  }
}
