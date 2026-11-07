class FinalCriterion {
  const FinalCriterion(this.name, this.maximum);

  final String name;
  final int maximum;
}

/// Grille de la leçon « Projet final » du module Expert Android.
const finalCriteria = [
  FinalCriterion('Utilité réelle', 15),
  FinalCriterion('Architecture', 20),
  FinalCriterion('Données et API', 15),
  FinalCriterion('Sécurité', 15),
  FinalCriterion('Tests', 15),
  FinalCriterion('Optimisation', 10),
  FinalCriterion('Livraison et documentation', 10),
];

const finalPassMark = 70;
const finalMinimumRequired = 10;
const _required = {'Sécurité', 'Tests'};

class FinalEntry {
  const FinalEntry(this.score, this.proof);

  final int score;
  final String proof;
}

class FinalResult {
  const FinalResult({required this.total, required this.validated});

  final int total;
  final bool validated;
}

/// Une note sans preuve vaut zéro, et aucune note ne dépasse son maximum.
int countedScore(FinalCriterion criterion, FinalEntry? entry) {
  if (entry == null || entry.proof.trim().isEmpty) return 0;
  return entry.score.clamp(0, criterion.maximum);
}

FinalResult evaluateFinal(Map<String, FinalEntry> entries) {
  var total = 0;
  var required = true;
  for (final criterion in finalCriteria) {
    final score = countedScore(criterion, entries[criterion.name]);
    total += score;
    if (_required.contains(criterion.name) && score < finalMinimumRequired) {
      required = false;
    }
  }
  return FinalResult(
    total: total,
    validated: total >= finalPassMark && required,
  );
}
