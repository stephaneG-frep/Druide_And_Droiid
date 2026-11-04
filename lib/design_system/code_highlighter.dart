enum CodeLanguage {
  kotlin('Kotlin'),
  java('Java'),
  dart('Dart'),
  xml('XML');

  const CodeLanguage(this.label);

  final String label;
}

enum CodeTokenKind { plain, keyword, string, number, comment, annotation, tag }

class CodeToken {
  const CodeToken(this.kind, this.text);

  final CodeTokenKind kind;
  final String text;
}

const _keywords = <CodeLanguage, Set<String>>{
  CodeLanguage.kotlin: {
    'val',
    'var',
    'fun',
    'class',
    'object',
    'interface',
    'data',
    'sealed',
    'if',
    'else',
    'when',
    'for',
    'while',
    'return',
    'null',
    'true',
    'false',
    'override',
    'private',
    'public',
    'internal',
    'suspend',
    'import',
    'package',
    'is',
    'in',
    'as',
    'this',
    'super',
  },
  CodeLanguage.java: {
    'class',
    'interface',
    'extends',
    'implements',
    'new',
    'if',
    'else',
    'for',
    'while',
    'switch',
    'case',
    'return',
    'null',
    'true',
    'false',
    'public',
    'private',
    'protected',
    'static',
    'final',
    'void',
    'int',
    'boolean',
    'try',
    'catch',
    'throw',
    'import',
    'package',
    'this',
    'super',
  },
  CodeLanguage.dart: {
    'class',
    'extends',
    'with',
    'implements',
    'final',
    'const',
    'var',
    'void',
    'if',
    'else',
    'for',
    'while',
    'switch',
    'case',
    'return',
    'null',
    'true',
    'false',
    'async',
    'await',
    'import',
    'late',
    'required',
    'this',
    'super',
    'enum',
    'new',
  },
};

final _codePattern = RegExp(
  r'(?<comment>//[^\n]*|/\*[\s\S]*?\*/)'
  r'|(?<string>"(?:\\.|[^"\\\n])*"|'
  r"'(?:\\.|[^'\\\n])*')"
  r'|(?<annotation>@\w+)'
  r'|(?<number>\b\d+(?:\.\d+)?\b)'
  r'|(?<word>\b[A-Za-z_]\w*\b)',
);

final _xmlPattern = RegExp(
  r'(?<comment><!--[\s\S]*?-->)'
  r'|(?<string>"[^"]*")'
  r'|(?<tag></?[\w:.]+|/?>)'
  r'|(?<word>[\w:.]+(?==))',
);

/// Découpe [source] en jetons colorables ; leur concaténation redonne [source].
List<CodeToken> highlightCode(String source, CodeLanguage language) {
  final isXml = language == CodeLanguage.xml;
  final keywords = _keywords[language] ?? const <String>{};
  final tokens = <CodeToken>[];
  var cursor = 0;

  for (final match in (isXml ? _xmlPattern : _codePattern).allMatches(source)) {
    if (match.start > cursor) {
      tokens.add(
        CodeToken(CodeTokenKind.plain, source.substring(cursor, match.start)),
      );
    }

    final text = match[0]!;
    final kind = switch (match) {
      _ when match.namedGroup('comment') != null => CodeTokenKind.comment,
      _ when match.namedGroup('string') != null => CodeTokenKind.string,
      _ when isXml && match.namedGroup('tag') != null => CodeTokenKind.tag,
      _ when isXml => CodeTokenKind.annotation,
      _ when match.namedGroup('annotation') != null => CodeTokenKind.annotation,
      _ when match.namedGroup('number') != null => CodeTokenKind.number,
      _ when keywords.contains(text) => CodeTokenKind.keyword,
      _ => CodeTokenKind.plain,
    };
    tokens.add(CodeToken(kind, text));
    cursor = match.end;
  }

  if (cursor < source.length) {
    tokens.add(CodeToken(CodeTokenKind.plain, source.substring(cursor)));
  }
  return tokens;
}
