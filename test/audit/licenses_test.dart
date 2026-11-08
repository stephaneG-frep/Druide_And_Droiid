import 'dart:io';

import 'package:druide_and_droiid/app/licenses.dart';
import 'package:druide_and_droiid/app/sections.dart';
import 'package:druide_and_droiid/design_system/arcane_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('la version affichée suit celle de pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version: ([^+\s]+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);
    expect(appVersion, version);
  });

  test('les licences des polices sont lisibles et enregistrées', () async {
    registerFontLicenses();
    final entries = await LicenseRegistry.licenses.toList();
    for (final font in fontLicenses.keys) {
      final entry = entries.firstWhere((e) => e.packages.contains(font));
      final text = entry.paragraphs.map((p) => p.text).join('\n');
      expect(text, contains('SIL OPEN FONT LICENSE'), reason: font);
    }
  });

  testWidgets('les paramètres ouvrent l\'écran des licences', (tester) async {
    final container = await pumpApp(tester);
    await goTo(tester, container, AppSection.parametres.path);
    final button = find.widgetWithText(ArcaneButton, 'Licences');
    await tester.scrollUntilVisible(button, 200);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    // L'écran charge les licences en arrière-plan : pas de pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(LicensePage), findsOneWidget);
  });
}
