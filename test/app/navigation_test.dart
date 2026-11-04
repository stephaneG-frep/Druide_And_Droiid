import 'package:druide_and_droiid/app/app.dart';
import 'package:druide_and_droiid/app/router.dart';
import 'package:druide_and_droiid/app/sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const phone = Size(390, 844);
const desktop = Size(1280, 720);

Future<ProviderContainer> pumpApp(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const DruideApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

String location(ProviderContainer container) =>
    container.read(routerProvider).routeInformationProvider.value.uri.path;

void main() {
  testWidgets('démarre sur l\'accueil avec une barre basse sur téléphone', (
    tester,
  ) async {
    final container = await pumpApp(tester, phone);

    expect(location(container), AppSection.accueil.path);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
  });

  testWidgets('affiche un rail latéral sur grand écran', (tester) async {
    await pumpApp(tester, desktop);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('chaque onglet principal ouvre sa rubrique', (tester) async {
    final container = await pumpApp(tester, phone);

    for (final section in AppSection.primary.reversed) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(section.label),
        ),
      );
      await tester.pumpAndSettle();

      expect(location(container), section.path);
      expect(find.text(section.description), findsOneWidget);
      expect(
        find.textContaining('phase ${section.plannedPhase}'),
        findsOneWidget,
      );
    }
  });

  testWidgets('l\'onglet Plus donne accès à chaque rubrique secondaire', (
    tester,
  ) async {
    final container = await pumpApp(tester, phone);

    for (final section in AppSection.secondary) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Plus'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, section.label));
      await tester.pumpAndSettle();

      expect(location(container), section.path);
      expect(find.widgetWithText(AppBar, section.label), findsOneWidget);

      // Retoucher l'onglet Plus revient à la liste.
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Plus'),
        ),
      );
      await tester.pumpAndSettle();
      expect(location(container), plusPath);
    }
  });

  testWidgets('un onglet retrouve sa position au retour', (tester) async {
    final container = await pumpApp(tester, phone);

    container.read(routerProvider).go(AppSection.grimoire.path);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppSection.academie.label));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plus'));
    await tester.pumpAndSettle();

    expect(location(container), AppSection.grimoire.path);
  });

  testWidgets('un chemin inconnu affiche une page en français', (tester) async {
    final container = await pumpApp(tester, phone);

    container.read(routerProvider).go('/nulle-part');
    await tester.pumpAndSettle();
    expect(find.text('Page introuvable'), findsOneWidget);

    await tester.tap(find.text('Retour à l\'accueil'));
    await tester.pumpAndSettle();
    expect(location(container), AppSection.accueil.path);
  });

  testWidgets('tient sur un petit téléphone avec un grand texte', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpApp(tester, const Size(320, 568));

    expect(tester.takeException(), isNull);
  });
}
