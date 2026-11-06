import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_theme.dart';
import '../../../design_system/code_highlighter.dart';
import '../../../design_system/code_panel.dart';

const _codeStyle = TextStyle(
  fontFamily: fontCode,
  fontSize: 14,
  height: 1.5,
  color: Color(0xFFE6EAF6),
);

/// Contrôleur de texte qui colore le code pendant la frappe.
class CodeEditingController extends TextEditingController {
  CodeEditingController({required this.language, super.text});

  final CodeLanguage language;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return TextSpan(
      style: style,
      children: [
        for (final token in highlightCode(text, language))
          TextSpan(
            text: token.text,
            style: TextStyle(color: codeTokenColors[token.kind]),
          ),
      ],
    );
  }

  /// Remplace la sélection, pour la touche Tabulation.
  void insertAtCursor(String inserted) {
    final range = selection.isValid
        ? selection
        : TextSelection.collapsed(offset: text.length);
    value = value.copyWith(
      text: text.replaceRange(range.start, range.end, inserted),
      selection: TextSelection.collapsed(offset: range.start + inserted.length),
      composing: TextRange.empty,
    );
  }
}

/// Éditeur sans retour à la ligne automatique : les numéros restent alignés.
class CodeEditor extends StatelessWidget {
  const CodeEditor({
    required this.controller,
    required this.onChanged,
    this.readOnly = false,
    super.key,
  });

  final CodeEditingController controller;
  final ValueChanged<String> onChanged;
  final bool readOnly;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent ||
        event.logicalKey != LogicalKeyboardKey.tab ||
        HardwareKeyboard.instance.isShiftPressed) {
      return KeyEventResult.ignored;
    }
    controller.insertAtCursor('    ');
    onChanged(controller.text);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: codeBackground,
        shape: BeveledRectangleBorder(
          borderRadius: bevel,
          side: BorderSide(color: context.techno.border),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final count = '\n'.allMatches(controller.text).length + 1;
                  return Text(
                    [for (var i = 1; i <= count; i++) '$i'].join('\n'),
                    textAlign: TextAlign.right,
                    style: _codeStyle.copyWith(color: const Color(0xFF9AA6C8)),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: box.maxWidth),
                    child: IntrinsicWidth(
                      child: Focus(
                        onKeyEvent: _onKey,
                        child: TextField(
                          controller: controller,
                          onChanged: onChanged,
                          readOnly: readOnly,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          autocorrect: false,
                          enableSuggestions: false,
                          smartDashesType: SmartDashesType.disabled,
                          smartQuotesType: SmartQuotesType.disabled,
                          textCapitalization: TextCapitalization.none,
                          cursorColor: const Color(0xFF45DDFF),
                          style: _codeStyle,
                          decoration:
                              const InputDecoration.collapsed(hintText: '')
                                  .copyWith(
                                    labelText: null,
                                    semanticCounterText: 'Éditeur de code',
                                  ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
