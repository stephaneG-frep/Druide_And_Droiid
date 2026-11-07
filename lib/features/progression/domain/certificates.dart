import '../../academie/domain/module_catalog.dart';
import 'learner_stats.dart';

const certificateDisclaimer =
    'Ce certificat interne atteste une progression dans l\'application Druide '
    'And-Droiīd. Ce n\'est ni un diplôme, ni une certification professionnelle '
    'officielle.';

class Certificate {
  const Certificate({
    required this.id,
    required this.title,
    required this.reason,
    required this.date,
  });

  final String id;
  final String title;
  final String reason;
  final DateTime date;
}

const grandDruideCertificate = 'grand-druide';

List<Certificate> certificatesFor(LearnerStats stats, LearningCatalog catalog) {
  final earned = <Certificate>[
    for (final module in academyModules)
      if (stats.moduleCompleted(catalog, module.id))
        Certificate(
          id: module.id,
          title: module.title,
          reason:
              'Toutes les leçons du module terminées, et son évaluation '
              'réussie.',
          date: stats.evaluationDates[module.id]!,
        ),
  ];
  final everything =
      catalog.lessonsByModule.isNotEmpty &&
      earned.length == catalog.lessonsByModule.length;
  if (everything && stats.finalValidated) {
    final dates = earned.map((item) => item.date).toList()..sort();
    earned.add(
      Certificate(
        id: grandDruideCertificate,
        title: 'Parcours complet de l\'Académie',
        reason:
            'Les douze modules terminés, et l\'évaluation finale validée par '
            'autoévaluation.',
        date: dates.last,
      ),
    );
  }
  return earned;
}
