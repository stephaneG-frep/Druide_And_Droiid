# Rapport de compilation

## Phase 9 — 2026-11-07

| Cible | Commande | Résultat |
| --- | --- | --- |
| Android debug | `flutter build apk --debug` | Réussi, installé par-dessus sur Honor MTN-NX1M |
| Linux debug | `flutter build linux --debug` | Réussi |
| Projets | `python3 tool/check_projects.py` | 20 tests exécutés, 40 extraits Android compilés, 4 extraits Flutter analysés |

## Phase 8 — 2026-11-07

| Cible | Commande | Résultat |
| --- | --- | --- |
| Android debug | `flutter build apk --debug` | Réussi, installé par-dessus sur Honor MTN-NX1M |
| Linux debug | Les trois fichiers d'intégration, un par un | Réussi |

Nouvelle dépendance : `file_selector`, dont la boîte de dialogue native ne dépend pas d'outils externes sur Linux.

## Phase 7 — 2026-11-06

| Cible | Commande | Résultat |
| --- | --- | --- |
| Android debug | `flutter build apk --debug` | Réussi, installé par-dessus sur Honor MTN-NX1M |
| Linux debug | `flutter test integration_test/lab_test.dart -d linux` | Réussi |
| Exercices | `python3 tool/check_lab_exercises.py` | 18 exercices vérifiés |

Nouvelles dépendances : `file_picker`, pour l'export sur Android, et `xml`.

## Phase 6 — 2026-11-06

| Cible | Commande | Résultat |
| --- | --- | --- |
| Android debug | `flutter build apk --debug` | Réussi, installé par-dessus sur Honor MTN-NX1M |
| Linux debug | `flutter test integration_test/foundations_test.dart -d linux` | Réussi |
| Linux debug | `flutter test integration_test/maitre_test.dart -d linux` | Réussi |

Sur Linux, chaque fichier d'intégration se lance séparément : enchaîner les deux échoue au démarrage de la seconde application.

Nouvelle dépendance : `http`.

## Phase 5, fin de phase — 2026-11-06

| Cible | Commande | Résultat |
| --- | --- | --- |
| Android debug | `flutter build apk --debug` | Réussi, installé par-dessus sur Honor MTN-NX1M |
| Linux debug | `flutter test integration_test -d linux` | Réussi, compilé et exécuté par ces tests |
| Exemples | `python3 tool/check_course_code.py` | 127 exemples exécutés, 2 blocs C++ vérifiés |
| Extraits Flutter | `python3 tool/check_flutter_snippets.py flutter expert` | 18 extraits analysés, APK de preuve compilé |
| Extraits Android | `python3 tool/check_android_snippets.py` sur onze modules | 106 extraits compilés |

Aucune compilation de release de l'application : c'est le sujet de la phase 13.

## Phase 5, tour 5 — 2026-11-06

| Cible | Commande | Résultat |
| --- | --- | --- |
| Android debug | `flutter build apk --debug` | Réussi, installé par-dessus sur Honor MTN-NX1M |
| Linux debug | `flutter test integration_test -d linux` | Réussi, compilé et exécuté par ces tests |
| Exemples | `python3 tool/check_course_code.py` | 109 exemples exécutés, 2 blocs C++ vérifiés |
| Extraits Android | `python3 tool/check_android_snippets.py securite ia` | 21 extraits compilés |

## Phase 5, tour 4 — 2026-11-06

| Cible | Commande | Résultat |
| --- | --- | --- |
| Android debug | `flutter build apk --debug` | Réussi, installé par-dessus sur Honor MTN-NX1M |
| Linux debug | `flutter test integration_test -d linux` | Réussi, compilé et exécuté par ces tests |
| Exemples | `python3 tool/check_course_code.py` | 93 exemples exécutés, 2 blocs C++ vérifiés |
| Extraits Flutter | `python3 tool/check_flutter_snippets.py flutter` | 17 extraits analysés, APK de preuve compilé |
| Extraits Android | `python3 tool/check_android_snippets.py avance` | 10 extraits compilés |

Le projet de preuve Flutter monte à AGP 9.5.0, Gradle 9.6.0 et `compileSdk 37`, et active la désucration de la bibliothèque Java : `permission_handler` et `flutter_local_notifications` les exigent. Ces réglages ne concernent que `build/flutter_snippets`, pas l'application.

## Phase 5, tour 3 — 2026-11-05

| Cible | Commande | Résultat |
| --- | --- | --- |
| Android debug | `flutter build apk --debug` | Réussi, installé par-dessus sur Honor MTN-NX1M |
| Linux debug | `flutter test integration_test -d linux` | Réussi, compilé et exécuté par ces tests |
| Exemples | `python3 tool/check_course_code.py` | 83 exemples compilés et exécutés |
| Extraits Android | `python3 tool/check_android_snippets.py interfaces donnees-reseaux` | 53 extraits compilés |

Le projet de preuve utilise AGP 9.5.0, Gradle 9.6.0, Kotlin 2.4.10, `compileSdk 37`, le BOM Compose 2026.09.00, Room 3.0.3 et Retrofit 3.0.0. Ces versions ne sont pas celles de l'application : AGP 9.1.0, Gradle 9.3.1.

## Phase 5, tour 2 — 2026-11-04

| Cible | Commande | Résultat |
| --- | --- | --- |
| Android debug | `flutter build apk --debug` | Réussi, installé et lancé sur Honor MTN-NX1M |
| Linux debug | `flutter test integration_test -d linux` | Réussi, compilé et exécuté par ces tests |
| Exemples | `python3 tool/check_course_code.py` (kotlinc 2.2.20, javac 21) | 70 exemples compilés et exécutés |
| Projet jetable du module 4 | `gradlew assembleGratuitDebug assemblePayantRelease bundleGratuitRelease` | Réussi |

## Phase 5, tour 1 — 2026-11-04

| Cible | Commande | Résultat |
| --- | --- | --- |
| Android debug | `flutter build apk --debug` | Réussi, installé et lancé sur Honor MTN-NX1M |
| Linux debug | `flutter test integration_test -d linux` | Réussi, compilé et exécuté par ces tests |
| Exemples Kotlin | `python3 tool/check_course_code.py` (kotlinc 2.2.20) | 41 exemples compilés et exécutés |

## Phase 4 — 2026-11-04

| Cible | Commande | Résultat |
| --- | --- | --- |
| Android debug | `flutter build apk --debug` | Réussi, installé et lancé sur Honor MTN-NX1M |
| Linux debug | `flutter test integration_test -d linux` | Réussi, compilé et exécuté par ces tests |
| Android release | — | Non tenté, prévu en phase 13 |
| Linux release et `.deb` | — | Non tenté, prévu en phase 13 |

## Phase 3 — 2026-11-04

| Cible | Commande | Résultat |
| --- | --- | --- |
| Android debug | `flutter build apk --debug` | Réussi, installé et lancé sur Honor MTN-NX1M |
| Linux debug | `flutter build linux --debug` | Réussi, lancé |
| Android release | — | Non tenté, prévu en phase 13 |
| Linux release et `.deb` | — | Non tenté, prévu en phase 13 |

## Phase 2 — 2026-11-04

| Cible | Commande | Résultat |
| --- | --- | --- |
| Android debug | `flutter build apk --debug` | Réussi (207 Mo), installé et lancé sur Honor MTN-NX1M |
| Linux debug | `flutter build linux --debug` | Réussi, lancé et contrôlé sur capture |
| Android release | — | Non tenté, prévu en phase 13 |
| Linux release et `.deb` | — | Non tenté, prévu en phase 13 |

La hausse de taille de l'APK de debug (30 Mo) vient surtout des polices et des icônes. La taille d'un APK de debug n'annonce pas celle du release.

## Phase 1 — 2026-11-04

| Cible | Commande | Résultat |
| --- | --- | --- |
| Android debug | `flutter build apk --debug` | Réussi (177 Mo), installé et lancé sur Honor MTN-NX1M |
| Linux debug | `flutter build linux --debug` | Réussi, lancement constaté |
| Android release | — | Non tenté, prévu en phase 13 |
| Linux release et `.deb` | — | Non tenté, prévu en phase 13 |

Contenu de l'APK de debug, lu avec `aapt` :

- Paquet `com.druideanddroiid.druide_and_droiid`, version 1.0.0 (1).
- Nom affiché : Druide And-Droiīd.
- minSdk 24, targetSdk 36.
- Architectures : arm64-v8a, armeabi-v7a, x86_64.
- `libsqlite3.so` présent pour chaque architecture.
- Permission Internet présente.

## Environnement

- Java n'est pas dans le `PATH` : Flutter utilise le JDK 21 d'Android Studio (`/opt/android-studio/jbr`).
- Gradle n'est pas installé globalement : le wrapper du projet suffit.
- `flutter doctor` signale deux binaires `adb`, sans effet à ce stade.
- Aucune image système Android installée, aucun AVD. Appareil de test : Honor MTN-NX1M en USB.
