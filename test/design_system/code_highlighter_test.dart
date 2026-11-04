import 'package:druide_and_droiid/design_system/code_highlighter.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> textsOf(List<CodeToken> tokens, CodeTokenKind kind) => [
  for (final token in tokens)
    if (token.kind == kind) token.text,
];

void main() {
  test('les jetons reconstituent le code source pour chaque langage', () {
    const samples = {
      CodeLanguage.kotlin: 'val a = "x" // note\nfun f() = 1.5',
      CodeLanguage.java: '@Override public void f() { /* note */ int a = 1; }',
      CodeLanguage.dart: "final a = 'x'; // note",
      CodeLanguage.xml: '<!-- note --><a b="c">texte</a>',
      CodeLanguage.shell: '# note\nadb install -r "app.apk" # fin',
      CodeLanguage.text: 'app/\n├── src/   # Code',
    };

    for (final MapEntry(key: language, value: code) in samples.entries) {
      final rebuilt = highlightCode(code, language).map((t) => t.text).join();
      expect(rebuilt, code, reason: language.label);
    }
  });

  test('reconnaît les éléments du Kotlin', () {
    final tokens = highlightCode(
      'val nom = "if" // else\n@Composable\nval n = 42',
      CodeLanguage.kotlin,
    );

    expect(textsOf(tokens, CodeTokenKind.keyword), ['val', 'val']);
    expect(textsOf(tokens, CodeTokenKind.string), ['"if"']);
    expect(textsOf(tokens, CodeTokenKind.comment), ['// else']);
    expect(textsOf(tokens, CodeTokenKind.annotation), ['@Composable']);
    expect(textsOf(tokens, CodeTokenKind.number), ['42']);
  });

  test('un mot-clé d\'un autre langage reste du texte simple', () {
    final tokens = highlightCode('fun', CodeLanguage.java);

    expect(textsOf(tokens, CodeTokenKind.keyword), isEmpty);
  });

  test('reconnaît commentaires et chaînes du shell', () {
    final tokens = highlightCode(
      '# Installer\nadb shell "ls"\necho a#b',
      CodeLanguage.shell,
    );

    expect(textsOf(tokens, CodeTokenKind.comment), ['# Installer']);
    expect(textsOf(tokens, CodeTokenKind.string), ['"ls"']);
  });

  test('reconnaît les balises et attributs XML', () {
    final tokens = highlightCode(
      '<uses-permission android:name="x"/>'.replaceAll('-', '_'),
      CodeLanguage.xml,
    );

    expect(textsOf(tokens, CodeTokenKind.tag), ['<uses_permission', '/>']);
    expect(textsOf(tokens, CodeTokenKind.annotation), ['android:name']);
    expect(textsOf(tokens, CodeTokenKind.string), ['"x"']);
  });
}
