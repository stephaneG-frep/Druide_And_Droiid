import 'package:flutter/material.dart';

/// Rubriques du Grimoire du Druide. L'aide contextuelle des écrans complexes
/// renvoie à l'une d'elles : un seul texte à tenir à jour.
enum GrimoireTopic {
  navigation('Se déplacer dans l\'application', Icons.explore_outlined, [
    'Sur téléphone, utilisez la barre du bas. Sur ordinateur, le rail à gauche '
        'de la fenêtre.',
    'L\'onglet Plus regroupe Mes notes, le Chaudron des Bugs, les Projets, la '
        'Progression, ce Grimoire et les Paramètres. Toucher à nouveau l\'onglet '
        'actif ramène à sa page de départ.',
    'Le bouton d\'aide, en haut des écrans les plus riches, ouvre directement '
        'la bonne rubrique de ce Grimoire.',
  ]),
  formation('Suivre une formation', Icons.school_outlined, [
    'Dans l\'Académie, ouvrez un module, puis une leçon. Lisez-la, répondez à '
        'son quiz, faites ses exercices, puis touchez Terminer la leçon. Vos '
        'réponses sont enregistrées : vous pouvez reprendre plus tard.',
    'Un quiz se réussit à 70 %. Une fois toutes les leçons terminées, '
        'l\'évaluation du module s\'ouvre : elle se réussit à 80 %.',
    'Dans Progression, choisissez un parcours selon votre objectif. Le bouton '
        'Continuer ouvre la prochaine leçon à suivre.',
  ]),
  exercices('Réaliser les exercices', Icons.edit_note, [
    'Une réponse courte se corrige automatiquement avec Vérifier. Les '
        'majuscules ne comptent pas.',
    'Une réponse libre se compare au corrigé : c\'est vous qui indiquez si '
        'vous avez réussi. Avec un fournisseur IA, Corriger avec le Maître '
        'donne un avis détaillé.',
  ]),
  ia('Utiliser l\'IA', Icons.smart_toy_outlined, [
    'Dans Maître, choisissez ce que vous voulez faire, puis ouvrez une '
        'conversation. Les réponses arrivent progressivement, et Arrêter coupe '
        'la réponse en cours.',
    'Une IA peut se tromper. Relisez toujours son code : l\'application ne '
        'l\'exécute jamais à votre place.',
    'Avant le premier envoi vers un service externe, l\'application demande '
        'votre accord. Selon votre abonnement, chaque réponse peut être '
        'facturée sur votre compte.',
  ]),
  fournisseurs('Configurer les fournisseurs', Icons.tune, [
    'Dans Plus, Paramètres, Réglages du Maître, choisissez Anthropic Claude, '
        'OpenAI, Google Gemini, Ollama ou une API compatible avec OpenAI.',
    'Saisissez votre clé si le service en demande une. Elle reste dans le '
        'stockage sécurisé de l\'appareil, n\'est jamais affichée et n\'entre '
        'jamais dans une sauvegarde.',
    'Tester la connexion liste les modèles, sans générer de réponse. Choisissez '
        'un modèle, puis touchez Enregistrer et activer : seul ce bouton change '
        'le fournisseur actif.',
    'Avec Ollama sur téléphone, reliez le câble USB puis lancez sur '
        'l\'ordinateur : adb reverse tcp:11434 tcp:11434. Ce lien disparaît à '
        'chaque débranchement.',
  ]),
  lab('Utiliser Android Lab', Icons.science_outlined, [
    'Le code s\'enregistre tout seul. Enregistrer une version le garde dans '
        'l\'Historique, d\'où vous pouvez le comparer ou y revenir.',
    'Sur Linux, Exécuter utilise les vrais compilateurs de la machine, avec vos '
        'droits : ce n\'est pas un bac à sable. N\'exécutez que du code que vous '
        'avez lu et compris.',
    'Sur téléphone, le code Kotlin, Java et Dart ne s\'exécute pas : aucun '
        'compilateur n\'y tourne, et le Lab ne simule rien. Le XML, lui, est '
        'réellement analysé.',
  ]),
  linux('Utiliser les outils Linux', Icons.build_outlined, [
    'Dans Lab, Outils Linux indique les outils trouvés sur la machine, avec la '
        'procédure d\'installation des autres. L\'application n\'installe rien '
        'elle-même.',
    'Seules des commandes prévues à l\'avance sont proposées. Ouvrir Android '
        'Studio ou démarrer un émulateur demande une confirmation.',
  ]),
  logs('Importer des logs', Icons.bug_report_outlined, [
    'Dans le Chaudron des Bugs, collez une erreur ou touchez Importer un '
        'fichier. Pour un très long fichier, seule sa fin est lue.',
    'Sur Linux, Lire les plantages (ADB) récupère le tampon des plantages du '
        'téléphone branché.',
    'Les fiches reconnues sont rédigées à l\'avance, sans IA. Avant une analyse '
        'IA, vous relisez exactement ce qui part : les secrets repérés sont '
        'masqués, mais ce filtre est imparfait.',
    'Un dossier reste Non vérifié tant que vous n\'avez pas noté le résultat '
        'd\'un essai.',
  ]),
  projets('Suivre un projet', Icons.construction_outlined, [
    'Chaque projet se réalise dans Android Studio ou votre éditeur. Cochez une '
        'étape quand vous avez observé ce qu\'elle demande.',
    'Valider le projet exige toutes les étapes, le questionnaire, tous les '
        'critères et une preuve écrite. C\'est une autoévaluation.',
    'L\'évaluation finale se note sur 100 : une note sans preuve compte pour '
        'zéro.',
  ]),
  progression('Progresser', Icons.bolt, [
    'Chaque action ne rapporte de l\'expérience qu\'une fois. Les badges restent '
        'acquis, et les défis se réclament une fois accomplis.',
    'Les certificats sont internes à l\'application : ce ne sont ni des '
        'diplômes, ni des certifications professionnelles officielles.',
  ]),
  exports('Exporter des documents', Icons.picture_as_pdf_outlined, [
    'Un module de l\'Académie, vos notes, une fiche de projet et un certificat '
        's\'exportent en PDF, depuis leur écran.',
    'Vos réponses aux exercices et votre code du Lab s\'exportent en Markdown, '
        'depuis Paramètres, Sauvegardes.',
    'Sur téléphone, le sélecteur du système vous laisse choisir l\'emplacement. '
        'Sur Linux, une boîte de dialogue s\'ouvre ; à défaut, le fichier va '
        'dans Téléchargements, sous Druide And-Droiid.',
  ]),
  sauvegarder('Sauvegarder vos données', Icons.save_outlined, [
    'Tout s\'enregistre automatiquement sur l\'appareil : fermer ou redémarrer '
        'l\'application ne perd rien.',
    'Chaque jour d\'utilisation, une copie de sécurité est créée dans le dossier '
        'privé de l\'application. Les cinq plus récentes sont gardées. Elles '
        'disparaissent avec l\'application : pour vous protéger d\'une '
        'désinstallation, exportez une sauvegarde ailleurs.',
    'Dans Paramètres, Sauvegardes, Exporter en JSON crée un fichier à '
        'conserver. Sauvegarde complète crée une archive ZIP, avec en plus vos '
        'notes et votre code dans des fichiers lisibles.',
    'Les clés d\'API ne sont jamais sauvegardées.',
  ]),
  restaurer('Restaurer une sauvegarde', Icons.restore, [
    'Dans Paramètres, Sauvegardes, touchez Restaurer, puis choisissez un fichier '
        'JSON ou une archive ZIP. Vous pouvez aussi repartir d\'une copie de '
        'sécurité.',
    'La restauration remplace toutes vos données par celles de la sauvegarde. '
        'Avant, l\'application crée automatiquement une copie de l\'état actuel.',
    'Après une restauration, saisissez de nouveau vos clés d\'API.',
  ]),
  horsLigne('Sans connexion', Icons.wifi_off, [
    'Les cours, quiz, exercices, corrigés, notes, le Lab, le Chaudron, les '
        'projets et la progression fonctionnent sans Internet.',
    'Les fournisseurs IA distants ont besoin d\'une connexion. Ollama fonctionne '
        'sans Internet, s\'il est installé et lancé.',
  ]),
  apparence('Changer l\'apparence', Icons.palette_outlined, [
    'Dans Plus, Paramètres, choisissez le thème sombre, clair ou celui du '
        'système. Vous pouvez aussi réduire ou désactiver les animations.',
  ]);

  const GrimoireTopic(this.title, this.icon, this.paragraphs);

  final String title;
  final IconData icon;
  final List<String> paragraphs;

  static GrimoireTopic? byName(String? name) {
    for (final topic in values) {
      if (topic.name == name) return topic;
    }
    return null;
  }
}
