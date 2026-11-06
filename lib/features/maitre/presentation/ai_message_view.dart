import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../design_system/code_highlighter.dart';
import '../../../design_system/code_panel.dart';
import '../../academie/presentation/lesson_blocks.dart';

sealed class MessagePart {
  const MessagePart();
}

class TextPart extends MessagePart {
  const TextPart(this.text);

  final String text;
}

class CodePart extends MessagePart {
  const CodePart(this.code, this.language);

  final String code;
  final CodeLanguage language;
}

CodeLanguage languageFor(String name) => switch (name.trim().toLowerCase()) {
  'kotlin' || 'kt' || 'kts' => CodeLanguage.kotlin,
  'java' => CodeLanguage.java,
  'dart' => CodeLanguage.dart,
  'xml' => CodeLanguage.xml,
  'cpp' || 'c++' || 'c' => CodeLanguage.cpp,
  'shell' || 'bash' || 'sh' => CodeLanguage.shell,
  _ => CodeLanguage.text,
};

/// Sépare le texte des blocs de code. Un bloc encore ouvert, pendant que la
/// réponse arrive, s'affiche déjà comme du code.
List<MessagePart> splitMessage(String message) {
  final parts = <MessagePart>[];
  final buffer = <String>[];
  CodeLanguage? language;

  void flush() {
    final text = buffer.join('\n');
    buffer.clear();
    if (language != null) {
      parts.add(CodePart(text, language));
    } else if (text.trim().isNotEmpty) {
      parts.add(TextPart(text.trim()));
    }
  }

  for (final line in message.split('\n')) {
    if (line.trimLeft().startsWith('```')) {
      flush();
      language = language == null
          ? languageFor(line.trimLeft().substring(3))
          : null;
    } else {
      buffer.add(line);
    }
  }
  flush();
  return parts;
}

/// Le code reçu reste du texte : il se lit et se copie, rien ne l'exécute.
class AiMessageView extends StatelessWidget {
  const AiMessageView(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          for (final part in splitMessage(message))
            switch (part) {
              TextPart(:final text) => RichLessonText(
                text,
                style: context.text.bodyMedium,
              ),
              CodePart(:final code, :final language) => CodePanel(
                code: code,
                language: language,
              ),
            },
        ],
      ),
    );
  }
}
