import 'package:druide_and_droiid/app/sections.dart';
import 'package:druide_and_droiid/features/academie/presentation/paths.dart';
import 'package:druide_and_droiid/features/lab/presentation/lab_paths.dart';
import 'package:druide_and_droiid/features/maitre/presentation/ai_paths.dart';
import 'package:druide_and_droiid/features/projets/presentation/project_paths.dart';
import 'package:druide_and_droiid/features/sauvegarde/presentation/backup_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

/// Règles d'accessibilité de Flutter : cibles tactiles assez grandes et
/// nommées, contraste du texte. Elles ne remplacent pas un essai avec TalkBack.
final _routes = [
  AppSection.accueil.path,
  AppSection.academie.path,
  modulePath('kotlin'),
  lessonPath('kotlin', 'kotlin-01-bases'),
  AppSection.maitre.path,
  aiSettingsPath,
  AppSection.lab.path,
  labEditorPath('kt-niveau'),
  AppSection.chaudron.path,
  AppSection.projets.path,
  projectPath('calculatrice'),
  finalProjectPath,
  AppSection.progression.path,
  AppSection.notes.path,
  AppSection.grimoire.path,
  AppSection.parametres.path,
  backupPath,
];

void main() {
  for (final themeMode in [ThemeMode.dark, ThemeMode.light]) {
    for (final route in _routes) {
      testWidgets('${themeMode.name} : $route', (tester) async {
        final handle = tester.ensureSemantics();
        final container = await pumpApp(tester, themeMode: themeMode);
        await goTo(tester, container, route);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  }
}
