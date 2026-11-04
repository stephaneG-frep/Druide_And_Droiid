# Rapport de tests

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
- **Rendu visuel Linux** : l'application se lance et la fenêtre a le bon titre et la bonne taille, mais les captures ont été prises sous l'économiseur d'écran et la fenêtre est sortie noire. L'affichage n'a pas été confirmé à l'œil.
