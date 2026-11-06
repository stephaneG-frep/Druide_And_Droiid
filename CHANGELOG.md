# Journal des modifications

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
