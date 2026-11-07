/// Limite du texte envoyé à une IA : un journal entier coûterait cher, et
/// l'erreur tient presque toujours en quelques lignes.
const maxDiagnosisChars = 16000;

class Redaction {
  const Redaction(this.text, this.count);

  final String text;
  final int count;
}

final _secretPatterns = <(RegExp, String)>[
  (RegExp(r'sk-[A-Za-z0-9_-]{16,}'), '[clé masquée]'),
  (RegExp(r'AIza[0-9A-Za-z_-]{20,}'), '[clé masquée]'),
  (RegExp(r'gh[pousr]_[A-Za-z0-9]{20,}'), '[clé masquée]'),
  (RegExp(r'github_pat_[A-Za-z0-9_]{20,}'), '[clé masquée]'),
  (
    RegExp(r'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]+'),
    '[jeton masqué]',
  ),
  (RegExp(r'[Bb]earer\s+[A-Za-z0-9._~+/=-]{8,}'), 'Bearer [jeton masqué]'),
  (
    RegExp(
      r'''((?:api[_-]?key|apikey|password|passwd|pwd|secret|token|storePassword|keyPassword)["']?\s*[=:]\s*)["']?[^\s"',;]+''',
      caseSensitive: false,
    ),
    r'$1[masqué]',
  ),
  (RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+'), '[courriel]'),
  (RegExp(r'/home/[^/\s]+'), '/home/[utilisateur]'),
  (RegExp(r'/Users/[^/\s]+'), '/Users/[utilisateur]'),
];

/// Masque ce qui ressemble à un secret ou à une donnée personnelle. Filtre
/// utile mais imparfait : l'utilisateur relit toujours avant l'envoi.
Redaction redactSecrets(String text) {
  var result = text;
  var count = 0;
  for (final (pattern, replacement) in _secretPatterns) {
    result = result.replaceAllMapped(pattern, (match) {
      count++;
      return replacement.startsWith(r'$1')
          ? '${match[1]}${replacement.substring(2)}'
          : replacement;
    });
  }
  return Redaction(result, count);
}

final _important = RegExp(
  r'error|exception|fail|fatal|caused by|what went wrong|denied|'
  r'\bE/|\bE \w|\bF/|signal \d|anr in',
  caseSensitive: false,
);

/// Réduit un journal aux lignes utiles, avec leur voisinage, en gardant le début
/// du résultat : la première erreur compte le plus.
String extractRelevant(String log, {int maxChars = maxDiagnosisChars}) {
  if (log.length <= maxChars) return log;

  final lines = log.split('\n');
  final kept = <int>{};
  for (var index = 0; index < lines.length; index++) {
    if (_important.hasMatch(lines[index])) {
      for (var near = index - 1; near <= index + 2; near++) {
        if (near >= 0 && near < lines.length) kept.add(near);
      }
    }
  }
  if (kept.isEmpty) return log.substring(log.length - maxChars);

  final sorted = kept.toList()..sort();
  final buffer = StringBuffer();
  var previous = -1;
  for (final index in sorted) {
    if (previous != -1 && index != previous + 1) buffer.writeln('[…]');
    if (buffer.length + lines[index].length > maxChars) break;
    buffer.writeln(lines[index]);
    previous = index;
  }
  return buffer.toString().trimRight();
}

String titleFromError(String error, String description) {
  final source = description.trim().isNotEmpty ? description : error;
  final line = source.trim().split('\n').first.trim();
  if (line.isEmpty) return 'Dossier sans titre';
  return line.length <= 70 ? line : '${line.substring(0, 70)}…';
}

/// Rien n'est résolu tant qu'une vérification n'a pas été notée.
enum BugStatus {
  open('Non vérifié'),
  verified('Vérification réussie'),
  stillBroken('Toujours en panne');

  const BugStatus(this.label);

  final String label;

  static BugStatus byName(String name) => BugStatus.values.firstWhere(
    (status) => status.name == name,
    orElse: () => open,
  );
}
