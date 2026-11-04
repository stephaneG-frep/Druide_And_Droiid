# Druide And-Droiīd

« La magie d'Android, du premier sort au code expert ! »

Académie Android interactive en français, pour Android et Linux, développée avec Flutter.

**État : phase 1 (fondations) terminée.** La navigation fonctionne, mais les rubriques n'ont pas encore de contenu. Le détail est dans [ROADMAP.md](ROADMAP.md).

## Prérequis

- Flutter stable 3.47 ou plus (Dart 3.13)
- Android : Android SDK et un JDK 17 ou plus (celui d'Android Studio convient)
- Linux : `clang`, `cmake`, `ninja`, `pkg-config`, `libgtk-3-dev`, `libsecret-1-dev`

## Lancer le projet

```bash
flutter pub get
flutter run -d linux     # ou un appareil Android
```

## Vérifier le projet

```bash
flutter analyze
flutter test
flutter test integration_test -d linux
```

Après toute modification des tables Drift, régénérer le code :

```bash
dart run build_runner build
```

## Documents

| Fichier | Contenu |
| --- | --- |
| [SPEC.md](SPEC.md) | Cahier des charges |
| [DESIGN.md](DESIGN.md) | Direction artistique et composants |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Architecture et décisions techniques |
| [ROADMAP.md](ROADMAP.md) | Phases et avancement |
| [CHANGELOG.md](CHANGELOG.md) | Modifications |
| [TEST_REPORT.md](TEST_REPORT.md) | Résultats des tests |
| [BUILD_REPORT.md](BUILD_REPORT.md) | État réel des compilations |
| [USER_GUIDE.md](USER_GUIDE.md) | Mode d'emploi |
