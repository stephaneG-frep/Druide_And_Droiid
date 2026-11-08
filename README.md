# Druide And-Droiīd

« La magie d'Android, du premier sort au code expert ! »

Académie Android interactive en français, pour Android et Linux, développée avec Flutter.

**État : version 1.0.0 compilée (phase 13).** APK Android et paquet Debian produits et installés ; quelques vérifications restent à faire, listées dans [ROADMAP.md](ROADMAP.md). L'APK est signé avec une clé de debug : il n'est pas destiné à un magasin d'applications.

## Installer

- **Android 7.0 ou plus** : installez `Druide_And-Droiid_v1.0.0.apk` (autorisez l'installation depuis cette source), ou `adb install Druide_And-Droiid_v1.0.0.apk`.
- **Ubuntu, PC x86-64** (essayé sur 22.04 seulement) : `sudo apt install ./Druide_And-Droiid_v1.0.0_amd64.deb`, puis lancez **Druide And-Droiīd** depuis le menu ou avec `druide-and-droiid`. Pour désinstaller : `sudo apt remove druide-and-droiid`.

Reconstruire ces fichiers : voir [BUILD.md](BUILD.md).

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

**Attention :** lancés sur un téléphone, les tests d'intégration désinstallent l'application à la fin, ce qui efface ses données. L'APK produit par ces tests démarre sur les tests : refaites `flutter build apk --debug` avant de réinstaller.

Après toute modification des tables Drift, régénérer le code :

```bash
dart run build_runner build
```

Après toute modification d'un cours, contrôlez les exemples Kotlin et Java (`kotlinc` et le JDK sont fournis avec Android Studio) :

```bash
python3 tool/check_course_code.py
python3 tool/check_lab_exercises.py
python3 tool/check_projects.py
```

Pour compiler les extraits Android d'un module dans un vrai projet Gradle (le premier lancement télécharge plusieurs gigaoctets) :

```bash
python3 tool/check_android_snippets.py fondations kotlin java android-studio interfaces donnees-reseaux avance securite ia publication expert
python3 tool/check_flutter_snippets.py flutter expert
```

Pour régénérer l'icône et des aperçus PNG des écrans :

```bash
FLUTTER_ROOT=<dossier de Flutter> RENDER_DIR=build/render flutter test tool/render_brand_test.dart
```

## Licences des polices

Chakra Petch, Atkinson Hyperlegible et IBM Plex Mono sont distribuées sous licence SIL Open Font License. Les textes de licence sont dans [assets/fonts/](assets/fonts/).

## Documents

| Fichier | Contenu |
| --- | --- |
| [SPEC.md](SPEC.md) | Cahier des charges |
| [DESIGN.md](DESIGN.md) | Direction artistique et composants |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Architecture et décisions techniques |
| [ROADMAP.md](ROADMAP.md) | Phases et avancement |
| [CHANGELOG.md](CHANGELOG.md) | Modifications |
| [TEST_REPORT.md](TEST_REPORT.md) | Résultats des tests |
| [BUILD.md](BUILD.md) | Reconstruire l'APK, le paquet et l'archive des sources |
| [BUILD_REPORT.md](BUILD_REPORT.md) | État réel des compilations |
| [USER_GUIDE.md](USER_GUIDE.md) | Mode d'emploi |
