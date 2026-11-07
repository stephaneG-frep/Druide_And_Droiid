import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/licenses.dart';
import 'features/parametres/presentation/appearance_controller.dart';
import 'features/sauvegarde/data/auto_backup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();

  final container = ProviderContainer();
  await container.read(appearanceProvider.notifier).restore();

  runApp(
    UncontrolledProviderScope(container: container, child: const DruideApp()),
  );

  // Une copie de sécurité par jour d'utilisation, sans retarder le démarrage.
  unawaited(
    container
        .read(autoBackupsProvider)
        .runIfDue()
        .then<void>(
          (_) {},
          onError: (Object error) =>
              debugPrint('Copie de sécurité impossible : $error'),
        ),
  );
}
