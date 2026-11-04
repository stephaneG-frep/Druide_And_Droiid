import 'package:druide_and_droiid/app/router.dart';
import 'package:druide_and_droiid/app/sections.dart';
import 'package:druide_and_droiid/features/academie/domain/module_catalog.dart';
import 'package:druide_and_droiid/features/academie/presentation/paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

const _layouts = {
  'petit téléphone': Size(320, 568),
  'téléphone': phone,
  'paysage': Size(844, 390),
  'tablette': Size(820, 1180),
  'ordinateur': desktop,
  'grand écran': Size(2560, 1440),
};

final _routes = [
  for (final section in AppSection.values) section.path,
  plusPath,
  '${AppSection.academie.path}/${academyModules.last.id}',
  '${AppSection.academie.path}/${academyModules.first.id}',
  lessonPath(academyModules.first.id, 'fondations-03-architecture'),
  evaluationPath(academyModules.first.id),
];

void main() {
  for (final MapEntry(key: name, value: size) in _layouts.entries) {
    for (final themeMode in [ThemeMode.dark, ThemeMode.light]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('${themeMode.name}, $name, texte × $scale', (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          final container = await pumpApp(
            tester,
            size: size,
            themeMode: themeMode,
          );

          // Un débordement ferait échouer le test via FlutterError.
          for (final route in _routes) {
            await goTo(tester, container, route);
            expect(tester.takeException(), isNull, reason: route);
          }
        });
      }
    }
  }
}
