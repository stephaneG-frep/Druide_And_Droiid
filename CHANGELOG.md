# Journal des modifications

## Phase 11 — 2026-11-07

- Export et import JSON de toutes les données, sans les clés d'API.
- Sauvegarde complète en ZIP, avec des copies lisibles des notes, des réponses et du code.
- Restauration confirmée, d'un seul bloc, précédée d'une copie de l'état actuel.
- Copie de sécurité quotidienne au démarrage, cinq gardées.
- Export PDF des modules, des notes, des fiches de projet et des certificats, polices embarquées.
- Export Markdown des exercices.
- Choix de la destination : sélecteur du système sur Android, boîte de dialogue native sur Linux.
- Le Grimoire du Druide couvre tous les sujets du mode d'emploi, avec une aide contextuelle dans les écrans complexes.
- La page Maître indique si le fournisseur a besoin d'Internet.

## Phase 10 — 2026-11-07

- Barème définitif, avec expérience pour le Lab, les projets, les bugs vérifiés et l'évaluation finale.
- Seuils des huit grades fixés : Grand Druide demande 9 000 XP.
- Vingt badges, conservés une fois gagnés.
- Défis du jour et de la semaine, à réclamer.
- Statistiques, avancement par module et série de jours.
- Parcours personnalisés et objectif hebdomadaire.
- Historique des récompenses.
- Certificats internes, présentés comme tels.
- Base en version 8.

## Phase 9 — 2026-11-07

- Vingt projets progressifs, avec objectif, prérequis, étapes, code, test, questionnaire et critères de réussite.
- Suivi par étape, validation avec preuve, annulée si un élément est décoché.
- Évaluation finale du module 12 : grille notée, note sans preuve à zéro.
- Aide du Maître depuis un projet.
- Base en version 7.
- Nouvel outil `tool/check_projects.py`.

## Correctifs du Maître — 2026-11-07

- Les réglages affichent le fournisseur actif, et préviennent si celui de la liste ne l'est pas.
- Le Maître change de fournisseur d'un geste, parmi ceux déjà configurés.
- Le test de connexion ne choisit plus le premier modèle de la liste, qui pouvait être le plus cher.
- Une erreur de connexion avec Ollama explique la cause probable : pont USB perdu sur téléphone, Ollama éteint sur Linux.

## Phase 8 — 2026-11-07

- Dossiers du Chaudron des Bugs : erreur, journal importé, description et code.
- 37 fiches de diagnostic préenregistrées, sur dix familles de pannes, avec exemples de corrections.
- Diagnostics guidés par famille, avec listes de vérifications.
- Analyse IA en six parties, avec relecture de ce qui part et masquage des secrets.
- État du dossier : rien n'est résolu sans résultat de vérification noté.
- Sur Linux, lecture des plantages de l'appareil par ADB.
- Base en version 6.

## Phase 7 — 2026-11-06

- Éditeur de code avec coloration, numéros de ligne et sauvegarde automatique.
- 18 exercices Kotlin, Java, Dart et XML, avec corrigés, et des feuilles libres.
- Exécution réelle sur Linux, limitée en durée et en sortie, sans les variables d'environnement du parent.
- Analyse réelle du XML sur Linux et Android.
- Historique des versions, comparaison au corrigé, retour en arrière.
- Correction ou relecture par le Maître.
- Export dans un fichier, et copie.
- Outils Linux : détection, procédures d'installation et commandes prévues à l'avance.
- Base en version 5 : brouillons et versions du Lab.
- Nouvel outil `tool/check_lab_exercises.py`.

## Phase 6 — 2026-11-06

- Fournisseurs interchangeables : Anthropic Claude, OpenAI, Google Gemini, Ollama et API compatible avec OpenAI.
- Chat avec réponses progressives, arrêt, nouvel essai et historique enregistré.
- Douze modes pédagogiques, adaptés au niveau déclaré.
- Correction d'un exercice et question sur une leçon depuis l'Académie.
- Réglages : clé dans le coffre, test de connexion, choix du modèle, délai, longueur maximale et tarifs facultatifs.
- Accord demandé avant le premier envoi vers un service externe.
- Coût et jetons affichés lorsque le service les annonce.
- Base en version 4 : conversations et messages.
- Message clair quand le trousseau Linux est verrouillé.
- Essai facultatif contre un vrai serveur Ollama : `test/features/maitre/ollama_live_test.dart`.
- Trafic Android limité à HTTPS, sauf vers la machine locale.

## Phase 5 — 2026-11-06

- Module 11 Publication et maintenance rédigé : douze leçons et évaluation.
- Module 12 Expert Android rédigé : onze leçons, trois projets et une grille d'évaluation sur projet réel.
- Tous les extraits Android et Flutter des douze modules sont vérifiés d'un seul passage.
- `tool/check_android_snippets.py` compile aussi les extraits écrits comme des instructions.
- Le test « module sans contenu » utilise un index réduit, puisque plus aucun module n'est vide.

## Phase 5, en cours — 2026-11-06, tour 5

- Module 9 Sécurité Android rédigé : onze leçons et évaluation. Les exercices offensifs sont limités aux applications de démonstration et aux environnements autorisés.
- Module 10 Intelligence artificielle rédigé : douze leçons et évaluation.
- `tool/check_android_snippets.py` couvre les API de sécurité, de voix et d'images.

## Phase 5, en cours — 2026-11-06

- Module 7 Flutter pour Android rédigé : neuf leçons et évaluation.
- Module 8 Android avancé rédigé : onze leçons et évaluation, avec des avertissements sur les commandes qui modifient ou effacent des données.
- Coloration du C++ dans les blocs de code.
- Le contrôle des exemples exécute aussi Dart et vérifie la syntaxe du C++ avec le NDK.
- Nouvel outil `tool/check_flutter_snippets.py`, qui analyse les extraits Flutter et compile le code Kotlin hôte.

## Phase 5, en cours — 2026-11-05

- Module 5 Interfaces Android rédigé : dix leçons et évaluation.
- Module 6 Données et réseaux rédigé : dix leçons et évaluation.
- Le contrôle des exemples prend en charge kotlinx.serialization.
- Nouvel outil `tool/check_android_snippets.py`, qui compile les extraits Android dans un vrai projet Gradle.
- Module 4 : chaîne de compatibilité entre bibliothèques, `compileSdk`, AGP et Gradle.

## Phase 5, en cours — 2026-11-04

- Module 3 Java pour Android rédigé : neuf leçons et évaluation.
- Module 4 Android Studio rédigé : neuf leçons et évaluation, procédures Linux.
- Le contrôle des exemples couvre aussi Java.
- Nouveau type de bloc de code « Texte », pour les arborescences et les journaux.
- Module 1 terminé : huit leçons, évaluation de onze questions.
- Module 2 Kotlin rédigé : neuf leçons et évaluation.
- Sortie des programmes affichée sous les exemples de code.
- Coloration du Shell.
- Outil `tool/check_course_code.py`, qui compile et exécute les exemples Kotlin.

## Phase 4 — 2026-11-04

- Cours au format JSON embarqué, avec validation stricte du contenu.
- Écran de leçon : texte, code, encadrés, conseils et schémas en couches.
- Quiz notés à une ou plusieurs réponses, avec correction détaillée.
- Exercices à réponse courte corrigée, et exercices autoévalués avec corrigé.
- Réponses aux exercices enregistrées automatiquement.
- Évaluation de module, ouverte une fois les leçons terminées.
- Avancement sur les cartes de modules et bouton « Continuer » sur l'accueil.
- Ressources complémentaires par module.
- Schéma SQLite en version 3 : réponses aux exercices.
- Sauvegarde automatique mutualisée entre notes et exercices.
- Module 1 : trois premières leçons rédigées, le reste suit en phase 5.

## Phase 3 — 2026-11-04

- Schéma SQLite en version 2, avec migration depuis la version 1.
- Repositories de la progression, des notes et des favoris.
- Progression réelle : l'accueil et la page Progression lisent la base.
- Question flash : une bonne réponse du premier coup rapporte 10 XP, une fois par jour.
- Nouvelle rubrique Mes notes, avec sauvegarde automatique et suppression confirmée.
- Notes rattachées à un module, depuis sa page.
- Favoris sur les modules, avec un bloc dédié dans l'Académie.
- Messages d'erreur visibles si la progression ou les notes sont illisibles.
- Tuile « Badges obtenus » remplacée par « Points d'expérience » : les badges n'existent pas encore.
- Dialogues aux coins biseautés.
- Correction : sur Linux, la base est désormais dans le dossier de données de l'application, et non dans `~/Documents`.

## Phase 2 — 2026-11-04

- Thèmes sombre et clair personnalisés, avec polices embarquées.
- Mascotte Maître And-Droiīd en vectoriel : cinq humeurs et animation discrète.
- Onze familles de composants réutilisables (voir [DESIGN.md](DESIGN.md)).
- Tableau de bord, avec question flash quotidienne.
- Écrans principaux de toutes les rubriques : programme des douze modules, vingt projets, huit grades.
- Paramètres : thème et niveau d'animation, conservés au redémarrage.
- Icône de l'application et écran de démarrage sombre sur Android.
- Corrections : débordement du rail en paysage, plantage de `AnimatedSize` avec animations désactivées.

## Phase 1 — 2026-11-04

- Projet Flutter créé pour Android et Linux.
- Dépendances ajoutées : Riverpod, GoRouter, Drift, flutter_secure_storage, localisations françaises.
- Navigation : quatre onglets plus « Plus », barre basse ou rail selon la largeur, page 404 en français.
- Rubriques en attente : chacune indique la phase qui la livrera.
- Base SQLite minimale et coffre des secrets.
- Android : nom de l'application, permission Internet, sauvegarde système désactivée.
- Linux : titre de la fenêtre, taille minimale 360 × 600.
- Documents de suivi créés, tests initiaux ajoutés.
