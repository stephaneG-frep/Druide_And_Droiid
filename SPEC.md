
# PROMPT MAÎTRE — DRUIDE AND-DROIĪD

## MISSION

Tu es Claude Code, architecte logiciel senior, développeur Flutter/Dart expert, ingénieur Android, spécialiste Kotlin/Java, concepteur UX/UI, ingénieur IA et responsable qualité.

Ta mission consiste à concevoir, développer, tester et livrer une application Flutter complète appelée :

# 🧙 DRUIDE AND-DROIĪD
### « La magie d'Android, du premier sort au code expert ! »

Druide And-Droiīd est une académie Android intelligente permettant d'apprendre, de comprendre, de programmer, de dépanner et de maîtriser Android, du niveau débutant jusqu'au niveau expert.

L'application doit être un véritable environnement pédagogique interactif, et non une simple collection de textes ou une démonstration graphique.

Elle doit fonctionner sur :
- Android : APK installable.
- Linux Ubuntu : application native distribuée en paquet `.deb`.

L'interface doit être intégralement en français.

L'application doit posséder une identité graphique originale, colorée, ludique, futuriste et technomagique.

Elle doit inclure un professeur IA incarné par un druide robot loufoque.

---

# 1. DIRECTIVES FONDAMENTALES

## 1.1 Autonomie

Travaille de manière autonome.

Ne demande pas de confirmation à chaque étape.

Prends les décisions techniques raisonnables et documente-les.

Ne t'arrête pas après avoir créé une architecture ou quelques écrans.

Poursuis le développement jusqu'à obtenir les fonctionnalités prévues, sous réserve des contraintes techniques réellement rencontrées.

Ne prétends jamais qu'une fonctionnalité fonctionne sans l'avoir vérifiée.

Ne simule pas artificiellement les résultats des tests.

## 1.2 Développement par phases

Le projet doit être réalisé en phases successives.

À la fin de chaque phase :

1. Vérifier le code.
2. Exécuter les tests appropriés.
3. Corriger les erreurs détectées.
4. Vérifier les fonctionnalités développées.
5. Mettre à jour le suivi du projet.
6. Effectuer un commit Git si le dépôt est configuré.
7. Passer à la phase suivante si les critères de validation sont satisfaits.

Ne pas passer à une phase ultérieure lorsqu'une erreur bloquante subsiste.

## 1.3 Fichiers de référence

Créer et maintenir :

- `SPEC.md` : cahier des charges détaillé.
- `DESIGN.md` : direction artistique et composants.
- `ARCHITECTURE.md` : architecture technique.
- `ROADMAP.md` : phases et progression.
- `CHANGELOG.md` : modifications.
- `TEST_REPORT.md` : résultats des tests.
- `README.md` : installation et utilisation.
- `USER_GUIDE.md` : mode d'emploi.
- `BUILD_REPORT.md` : état réel des compilations.

Ces documents doivent correspondre au code réellement développé.

---

# 2. IDENTITÉ GRAPHIQUE

## 2.1 Univers

Créer une académie technomagique Android.

Mélanger visuellement :

- Laboratoire de savant fou.
- Atelier électronique.
- Grimoires numériques.
- Potions lumineuses.
- Circuits imprimés.
- Hologrammes.
- Symboles Android.
- Robots et technologies futuristes.

L'application doit posséder une véritable personnalité.

Éviter les interfaces Material 3 génériques sans personnalisation.

## 2.2 Mascotte

Créer une mascotte originale appelée :

**Maître And-Droiīd**

C'est un druide robot sympathique, légèrement excentrique, avec :

- Une capuche de druide futuriste.
- Des yeux électroniques expressifs.
- Une barbe constituée de fibres optiques.
- Un bâton technologique.
- Des accessoires électroniques.
- Des animations discrètes.

La mascotte intervient dans les cours, les corrections et les encouragements.

Elle ne doit pas gêner la lecture ni ralentir l'application.

Prévoir une option pour réduire ou désactiver les animations.

## 2.3 Palette

Couleurs principales :

- Vert émeraude : `#00D68F`
- Violet mystique : `#865DFF`
- Orange alchimique : `#FFAA33`
- Cyan électrique : `#00D9FF`
- Bleu nuit : `#101527`
- Fond sombre : `#0B1020`

Prévoir également un thème clair.

## 2.4 Composants

Créer des composants réutilisables :

- Cartes de cours.
- Grimoires interactifs.
- Boutons technomagiques.
- Badges de progression.
- Barres d'expérience.
- Fenêtres de dialogue IA.
- Éditeur de code.
- Console pédagogique.
- Tableaux de bord.
- Quiz animés.
- Notifications visuelles.

Garantir un affichage adapté aux smartphones et aux ordinateurs.

Respecter l'accessibilité, les contrastes et les tailles de texte.

---

# 3. ARCHITECTURE TECHNIQUE

Utiliser :

- Flutter stable compatible avec le projet.
- Dart.
- Riverpod pour la gestion d'état.
- GoRouter pour la navigation.
- SQLite pour les données structurées.
- Stockage sécurisé pour les clés API.
- Architecture modulaire inspirée de Clean Architecture.
- Tests unitaires, widgets et intégration.

Choisir les bibliothèques maintenues et compatibles Android/Linux.

Ne pas imposer Firebase.

L'application doit fonctionner sans compte utilisateur.

La connexion Internet ne doit être nécessaire que pour les fonctionnalités qui en dépendent.

Séparer clairement :

1. Présentation.
2. Logique métier.
3. Persistance.
4. Contenu pédagogique.
5. Fournisseurs IA.
6. Services spécifiques aux plateformes.

Les fonctionnalités Linux nécessitant Android SDK, ADB ou Gradle doivent vérifier la présence des outils avant utilisation.

Ne jamais supposer qu'un smartphone Android peut compiler localement un projet Android complet sans environnement adapté.

---

# 4. ACADÉMIE ANDROID

Créer une formation structurée, progressive et réellement exploitable.

Chaque module doit contenir :

- Des leçons rédigées.
- Des exemples concrets.
- Des explications accessibles.
- Du code commenté lorsque nécessaire.
- Des exercices.
- Des quiz.
- Des corrections.
- Des projets pratiques.
- Des évaluations.
- Des ressources complémentaires.
- Un suivi de progression.

Ne pas remplacer les cours par de simples titres ou quelques phrases générées automatiquement.

## MODULE 1 — LES FONDATIONS D'ANDROID

Enseigner :

- Histoire d'Android.
- Versions et évolutions.
- Architecture Android.
- Noyau Linux.
- Android Runtime.
- Framework Android.
- Applications système.
- APK et AAB.
- Installation des applications.
- Permissions.
- Stockage.
- Gestion des fichiers.
- Processus.
- Mémoire.
- Services.
- Notifications.

Prévoir des schémas explicatifs et des quiz.

## MODULE 2 — KOTLIN

Formation progressive :

- Variables.
- Types.
- Conditions.
- Boucles.
- Fonctions.
- Classes.
- Objets.
- Héritage.
- Interfaces.
- Collections.
- Null safety.
- Lambdas.
- Coroutines.
- Flow.
- Programmation asynchrone.
- Architecture applicative.

Inclure des exercices corrigés.

## MODULE 3 — JAVA POUR ANDROID

Enseigner :

- Syntaxe Java.
- Programmation orientée objet.
- Collections.
- Exceptions.
- Threads.
- Interfaces.
- Classes Android.
- Interopérabilité Kotlin/Java.
- Maintenance d'applications Java existantes.

## MODULE 4 — ANDROID STUDIO

Créer un parcours interactif :

- Installation.
- Configuration.
- Android SDK.
- SDK Manager.
- AVD Manager.
- Émulateurs.
- Création de projets.
- Gradle.
- Structure des dossiers.
- Manifest.
- Logcat.
- Debugger.
- Profiler.
- Compilation.
- Signature.
- Export APK/AAB.

Prévoir des procédures adaptées à Linux.

## MODULE 5 — INTERFACES ANDROID

Enseigner :

- Jetpack Compose.
- Composables.
- États.
- Navigation.
- Thèmes.
- Material Design.
- Interfaces XML historiques.
- Activity.
- Fragment.
- ViewModel.
- MVVM.
- Accessibilité.
- Responsive design.
- Animations.
- Gestion des formulaires.

## MODULE 6 — DONNÉES ET RÉSEAUX

Enseigner :

- SQLite.
- Room.
- DataStore.
- JSON.
- REST.
- HTTP.
- Retrofit.
- Authentification.
- Gestion des erreurs.
- Synchronisation.
- Cache.
- Fonctionnement hors ligne.
- Sécurité des communications.

## MODULE 7 — FLUTTER ET ANDROID

Enseigner :

- Dart.
- Widgets.
- StatefulWidget.
- StatelessWidget.
- Navigation.
- Gestion d'état.
- Plugins Flutter.
- Platform Channels.
- Intégration Kotlin.
- Permissions Android.
- Notifications.
- Stockage.
- Compilation APK.
- Signature.
- Débogage.
- Optimisation.

Expliquer les différences entre Flutter et le développement Android natif.

## MODULE 8 — ANDROID AVANCÉ

Enseigner :

- ADB.
- Fastboot.
- Logcat.
- Shell Android.
- Termux.
- Débogage USB.
- Processus.
- Services.
- WorkManager.
- Gestion énergétique.
- Batterie.
- Mémoire.
- Performances.
- ANR.
- Crashs.
- Architecture ARM.
- ABI.
- Bibliothèques natives.
- NDK.
- JNI.
- Analyse des problèmes de compilation.

Inclure des avertissements pour les commandes susceptibles de modifier ou d'effacer des données.

## MODULE 9 — SÉCURITÉ ANDROID

Créer un parcours de cybersécurité éthique :

- Sandbox Android.
- Permissions.
- Keystore.
- Chiffrement.
- Stockage sécurisé.
- OWASP MASVS.
- Analyse statique.
- Analyse dynamique.
- Analyse d'APK.
- MobSF.
- JADX.
- Tests de sécurité.
- Protection des API.
- Vulnérabilités courantes.
- Sécurisation des applications.

Les exercices offensifs doivent rester limités aux applications de démonstration, aux laboratoires autorisés et aux environnements contrôlés.

## MODULE 10 — INTELLIGENCE ARTIFICIELLE

Enseigner :

- API d'IA.
- Intégration de modèles.
- Agents conversationnels.
- IA locale.
- Ollama.
- Modèles embarqués compatibles.
- Reconnaissance vocale.
- Synthèse vocale.
- Automatisations.
- Traitement d'images.
- Gestion des coûts.
- Confidentialité.
- Sécurité des clés API.

## MODULE 11 — PUBLICATION ET MAINTENANCE

Enseigner :

- Compilation release.
- Signature APK/AAB.
- Versionnement.
- Google Play Console.
- Tests.
- CI/CD.
- GitHub Actions.
- Maintenance.
- Compatibilité Android.
- Mises à jour.
- Optimisation.
- Crash reporting.
- Publication professionnelle.

## MODULE 12 — EXPERT ANDROID

Créer des projets complets mobilisant :

- Architecture avancée.
- Développement natif.
- Flutter.
- API.
- Bases de données.
- Sécurité.
- Tests.
- Optimisation.
- Publication.
- Documentation.

Prévoir une évaluation finale fondée sur un véritable projet.

---

# 5. PROFESSEUR IA — MAÎTRE AND-DROIĪD

Créer un agent IA pédagogique intégré.

## Capacités

L'agent doit pouvoir :

1. Expliquer les concepts Android.
2. Adapter ses réponses au niveau de l'utilisateur.
3. Générer des exemples de code.
4. Corriger les exercices.
5. Analyser des erreurs.
6. Expliquer les messages Logcat.
7. Aider à comprendre Gradle.
8. Diagnostiquer des problèmes Flutter.
9. Proposer des exercices personnalisés.
10. Accompagner la réalisation de projets.
11. Expliquer le fonctionnement interne d'Android.
12. Suggérer des améliorations de code.

## Fournisseurs IA

Prévoir une architecture permettant de configurer :

- Anthropic Claude.
- OpenAI.
- Google Gemini.
- Ollama.
- Fournisseur compatible avec une API documentée.

Chaque fournisseur doit être interchangeable.

Prévoir :

- Configuration des clés.
- Test de connexion.
- Choix du modèle.
- Gestion des erreurs.
- Gestion des délais d'attente.
- Historique des conversations.
- Suppression des conversations.
- Indication des coûts lorsque les informations sont disponibles.

Ne jamais intégrer de clé API dans le code source.

Les clés doivent être conservées dans un stockage sécurisé adapté à chaque plateforme.

## Fonctionnement sans IA

L'application doit rester utilisable sans fournisseur IA configuré.

Les cours, quiz, exercices et corrections prédéfinies doivent rester disponibles.

Ne pas présenter un système de réponses statiques comme une véritable IA.

---

# 6. ANDROID LAB

Créer un laboratoire pédagogique interactif.

## Fonctionnalités

- Éditeur de code avec coloration syntaxique.
- Exercices Kotlin.
- Exercices Java.
- Exercices Dart.
- Exemples XML.
- Console de résultats.
- Correction IA.
- Comparaison entre solutions.
- Sauvegarde des exercices.
- Historique des modifications.
- Export du code.

## Android

Sur smartphone, proposer un environnement d'édition et des exercices pédagogiques.

Les exécutions de code doivent utiliser uniquement des mécanismes réellement implémentés et sécurisés.

Ne pas prétendre exécuter du Kotlin ou du Java natif lorsqu'il s'agit seulement d'une simulation.

## Linux

Prévoir une intégration optionnelle avec :

- Android Studio.
- Android SDK.
- ADB.
- Gradle.
- Émulateur Android.

L'application doit détecter les outils installés.

Si un outil manque, afficher une explication et une procédure d'installation.

Les commandes doivent être exécutées dans un environnement contrôlé, avec validation explicite des opérations sensibles.

Ne jamais exécuter automatiquement du code généré par IA sans validation de l'utilisateur.

---

# 7. ATELIER DE DÉPANNAGE

Créer une rubrique :

## « Le Chaudron des Bugs »

Elle permet à l'utilisateur de :

- Coller un message d'erreur.
- Importer un fichier de logs.
- Décrire un dysfonctionnement.
- Ajouter un extrait de code.
- Demander une analyse IA.

L'agent doit produire :

1. Un résumé du problème.
2. Les causes possibles.
3. Les vérifications recommandées.
4. Les corrections proposées.
5. Une explication pédagogique.
6. Une procédure de validation.

Prévoir notamment :

- Erreurs Gradle.
- Problèmes SDK.
- Erreurs ADB.
- APK incompatibles.
- Problèmes ABI.
- Crashs au démarrage.
- Blocages sur splash screen.
- Erreurs de permissions.
- Problèmes de dépendances.
- Erreurs Flutter/Dart.

Ne jamais affirmer qu'un problème est résolu sans résultat de vérification.

---

# 8. PROJETS PRATIQUES

Créer un atelier de réalisation.

Proposer des projets progressifs :

### Débutant

- Calculatrice.
- Convertisseur.
- Liste de tâches.
- Chronomètre.
- Application de notes.

### Intermédiaire

- Gestionnaire de fichiers.
- Application météo.
- Lecteur multimédia.
- Application utilisant une API.
- Gestionnaire de données locales.

### Avancé

- Application avec authentification.
- Application avec synchronisation.
- Application Flutter avec fonctions natives.
- Application utilisant une IA.
- Application avec notifications avancées.

### Expert

- Application complète prête à publier.
- Application Android native avec architecture avancée.
- Application multiplateforme.
- Application avec tests automatisés.
- Projet professionnel documenté.

Chaque projet doit contenir un objectif, des prérequis, des étapes, du code, des tests et des critères de réussite.

---

# 9. PROGRESSION ET GAMIFICATION

Créer un système de progression ludique.

L'utilisateur commence comme :

**Apprenti du Droid**

Puis progresse :

1. Apprenti du Droid.
2. Initié des Circuits.
3. Alchimiste Kotlin.
4. Mage des Interfaces.
5. Gardien du SDK.
6. Maître du Débogage.
7. Archimage Android.
8. Grand Druide And-Droiīd.

Ajouter :

- Points d'expérience.
- Badges.
- Défis.
- Quiz.
- Statistiques.
- Parcours personnalisés.
- Objectifs.
- Historique.
- Certificats de réussite internes.

Ne pas présenter les certificats internes comme des certifications professionnelles officielles.

---

# 10. SAUVEGARDE ET EXPORT

Toutes les données importantes doivent être sauvegardées localement.

Inclure :

- Progression pédagogique.
- Leçons terminées.
- Résultats des quiz.
- Exercices.
- Projets personnels.
- Historique IA.
- Notes.
- Favoris.
- Paramètres.

La fermeture ou le redémarrage de l'application ne doit provoquer aucune perte de données enregistrées.

Prévoir :

- Sauvegarde automatique.
- Export JSON.
- Import JSON.
- Export PDF des cours et notes.
- Export PDF des projets.
- Export des exercices.
- Sauvegarde ZIP.
- Restauration des sauvegardes.

Permettre à l'utilisateur de choisir la destination lorsque la plateforme le permet.

Vérifier la compatibilité Android et Linux des mécanismes d'export.

Ne pas inclure les clés API dans les sauvegardes ordinaires.

---

# 11. MODE HORS LIGNE

L'application doit être utilisable sans Internet pour :

- Lire les cours installés.
- Réviser.
- Effectuer les quiz locaux.
- Consulter les corrections.
- Modifier les exercices.
- Consulter les notes.
- Consulter la progression.

Les fonctionnalités nécessitant une IA distante doivent indiquer clairement qu'une connexion est nécessaire.

Un fournisseur IA local peut être utilisé uniquement lorsqu'il est réellement installé, accessible et configuré.

---

# 12. MODE D'EMPLOI

Créer une rubrique :

## « Le Grimoire du Druide »

Elle doit expliquer :

- Comment utiliser l'application.
- Comment suivre une formation.
- Comment utiliser l'IA.
- Comment configurer les fournisseurs.
- Comment réaliser les exercices.
- Comment utiliser Android Lab.
- Comment importer des logs.
- Comment exporter des documents.
- Comment sauvegarder les données.
- Comment restaurer une sauvegarde.
- Comment utiliser les outils Linux.

Ajouter une aide contextuelle dans les écrans complexes.

---

# 13. QUALITÉ ET SÉCURITÉ

## Exigences

- Aucun bouton factice.
- Aucun écran vide non justifié.
- Aucun faux résultat IA.
- Aucun faux compilateur.
- Aucun faux téléchargement.
- Aucun faux export.
- Aucune clé API codée en dur.
- Aucune suppression de données sans confirmation.
- Aucune commande dangereuse exécutée silencieusement.

Gérer correctement :

- Absence de connexion.
- Permissions refusées.
- Fichiers invalides.
- Erreurs de stockage.
- Clés API incorrectes.
- Réponses IA malformées.
- Délais d'attente.
- Échecs de compilation.
- Reprise après interruption.

Prévoir des messages d'erreur compréhensibles en français.

---

# 14. PLAN DE DÉVELOPPEMENT

## PHASE 1 — Fondations

- Initialiser le projet Flutter.
- Définir l'architecture.
- Créer les documents.
- Configurer les dépendances.
- Préparer Android et Linux.
- Mettre en place la navigation.
- Créer les tests initiaux.

## PHASE 2 — Design

- Créer les thèmes.
- Développer les composants.
- Intégrer la mascotte.
- Créer le tableau de bord.
- Réaliser les écrans principaux.
- Vérifier le responsive.

## PHASE 3 — Persistance

- Mettre en place SQLite.
- Créer les modèles.
- Développer les repositories.
- Sauvegarder la progression.
- Sauvegarder les notes.
- Tester la persistance.

## PHASE 4 — Moteur pédagogique

- Créer le système de cours.
- Intégrer les leçons.
- Créer les quiz.
- Développer les exercices.
- Mettre en place les évaluations.
- Enregistrer la progression.

## PHASE 5 — Contenus Android

- Développer les douze modules.
- Rédiger les leçons.
- Intégrer les exemples.
- Créer les exercices.
- Ajouter les corrections.
- Vérifier la cohérence pédagogique.

Ne pas considérer cette phase terminée avec des contenus de démonstration.

## PHASE 6 — Professeur IA

- Créer l'architecture des fournisseurs.
- Intégrer les API.
- Développer le chat.
- Ajouter les explications pédagogiques.
- Créer la correction des exercices.
- Gérer les erreurs.
- Tester les intégrations disponibles.

## PHASE 7 — Android Lab

- Développer l'éditeur.
- Créer les exercices interactifs.
- Ajouter les corrections.
- Intégrer les outils Linux disponibles.
- Développer les exports.
- Tester les limitations propres aux plateformes.

## PHASE 8 — Chaudron des Bugs

- Créer l'import de logs.
- Développer l'analyse IA.
- Ajouter les diagnostics guidés.
- Intégrer les exemples de corrections.
- Tester les scénarios.

## PHASE 9 — Projets pratiques

- Créer les parcours.
- Intégrer les projets.
- Ajouter les étapes.
- Ajouter les tests pédagogiques.
- Développer le suivi.

## PHASE 10 — Gamification

- Points d'expérience.
- Badges.
- Niveaux.
- Défis.
- Statistiques.
- Récompenses.
- Évaluations finales.

## PHASE 11 — Sauvegardes et documentation

- Export PDF.
- Export JSON.
- Import JSON.
- Sauvegarde ZIP.
- Restauration.
- Mode d'emploi.
- Aide contextuelle.
- Tests de persistance.

## PHASE 12 — Audit général

Effectuer :

- Audit du code.
- Audit de l'architecture.
- Audit de sécurité.
- Audit des dépendances.
- Audit des performances.
- Audit des interfaces.
- Audit pédagogique.
- Tests de navigation.
- Tests de sauvegarde.
- Tests des exports.
- Tests hors ligne.

Corriger les anomalies détectées.

## PHASE 13 — Compilation et livraison

### Android

Produire :

`Druide_And-Droiid_v1.0.0.apk`

Vérifier :

- Compilation release.
- Architecture Android ciblée.
- Permissions.
- Démarrage.
- Navigation.
- Sauvegardes.
- Exports.
- Fonctionnement hors ligne.

Installer et tester l'APK sur un appareil ou émulateur compatible lorsqu'il est disponible.

### Linux

Produire :

`Druide_And-Droiid_v1.0.0_amd64.deb`

Adapter l'architecture du paquet à la machine de compilation et documenter les architectures réellement prises en charge.

Vérifier :

- Installation du paquet.
- Lancement.
- Navigation.
- Persistance.
- Exports.
- Fonctionnement hors ligne.
- Désinstallation.

### Sources

Produire :

`Druide_And-Droiid_v1.0.0_sources.zip`

Inclure :

- Sources Flutter.
- Ressources.
- Contenus pédagogiques.
- Configuration sans secrets.
- Documentation.
- Tests.
- Scripts de compilation.
- Instructions de reconstruction.

---

# 15. CRITÈRES DE LIVRAISON

Le projet n'est considéré comme terminé que lorsque :

1. Les fonctionnalités annoncées sont implémentées.
2. Les contenus pédagogiques sont réellement disponibles.
3. La navigation fonctionne.
4. La progression est persistante.
5. Les quiz fonctionnent.
6. Les exercices sont exploitables.
7. Les intégrations IA configurées fonctionnent.
8. Le mode hors ligne est opérationnel.
9. Les sauvegardes et restaurations sont testées.
10. Les exports fonctionnent.
11. Les tests automatisés passent.
12. Les livrables ont été compilés.
13. Les tests d'installation disponibles ont été effectués.
14. La documentation est complète.
15. Les limitations restantes sont explicitement documentées.

Ne jamais déclarer « application complète et testée » si certains critères ne sont pas satisfaits.

En cas d'impossibilité technique, identifier précisément le blocage, les éléments terminés et les actions nécessaires.

---

# 16. CONSIGNES FINALES

Commence par inspecter l'environnement de développement.

Vérifie :

- Flutter.
- Dart.
- Android SDK.
- Java.
- Gradle.
- Outils Linux.
- Dépendances nécessaires.

Crée ensuite `SPEC.md`, `DESIGN.md`, `ARCHITECTURE.md` et `ROADMAP.md`.

Démarre immédiatement la phase 1.

Travaille de manière autonome et méthodique.

Évite les interruptions inutiles.

N'effectue aucune action destructive sans autorisation.

Ne publie rien sur GitHub ni sur un service externe sans accord explicite.

Ne consomme pas de crédits API payants pour des tests sans autorisation.

À chaque phase, produis un compte rendu concis :

- Phase terminée.
- Fonctionnalités développées.
- Tests effectués.
- Résultats.
- Problèmes éventuels.
- Phase suivante.

**OBJECTIF FINAL :**

Livrer Druide And-Droiīd, une académie Android technomagique, originale, pédagogique, complète et réellement fonctionnelle, permettant d'apprendre Android de zéro à expert avec un professeur IA, un laboratoire interactif, des outils de dépannage et une progression sauvegardée.

**COMMENCE MAINTENANT PAR LA PHASE 1.**