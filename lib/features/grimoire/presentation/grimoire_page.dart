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
            'ordinateur. L\'onglet Plus regroupe vos Notes, le Chaudron des '
            'Bugs, les Projets, la Progression, ce Grimoire et les Paramètres. Toucher '
            'à nouveau l\'onglet actif ramène à sa page de départ.',
            style: body,
          ),
        ),
        GrimoirePanel(
          title: 'Consulter le programme de l\'Académie',
          icon: Icons.school_outlined,
          child: Text(
            'Dans l\'onglet Académie, touchez un module pour lire son '
            'programme. L\'étoile en haut de l\'écran l\'ajoute à vos favoris. '
            'Certains modules n\'ont encore que leur programme.',
            style: body,
          ),
        ),
        GrimoirePanel(
          title: 'Suivre une leçon',
          icon: Icons.menu_book_outlined,
          child: Text(
            'Ouvrez un module, puis une leçon. Lisez-la, répondez au quiz, '
            'faites les exercices, puis touchez Terminer la leçon. Vos '
            'réponses sont enregistrées : vous pouvez reprendre plus tard. '
            'Une fois toutes les leçons terminées, l\'évaluation du module '
            's\'ouvre. L\'accueil vous propose toujours la leçon suivante.',
            style: body,
          ),
        ),
        GrimoirePanel(
          title: 'Prendre des notes',
          icon: Icons.edit_note,
          child: Text(
            'Dans Plus, ouvrez Mes notes pour écrire une note libre. Depuis '
            'un module, le bouton Ajouter une note la rattache à ce module. '
            'Vos notes s\'enregistrent automatiquement pendant que vous '
            'écrivez et restent disponibles hors ligne.',
            style: body,
          ),
        ),
        GrimoirePanel(
          title: 'Gagner de l\'expérience',
          icon: Icons.bolt,
          child: Text(
            'Terminer une leçon, réussir un quiz ou une évaluation et valider '
            'un exercice rapportent de l\'expérience, une seule fois chacun. '
            'La question flash de l\'accueil en rapporte aussi chaque jour. '
            'Votre progression est conservée sur cet appareil.',
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
