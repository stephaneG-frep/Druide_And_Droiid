import 'dart:io';

import 'package:drift/native.dart';
import 'package:druide_and_droiid/app/app.dart';
import 'package:druide_and_droiid/app/sections.dart';
import 'package:druide_and_droiid/core/persistence/app_database.dart';
import 'package:druide_and_droiid/core/security/secret_store.dart';
import 'package:druide_and_droiid/design_system/motion.dart';
import 'package:druide_and_droiid/features/parametres/domain/appearance.dart';
import 'package:druide_and_droiid/features/parametres/presentation/appearance_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('l\'application démarre et navigue sur la plateforme réelle', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // La boucle de la mascotte empêcherait pumpAndSettle de se terminer.
          initialAppearanceProvider.overrideWithValue(
            const Appearance(
              themeMode: ThemeMode.dark,
              motion: MotionLevel.none,
            ),
          ),
        ],
        child: const DruideApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bienvenue à l\'Académie !'), findsOneWidget);

    await tester.tap(find.text('Plus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppSection.chaudron.label));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(AppBar, AppSection.chaudron.label),
      findsOneWidget,
    );
  });

  test('SQLite conserve les données après réouverture du fichier', () async {
    final directory = await getTemporaryDirectory();
    final file = File(p.join(directory.path, 'druide_smoke.sqlite'));
    addTearDown(() async {
      if (file.existsSync()) await file.delete();
    });

    final first = AppDatabase(NativeDatabase(file));
    await first.writeMeta('smoke', 'persisté');
    await first.close();

    final second = AppDatabase(NativeDatabase(file));
    expect(await second.readMeta('smoke'), 'persisté');
    await second.close();
  });

  test('le coffre de la plateforme écrit, relit et efface un secret', () async {
    const store = SecretStore(FlutterSecureStorage());
    const name = 'druide_smoke_secret';

    await store.write(name, 'valeur-de-test');
    expect(await store.read(name), 'valeur-de-test');

    await store.delete(name);
    expect(await store.read(name), isNull);
  });
}
