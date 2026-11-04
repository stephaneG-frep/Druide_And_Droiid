import 'package:druide_and_droiid/app/router.dart';
import 'package:druide_and_droiid/app/sections.dart';
import 'package:druide_and_droiid/features/academie/domain/module_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

Finder inNavigationBar(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  testWidgets('démarre sur l\'accueil avec une barre basse sur téléphone', (
    tester,
  ) async {
    final container = await pumpApp(tester);

    expect(location(container), AppSection.accueil.path);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
  });

  testWidgets('affiche un rail latéral sur grand écran', (tester) async {
    await pumpApp(tester, size: desktop);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('chaque onglet principal ouvre sa rubrique', (tester) async {
    final container = await pumpApp(tester);

    for (final section in AppSection.primary.reversed) {
      await tester.tap(inNavigationBar(section.label));
      await tester.pumpAndSettle();

      expect(location(container), section.path);
      expect(find.widgetWithText(AppBar, section.label), findsOneWidget);
    }
  });

  testWidgets('l\'onglet Plus donne accès à chaque rubrique secondaire', (
    tester,
  ) async {
    final container = await pumpApp(tester);

    for (final section in AppSection.secondary) {
      await tester.tap(inNavigationBar('Plus'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(section.label));
      await tester.pumpAndSettle();

      expect(location(container), section.path);
      expect(find.widgetWithText(AppBar, section.label), findsOneWidget);

      // Retoucher l'onglet Plus revient à la liste.
      await tester.tap(inNavigationBar('Plus'));
      await tester.pumpAndSettle();
      expect(location(container), plusPath);
    }
  });

  testWidgets('un onglet retrouve sa position au retour', (tester) async {
    final container = await pumpApp(tester);

    await goTo(tester, container, AppSection.grimoire.path);
    await tester.tap(inNavigationBar(AppSection.academie.label));
    await tester.pumpAndSettle();
    await tester.tap(inNavigationBar('Plus'));
    await tester.pumpAndSettle();

    expect(location(container), AppSection.grimoire.path);
  });

  testWidgets('une carte de module ouvre son programme et permet le retour', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    final module = academyModules.first;

    await tester.tap(inNavigationBar(AppSection.academie.label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(module.title));
    await tester.pumpAndSettle();

    expect(location(container), '${AppSection.academie.path}/${module.id}');
    expect(find.text('Au programme'), findsOneWidget);
    expect(find.text(module.topics.first), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(location(container), AppSection.academie.path);
  });

  testWidgets('les raccourcis de l\'accueil mènent à leur rubrique', (
    tester,
  ) async {
    final container = await pumpApp(tester);

    await tester.tap(find.text('Découvrir l\'Académie'));
    await tester.pumpAndSettle();
    expect(location(container), AppSection.academie.path);

    await tester.tap(inNavigationBar(AppSection.accueil.label));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(AppSection.chaudron.label),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text(AppSection.chaudron.label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppSection.chaudron.label));
    await tester.pumpAndSettle();
    expect(location(container), AppSection.chaudron.path);
  });

  testWidgets('un chemin inconnu affiche une page en français', (tester) async {
    final container = await pumpApp(tester);

    await goTo(tester, container, '/nulle-part');
    expect(find.text('Page introuvable'), findsOneWidget);

    await tester.tap(find.text('Retour à l\'accueil'));
    await tester.pumpAndSettle();
    expect(location(container), AppSection.accueil.path);
  });

  testWidgets('un module inconnu affiche la page introuvable', (tester) async {
    final container = await pumpApp(tester);

    await goTo(tester, container, '${AppSection.academie.path}/fantome');

    expect(find.text('Page introuvable'), findsOneWidget);
  });
}
