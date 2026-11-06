enum DiffKind { same, added, removed }

class DiffLine {
  const DiffLine(this.kind, this.text);

  final DiffKind kind;
  final String text;
}

/// Au-delà, la comparaison serait trop lente pour un écran de téléphone.
const maxDiffLines = 3000;

/// Comparaison ligne à ligne, par plus longue sous-suite commune.
List<DiffLine> diffLines(String before, String after) {
  final a = before.split('\n');
  final b = after.split('\n');
  if (a.length > maxDiffLines || b.length > maxDiffLines) {
    return [
      for (final line in a) DiffLine(DiffKind.removed, line),
      for (final line in b) DiffLine(DiffKind.added, line),
    ];
  }

  final table = List.generate(
    a.length + 1,
    (_) => List<int>.filled(b.length + 1, 0),
  );
  for (var i = a.length - 1; i >= 0; i--) {
    for (var j = b.length - 1; j >= 0; j--) {
      table[i][j] = a[i] == b[j]
          ? table[i + 1][j + 1] + 1
          : (table[i + 1][j] > table[i][j + 1]
                ? table[i + 1][j]
                : table[i][j + 1]);
    }
  }

  final lines = <DiffLine>[];
  var i = 0;
  var j = 0;
  while (i < a.length && j < b.length) {
    if (a[i] == b[j]) {
      lines.add(DiffLine(DiffKind.same, a[i]));
      i++;
      j++;
    } else if (table[i + 1][j] >= table[i][j + 1]) {
      lines.add(DiffLine(DiffKind.removed, a[i++]));
    } else {
      lines.add(DiffLine(DiffKind.added, b[j++]));
    }
  }
  while (i < a.length) {
    lines.add(DiffLine(DiffKind.removed, a[i++]));
  }
  while (j < b.length) {
    lines.add(DiffLine(DiffKind.added, b[j++]));
  }
  return lines;
}
