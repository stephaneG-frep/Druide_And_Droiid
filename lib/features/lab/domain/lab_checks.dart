import 'package:xml/xml.dart';

String _normalize(String text) =>
    text.trim().split('\n').map((line) => line.trimRight()).join('\n');

/// Compare une sortie réelle à la sortie attendue, sans les espaces de fin.
bool outputMatches(String actual, String expected) =>
    _normalize(actual) == _normalize(expected);

class XmlCheck {
  const XmlCheck({this.error, this.missing = const []});

  final String? error;
  final List<String> missing;

  bool get wellFormed => error == null;
  bool get complete => wellFormed && missing.isEmpty;
}

/// Vraie analyse du XML, disponible sur toutes les plateformes. Elle vérifie la
/// syntaxe, pas la validité pour Android : seul `aapt2` en serait capable.
XmlCheck checkXml(String code, List<String> required) {
  try {
    XmlDocument.parse(code);
  } on XmlException catch (error) {
    return XmlCheck(error: error.message);
  }
  return XmlCheck(
    missing: [
      for (final element in required)
        if (!code.contains(element)) element,
    ],
  );
}
