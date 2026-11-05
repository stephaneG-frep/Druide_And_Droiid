# Rapport de tests

## Phase 5, tour 3 — 2026-11-05

La phase n'est pas terminée : modules 1 à 6 sur douze.

| Vérification | Résultat |
| --- | --- |
| `flutter analyze` | Aucun problème |
| `flutter test` | 192 tests sur 192 réussis |
| Intégration sur Linux | **4 tests sur 5** : voir ci-dessous |
| Intégration sur Honor | **Non lancée** : voir ci-dessous |
| Exemples Kotlin et Java compilés, exécutés et comparés | 83 sur 83 |
| Extraits Android compilés dans un projet Gradle | 53 sur 53 |
| Requêtes SQL du cours | Exécutées sur SQLite, résultats cohérents |
| Police de code | Tous les caractères des blocs sont présents |

L'outil de compilation a été éprouvé : une table inexistante dans une requête Room et une erreur de type ont bien fait échouer la compilation. 141 classes ont été produites, et KSP a généré le code Room.

Vérifié sur des rendus de test : quatre leçons des modules 5 et 6.

Sources contrôlées : developer.android.com pour l'état, la navigation, le cycle de vie, ViewModel, les fenêtres adaptatives, Room, DataStore, la sécurité réseau, le hors-ligne et Credential Manager ; le dépôt GitHub de Retrofit ; les dépôts Maven pour les versions.

### Échec du test d'intégration Linux

Le test du coffre échoue avec `PlatformException(KeyringLocked)`. Le trousseau GNOME était verrouillé sur cette session, après un redémarrage de la machine. Le code du coffre n'a pas changé, mais le test n'a pas été rejoué avec un trousseau déverrouillé.

Ce résultat montre aussi un manque : l'application ne présente pas encore ce cas à l'utilisateur. C'est à traiter en phase 6.

### Tests d'intégration non lancés sur le Honor

Ces tests désinstallent l'application, et la base du téléphone contient désormais la progression réelle de l'utilisateur. Ils n'ont donc pas été lancés. L'APK a été installé par-dessus, et le contenu de la base est identique avant et après l'installation. L'application n'a pas été parcourue sur le téléphone, qui était verrouillé.

### Non vérifié

- **Comportement des extraits Android** : ils compilent, mais aucun n'a été exécuté.
- **Compilation du projet par rapport aux modules 1 à 4** : `tool/check_android_snippets.py` n'a été lancé que sur les modules 5 et 6.
- **Fragments XML** : les balises isolées, comme `<uses-permission>`, ne sont pas compilées.
- **Recommandation sur Navigation 3** : déduite de la documentation, qui l'oriente vers les projets Compose. Aucune page lue ne le formule comme une consigne générale.
- **Repères d'accessibilité** : 48 dp et 4,5:1 viennent de mes connaissances, la page d'accueil lue ne les cite pas.
- **Site de Retrofit** : la page historique renvoie une erreur 404, et le README renvoie vers un domaine non vérifié. Le cours pointe vers le dépôt GitHub.
- **Le contenu n'a pas été relu par un tiers.**

## Phase 5, tour 2 — 2026-11-04

La phase n'est pas terminée : modules 1 à 4 sur douze.

| Vérification | Résultat |
| --- | --- |
| `flutter analyze` | Aucun problème |
| `flutter test` | 192 tests sur 192 réussis |
| Intégration sur Linux et sur Honor | 5 tests sur 5 réussis sur chacun |
| Exemples Kotlin et Java compilés, exécutés et comparés | 70 sur 70 |

Vérifications complémentaires, faites à part :

- **Blocs Gradle du module 4** : assemblés dans un projet Android jetable avec AGP 9.1.0 et Gradle 9.3.1. Variantes, suffixe d'identifiant, catalogue de versions, R8, AAB et signature par `keystore.properties` fonctionnent. L'APK de release porte bien le certificat de la clé de test, lu avec `apksigner`.
- **Interopérabilité** : la classe Kotlin `Potion` et son appel en Java ont été compilés ensemble. La sortie correspond au cours.
- **Commandes lancées sur cette machine** : `emulator -accel-check`, `emulator -list-avds`, `sdkmanager --list_installed`, `avdmanager list device -c`, `keytool -genkeypair`, `keytool -list`, `apksigner verify`, et l'existence des tâches `assembleDebug`, `assembleRelease`, `bundleRelease`, `installDebug`, `lintDebug` et `signingReport`.
- **Police de code** : tous les caractères des blocs existent, y compris le dessin de l'arborescence.

Sources contrôlées sur developer.android.com : accélération de l'émulateur, appareils USB, build, Logcat, signature, débogage, Profiler, `sdkmanager`, interopérabilité et `AsyncTask`.

Vérifié à la main sur le Honor : liste des modules, module Android Studio, leçon de structure de projet avec l'arborescence. Aucun crash ni erreur Flutter dans logcat.

### Non vérifié

- **Extraits non exécutés** : 25 extraits utilisent des API Android ou sont des fragments, listés par `tool/check_course_code.py`. Six d'entre eux relèvent des vérifications complémentaires ci-dessus : quatre blocs Gradle et deux blocs d'interopérabilité. Les 19 autres n'ont été ni compilés ni exécutés.
- **Commandes non lancées** : `avdmanager create avd` et `emulator -avd`, faute d'image système ; `sudo tar`, `apt-get install`, `usermod`, qui modifieraient la machine ; `sdkmanager --licenses`.
- **Installation d'Android Studio** : la procédure n'a pas été rejouée. La page lue ne donnait pas la procédure Linux, l'extraction de l'archive repose sur l'installation présente dans `/opt`. La configuration requise n'est pas chiffrée : le cours renvoie à la page officielle.
- **Interface d'Android Studio** : les noms de menus viennent de la documentation, et ils n'ont pas été vérifiés dans l'application. Les raccourcis F7, F8, F9 et Maj + F8 n'ont pas été recoupés sur une page lue.
- **Nouvelle commande `android sdk`** : mentionnée comme remplaçante de `sdkmanager`, mais non essayée.
- **Le contenu n'a pas été relu par un tiers**, et toutes les leçons n'ont pas été parcourues sur le téléphone.

## Phase 5, tour 1 — 2026-11-04

La phase n'est pas terminée : modules 1 et 2 sur douze.

| Vérification | Résultat |
| --- | --- |
| `flutter analyze` | Aucun problème |
| `flutter test` | 192 tests sur 192 réussis |
| Intégration sur Linux et sur Honor | 5 tests sur 5 réussis sur chacun |
| Exemples Kotlin compilés, exécutés et comparés | 41 sur 41 |
| Cohérence des cours | Identifiants, réponses et index validés par les tests |

L'outil de contrôle a été éprouvé : une sortie faussée et un code qui ne compile pas ont bien été signalés.

Sources contrôlées sur developer.android.com : niveaux d'API, AAB, notifications et canaux, stockage, services et types de premier plan, processus, permissions, mémoire. Aucune correction n'a été nécessaire sur les trois leçons existantes.

Vérifié à la main sur le Honor : liste des modules, module Kotlin, lecture d'une leçon avec sa console de résultat. Aucun crash ni erreur Flutter dans logcat.

### Non vérifié

- **Neuf extraits non exécutés** : ils utilisent des API Android, ou sont des fragments, et n'ont été ni compilés ni exécutés.
  - Module 1 : niveaux d'API (2), corrigé `defaultConfig`, permissions, mémoire (2), notifications (2).
  - Module 2 : `viewModelScope`.
- **Trois affirmations du module 1** n'ont pas été recoupées sur une page lue : permissions accordées une seule fois et retrait automatique, depuis Android 11 ; permissions d'exécution depuis Android 6.0 ; message `INSTALL_FAILED_UPDATE_INCOMPATIBLE`.
- **Android 37** : le SDK de cette machine contient la plateforme 37, absente de la page officielle consultée. La liste des versions est présentée comme des repères.
- **Le contenu n'a pas été relu par un tiers**, et les leçons n'ont pas toutes été parcourues sur le téléphone.
- **Les liens des ressources** ne s'ouvrent pas, et les cinq liens du module Kotlin n'ont pas été testés.

## Phase 4 — 2026-11-04

| Vérification | Résultat |
| --- | --- |
| `flutter analyze` | Aucun problème |
| `flutter test` | 190 tests sur 190 réussis |
| Intégration sur Linux | 5 tests sur 5 réussis |
| Intégration sur Honor MTN-NX1M (Android 16, arm64) | 5 tests sur 5 réussis |

Couvert par les tests :

- **Lecture des cours** : chaque type de bloc, et onze formes de contenu invalide avec localisation de l'erreur.
- **Vrais fichiers de cours** : concordance avec le programme, identifiants uniques, leçons complètes, solutions acceptées, évaluation réalisable.
- **Notation** : questions multiples, seuil inclusif, calcul entier sans erreur d'arrondi.
- **Leçon** : affichage, fin de leçon, passage à la suivante, retour au module, leçon inconnue, cours illisible.
- **Quiz** : réussite, échec, reprise, expérience créditée une fois, réponses conservées au défilement.
- **Exercices** : réponse juste ou fausse, autoévaluation, texte retrouvé en rouvrant la leçon.
- **Évaluation** : fermée tant que des leçons manquent, réussite, échec puis nouvel essai.
- **Reprise** : le bouton Continuer suit la progression.
- **Migration** : d'un vrai fichier v2 vers v3, sans perte, et même schéma qu'une base neuve.

Vérifié à la main sur le Honor :

| Vérification | Résultat |
| --- | --- |
| Mise à jour de la version phase 3 par-dessus | Fichier passé de v2 à v3 |
| Accueil, lecture d'une leçon, défilement | Corrects |
| Réponse à un exercice, validation | « Exercice réussi », +10 XP |
| Fin de leçon, arrêt forcé, relance | 30 XP affichés, Continuer propose la leçon 2, données correctes en base |
| Logcat | Aucun crash ni erreur Flutter |

La base du téléphone ne contenait que des données de test. Elle a été effacée par les tests d'intégration, et l'application réinstallée repart de zéro.

### Non vérifié

- **Contenu** : les trois leçons n'ont pas été relues par un tiers. Les faits, notamment les dates et niveaux d'API, viennent de mes connaissances, sans contrôle en ligne.
- **Quiz et évaluation sur le téléphone** : testés par widgets, pas parcourus à la main sur le Honor.
- **Liens des ressources** : affichés et sélectionnables, ils ne s'ouvrent pas. Leur validité n'a pas été contrôlée.
- **Performances** de longues leçons.
- **Lecteur d'écran** sur les leçons.

## Phase 3 — 2026-11-04

| Vérification | Résultat |
| --- | --- |
| `flutter analyze` | Aucun problème |
| `flutter test` | 137 tests sur 137 réussis |
| Intégration sur Linux | 4 tests sur 4 réussis |
| Intégration sur Honor MTN-NX1M (Android 16, arm64) | 4 tests sur 4 réussis |

Couvert par les tests :

- **Migration** : d'un vrai fichier v1 vers v2, sans perte, et même schéma qu'une base neuve.
- **Progression** : leçons, quiz, expérience créditée une seule fois, y compris en appels simultanés.
- **Notes** : création, relecture, accents et emoji, tri, filtre par module, suppression, note inconnue.
- **Sauvegarde automatique** : délai, sortie immédiate de l'écran, passage en arrière-plan, frappe pendant une écriture, note vide jamais créée, échec puis nouvel essai.
- **Écrans** : annulation et confirmation de suppression, note liée à un module, favoris, question flash.
- **Persistance sur fichier** : notes, progression et favoris relus après fermeture, sur Linux et Android.

Vérifié à la main sur les appareils réels :

| Vérification | Résultat |
| --- | --- |
| Honor : mise à jour de la version phase 2 par-dessus, sans désinstaller | Fichier passé de v1 à v2, réglage conservé, thème clair affiché |
| Honor : bonne réponse à la question flash, arrêt forcé, relance | 10 XP et 1 quiz réussi affichés et présents dans la base |
| Honor : suppression d'une note avec confirmation | Note retirée de la base |
| Honor : logcat | Aucun crash ni erreur Flutter |
| Linux : lancement réel | Base v2 créée dans `~/.local/share/`, plus rien écrit dans `~/Documents` |

Sauvegarde des notes sur le Honor, avec arrêt forcé :

| Scénario | Résultat |
| --- | --- |
| Arrêt 2 s après la frappe | Note conservée |
| Arrêt environ 860 ms après le début de la frappe | Note conservée |
| Touche Accueil puis arrêt forcé immédiat, délai alors de 600 ms | **Note perdue** |

Le délai a ensuite été réduit à 300 ms. Le scénario perdant n'a pas été rejoué : la fenêtre est réduite, pas supprimée. L'enregistrement au passage en arrière-plan est prouvé par un test de widget, mais il n'a pas été isolé sur le téléphone.

Bugs trouvés et corrigés pendant la phase :

- La base était écrite dans `~/Documents` sur Linux.
- La tuile « Badges obtenus » affichait un zéro figé pour une fonction inexistante.

### Non vérifié

- **Base corrompue ou disque plein** sur un appareil réel : seules des erreurs simulées sont testées.
- **Performances** avec un grand nombre de notes.
- **Saisie sur Linux** : l'écran des notes n'y a pas été essayé à la main.

## Phase 2 — 2026-11-04

| Vérification | Résultat |
| --- | --- |
| `flutter analyze` | Aucun problème |
| `flutter test` | 89 tests sur 89 réussis |
| Intégration sur Linux | 3 tests sur 3 réussis |
| Intégration sur Honor MTN-NX1M (Android 16, arm64) | 3 tests sur 3 réussis |

Couvert par les tests :

- **Mise en page** : tous les écrans, en 6 formats, thèmes clair et sombre, texte à 100 % et 200 %, sans débordement.
- **Contraste** : texte sur toutes les surfaces des deux thèmes, code et console, à 4,5:1 minimum.
- **Composants** : correction du quiz, mascotte dans chaque humeur, arrêt de sa boucle, dépliage du grimoire, copie réelle du code, barre d'expérience.
- **Apparence** : enregistrement, relecture, valeur invalide, échec de lecture et d'écriture.
- **Navigation** : onglets, programme d'un module et retour, raccourcis, chemins inconnus.

Bugs trouvés et corrigés pendant la phase :

- Le rail débordait sur un téléphone en paysage.
- `AnimatedSize` plantait quand les animations étaient désactivées.
- Les tuiles laissaient un vide à droite sur grand écran, défaut vu sur la capture Linux.

Vérifié à la main sur l'application réelle :

| Vérification | Résultat |
| --- | --- |
| Honor : écrans Accueil, Plus et Paramètres | Corrects |
| Honor : thème clair et animations réduites, puis arrêt forcé et relance | Réglages conservés, nouveau processus confirmé |
| Honor : logcat | Aucun crash ni erreur Flutter |
| Linux : accueil en thème sombre | Correct sur capture de la fenêtre |

Sur le Honor, les captures montrent des couleurs légèrement différentes de la palette. Les valeurs correspondent à l'espace colorimétrique Display P3 utilisé par Flutter sur cet appareil : c'est un artefact de capture, pas une erreur de couleur.

### Non vérifié

- **Performances** : seul le mode debug a été exécuté, aucune mesure n'a été faite.
- **Lecteur d'écran** : les libellés sont testés, mais TalkBack et Orca n'ont pas été essayés.
- **Icône Android** : générée et installée, mais pas contrôlée à l'œil sur l'écran d'accueil du téléphone.
- **Sur Linux**, seul l'écran d'accueil a été regardé. Les autres écrans ont été vus sur des rendus de test et, pour trois d'entre eux, sur le Honor.

## Phase 1 — 2026-11-04

Environnement : Ubuntu 22.04 x86_64, Flutter 3.47.2, Dart 3.13.2.

| Vérification | Résultat |
| --- | --- |
| `flutter analyze` | Aucun problème |
| `flutter test` | 12 tests sur 12 réussis |
| `flutter test integration_test -d linux` | 3 tests sur 3 réussis |
| `flutter test integration_test` sur Honor MTN-NX1M (Android 16, API 36, arm64) | 3 tests sur 3 réussis |
| Lancement de l'application sur le Honor (debug) | Démarrage en 3,3 s, écran d'accueil correct sur capture, aucune erreur dans logcat |

Couvert par les tests :

- Démarrage, onglets, page Plus, position conservée entre onglets, chemin inconnu.
- Barre basse et rail selon la largeur.
- Affichage sur 320 × 568 avec texte à 150 %. Ce test a révélé un débordement, corrigé en rendant les pages défilantes.
- SQLite : lecture et écriture en mémoire, conservation après réouverture d'un fichier sur Linux et Android.
- Coffre : écriture, lecture et effacement dans le vrai trousseau Linux et dans le stockage sécurisé Android.

## Non vérifié

- **Android release** : seul le mode debug a été exécuté.
- **Autres appareils Android** : un seul modèle testé, arm64. Les versions armeabi-v7a et x86_64 n'ont pas été lancées.
- **Rendu visuel Linux** : capture noire pendant cette phase, sous l'économiseur d'écran. Confirmé en phase 2.
