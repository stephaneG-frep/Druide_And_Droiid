# Rapport de tests

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
