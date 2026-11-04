import '../../academie/domain/module_catalog.dart';

class ProjectTrack {
  const ProjectTrack(this.level, this.projects);

  final ModuleLevel level;
  final List<String> projects;
}

/// Parcours de projets (section 8 de SPEC.md).
const projectTracks = [
  ProjectTrack(ModuleLevel.debutant, [
    'Calculatrice',
    'Convertisseur',
    'Liste de tâches',
    'Chronomètre',
    'Application de notes',
  ]),
  ProjectTrack(ModuleLevel.intermediaire, [
    'Gestionnaire de fichiers',
    'Application météo',
    'Lecteur multimédia',
    'Application utilisant une API',
    'Gestionnaire de données locales',
  ]),
  ProjectTrack(ModuleLevel.avance, [
    'Application avec authentification',
    'Application avec synchronisation',
    'Application Flutter avec fonctions natives',
    'Application utilisant une IA',
    'Application avec notifications avancées',
  ]),
  ProjectTrack(ModuleLevel.expert, [
    'Application complète prête à publier',
    'Application Android native avec architecture avancée',
    'Application multiplateforme',
    'Application avec tests automatisés',
    'Projet professionnel documenté',
  ]),
];
