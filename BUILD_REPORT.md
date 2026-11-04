# Rapport de compilation

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
