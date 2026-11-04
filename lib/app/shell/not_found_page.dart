import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/arcane_button.dart';
import '../../design_system/mascot/maitre_and_droiid.dart';
import '../../design_system/page_frame.dart';
import '../sections.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({required this.uri, super.key});

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Page introuvable',
      children: [
        const Center(
          child: MaitreAndDroiid(width: 96, mood: MascotMood.surpris),
        ),
        Text('Ce chemin n\'existe pas : $uri', textAlign: TextAlign.center),
        Center(
          child: ArcaneButton(
            label: 'Retour à l\'accueil',
            onPressed: () => context.go(AppSection.accueil.path),
          ),
        ),
      ],
    );
  }
}
