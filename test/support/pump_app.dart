import 'package:drift/native.dart';
import 'package:druide_and_droiid/app/app.dart';
import 'package:druide_and_droiid/app/router.dart';
import 'package:druide_and_droiid/core/persistence/app_database.dart';
import 'package:druide_and_droiid/design_system/motion.dart';
import 'package:druide_and_droiid/features/parametres/domain/appearance.dart';
import 'package:druide_and_droiid/features/parametres/presentation/appearance_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const phone = Size(390, 844);
const desktop = Size(1280, 720);

/// Lance l'application complète sur une base en mémoire, animations coupées :
/// la boucle de la mascotte empêcherait `pumpAndSettle` de se terminer.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  Size size = phone,
  ThemeMode themeMode = ThemeMode.dark,
  MotionLevel motion = MotionLevel.none,
  AppDatabase? database,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      initialAppearanceProvider.overrideWithValue(
        Appearance(themeMode: themeMode, motion: motion),
      ),
      appDatabaseProvider.overrideWith((ref) {
        final db = database ?? AppDatabase(NativeDatabase.memory());
        ref.onDispose(db.close);
        return db;
      }),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const DruideApp()),
  );
  if (motion == MotionLevel.none) await tester.pumpAndSettle();
  return container;
}

String location(ProviderContainer container) =>
    container.read(routerProvider).routeInformationProvider.value.uri.path;

Future<void> goTo(
  WidgetTester tester,
  ProviderContainer container,
  String path,
) async {
  container.read(routerProvider).go(path);
  await tester.pumpAndSettle();
}
