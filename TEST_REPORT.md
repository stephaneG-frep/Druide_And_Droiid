# Rapport de tests

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
