import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../sections.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({required this.uri, super.key});

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page introuvable')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ce chemin n\'existe pas : $uri',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go(AppSection.accueil.path),
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
