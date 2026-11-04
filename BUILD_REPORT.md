# Rapport de compilation

## Phase 1 — 2026-11-04

| Cible | Commande | Résultat |
| --- | --- | --- |
| Android debug | `flutter build apk --debug` | Réussi (177 Mo, compilation 261 s) |
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
- Aucune image système Android installée, aucun AVD.
