import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'features/parametres/presentation/appearance_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  await container.read(appearanceProvider.notifier).restore();

  runApp(
    UncontrolledProviderScope(container: container, child: const DruideApp()),
  );
}
