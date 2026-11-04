import 'package:flutter/material.dart';

import '../../../app/sections.dart';
import '../../../app/theme/app_theme.dart';
import '../../../design_system/code_highlighter.dart';
import '../../../design_system/code_panel.dart';
import '../../../design_system/console_panel.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';

const _example = '''
// Calcule le niveau d'un apprenti à partir de ses points
fun niveau(points: Int): String {
    val paliers = listOf(100, 300, 600)
    val rang = paliers.count { points >= it }
    return "Niveau \${rang + 1}"
}

fun main() {
    println(niveau(350))
}''';

class LabPage extends StatelessWidget {
  const LabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: AppSection.lab.label,
      children: [
        Text(
          'Votre paillasse de code : lisez un exemple, puis copiez-le pour '
          'l\'essayer dans votre propre projet.',
          style: context.text.bodyLarge,
        ),
        const PhaseNotice(
          message:
              'L\'éditeur et les exercices ne sont pas encore disponibles. '
              'Le code ci-dessous peut être lu et copié, mais pas exécuté ici.',
        ),
        const SectionTitle('Exemple Kotlin'),
        const CodePanel(code: _example, language: CodeLanguage.kotlin),
        const ConsolePanel(
          title: 'Résultat attendu (rédigé à la main, non exécuté)',
          lines: [ConsoleLine(ConsoleLineKind.output, 'Niveau 3')],
        ),
      ],
    );
  }
}
