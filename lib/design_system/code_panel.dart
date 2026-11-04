import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme/app_theme.dart';
import 'code_highlighter.dart';
import 'druide_toast.dart';

const codeBackground = Color(0xFF0A0E1C);
const _codeText = Color(0xFFE6EAF6);

const codeTokenColors = {
  CodeTokenKind.plain: _codeText,
  CodeTokenKind.keyword: Color(0xFFC3AEFF),
  CodeTokenKind.string: Color(0xFF3DE3AC),
  CodeTokenKind.number: Color(0xFFFFB955),
  CodeTokenKind.comment: Color(0xFF9AA6C8),
  CodeTokenKind.annotation: Color(0xFF45DDFF),
  CodeTokenKind.tag: Color(0xFFC3AEFF),
};

/// Affichage de code en lecture seule, toujours sur fond sombre.
class CodePanel extends StatelessWidget {
  const CodePanel({required this.code, required this.language, super.key});

  final String code;
  final CodeLanguage language;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) {
      showDruideToast(context, 'Code copié dans le presse-papiers.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lineCount = '\n'.allMatches(code).length + 1;
    const style = TextStyle(
      fontFamily: fontCode,
      fontSize: 13.5,
      height: 1.5,
      color: _codeText,
    );

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: codeBackground,
        shape: BeveledRectangleBorder(
          borderRadius: bevel,
          side: BorderSide(color: context.techno.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    language.label,
                    style: context.text.labelMedium!.copyWith(color: _codeText),
                  ),
                ),
                IconButton(
                  tooltip: 'Copier le code',
                  color: _codeText,
                  icon: const Icon(Icons.copy_outlined, size: 20),
                  onPressed: () => _copy(context),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Text(
                    [for (var i = 1; i <= lineCount; i++) '$i'].join('\n'),
                    textAlign: TextAlign.right,
                    style: style.copyWith(color: const Color(0xFF9AA6C8)),
                  ),
                ),
                const SizedBox(width: 16),
                SelectableText.rich(
                  TextSpan(
                    style: style,
                    children: [
                      for (final token in highlightCode(code, language))
                        TextSpan(
                          text: token.text,
                          style: TextStyle(color: codeTokenColors[token.kind]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
