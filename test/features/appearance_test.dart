import 'package:drift/native.dart';
import 'package:druide_and_droiid/app/app.dart';
import 'package:druide_and_droiid/app/sections.dart';
import 'package:druide_and_droiid/core/persistence/app_database.dart';
import 'package:druide_and_droiid/design_system/motion.dart';
import 'package:druide_and_droiid/features/parametres/data/appearance_repository.dart';
import 'package:druide_and_droiid/features/parametres/domain/appearance.dart';
import 'package:druide_and_droiid/features/parametres/presentation/appearance_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

class _FailingRepository implements AppearanceRepository {
  @override
  Future<Appearance> load() async => throw Exception('disque illisible');

  @override
  Future<void> save(Appearance appearance) async {
    throw Exception('disque plein');
  }
}

void main() {
  group('AppearanceRepository', () {
    late AppDatabase database;

    setUp(() => database = AppDatabase(NativeDatabase.memory()));
    tearDown(() => database.close());

    test('renvoie les valeurs par défaut sans réglage enregistré', () async {
      final loaded = await AppearanceRepository(database).load();

      expect(loaded.themeMode, Appearance.defaults.themeMode);
      expect(loaded.motion, Appearance.defaults.motion);
    });

    test('relit ce qui a été enregistré', () async {
      final repository = AppearanceRepository(database);
      await repository.save(
        const Appearance(
          themeMode: ThemeMode.light,
          motion: MotionLevel.reduced,
        ),
      );

      final loaded = await repository.load();
      expect(loaded.themeMode, ThemeMode.light);
      expect(loaded.motion, MotionLevel.reduced);
    });

    test('ignore une valeur enregistrée invalide', () async {
      await database.writeMeta('appearance.theme', 'violet-fluo');

      final loaded = await AppearanceRepository(database).load();
      expect(loaded.themeMode, Appearance.defaults.themeMode);
    });
  });

  group('AppearanceController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          appearanceRepositoryProvider.overrideWithValue(_FailingRepository()),
        ],
      );
      addTearDown(container.dispose);
    });

    test('garde les valeurs par défaut si la lecture échoue', () async {
      await container.read(appearanceProvider.notifier).restore();

      expect(
        container.read(appearanceProvider).themeMode,
        Appearance.defaults.themeMode,
      );
    });

    test('applique le réglage et signale l\'échec d\'écriture', () async {
      final saved = await container
          .read(appearanceProvider.notifier)
          .setThemeMode(ThemeMode.light);

      expect(saved, isFalse);
      expect(container.read(appearanceProvider).themeMode, ThemeMode.light);
    });
  });

  group('Écran Paramètres', () {
    testWidgets('le thème choisi s\'applique et survit à un redémarrage', (
      tester,
    ) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final container = ProviderContainer(
        overrides: [
          initialAppearanceProvider.overrideWithValue(
            const Appearance(
              themeMode: ThemeMode.dark,
              motion: MotionLevel.none,
            ),
          ),
          appDatabaseProvider.overrideWithValue(database),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const DruideApp(),
        ),
      );
      await tester.pumpAndSettle();
      await goTo(tester, container, AppSection.parametres.path);

      await tester.tap(find.text('Clair'));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.text('Clair'))).brightness,
        Brightness.light,
      );

      // Un nouveau conteneur simule le redémarrage sur la même base.
      await tester.runAsync(() async {
        final restarted = ProviderContainer(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
        );
        addTearDown(restarted.dispose);
        await restarted.read(appearanceProvider.notifier).restore();
        expect(restarted.read(appearanceProvider).themeMode, ThemeMode.light);
      });
    });

    testWidgets('choisir « Aucune » coupe l\'animation de la mascotte', (
      tester,
    ) async {
      final container = await pumpApp(tester, motion: MotionLevel.full);
      await tester.pump(const Duration(milliseconds: 100));

      await container
          .read(appearanceProvider.notifier)
          .setMotion(MotionLevel.none);
      await tester.pumpAndSettle();

      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('la réduction système prime sur le réglage', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await pumpApp(tester, motion: MotionLevel.full);
      await tester.pumpAndSettle();

      expect(tester.binding.transientCallbackCount, 0);
    });
  });
}
