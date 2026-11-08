# Reconstruire les livrables

*Instructions écrites pour qui reconstruit l'application à partir des sources : toi, ou un futur contributeur.*

Les trois livrables de la version 1.0.0 sont écrits dans `dist/`, un dossier ignoré par git.

| Livrable | Commande |
| --- | --- |
| `Druide_And-Droiid_v1.0.0.apk` | `flutter build apk --release`, puis copie de `build/app/outputs/flutter-apk/app-release.apk` |
| `Druide_And-Droiid_v1.0.0_amd64.deb` | `python3 tool/build_deb.py` |
| `Druide_And-Droiid_v1.0.0_sources.zip` | `tool/build_sources.sh` |

## Préparer la machine

- Flutter stable 3.47 ou plus (Dart 3.13), puis `flutter pub get`.
- **Android** : Android SDK (plateforme et build-tools 36 ou plus), NDK installé par Flutter, JDK 17 ou plus (celui d'Android Studio convient).
- **Linux** : `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`, `libsecret-1-dev`, et `dpkg-deb` pour le paquet.

Aucune clé d'API ni aucun secret n'est nécessaire pour compiler. Les clés des fournisseurs d'IA sont saisies dans l'application et rangées dans le coffre du système.

## APK Android

```bash
flutter build apk --release
mkdir -p dist
cp build/app/outputs/flutter-apk/app-release.apk dist/Druide_And-Droiid_v1.0.0.apk
```

N'ajoutez pas `--no-pub` : sans cette étape, Flutter garde l'enregistrement des plugins de debug, qui cite `integration_test`, et la compilation release échoue.

L'APK contient le code natif pour `arm64-v8a`, `armeabi-v7a` et `x86_64`. Il demande Android 7.0 (API 24) au minimum.

### Signature

Sans fichier `android/key.properties`, la release est signée avec la **clé de debug** de la machine de compilation (`~/.config/.android/debug.keystore` sur cette machine, `~/.android/debug.keystore` sur d'autres). Gradle l'annonce par un avertissement. Cet APK s'installe et se met à jour normalement, mais seulement depuis la même machine, et il ne peut pas être publié sur un magasin d'applications.

Pour publier, créez une clé une fois pour toutes, rangée hors du dépôt :

```bash
keytool -genkeypair -v -keystore ~/.android-keys/druide-upload.jks \
  -keyalg RSA -keysize 4096 -validity 10000 -alias druide
```

puis écrivez `android/key.properties` :

```properties
storeFile=/home/<vous>/.android-keys/druide-upload.jks
storePassword=<mot de passe>
keyAlias=druide
keyPassword=<mot de passe>
```

Ce fichier et les fichiers `.jks` sont ignorés par git. Gardez une copie de la clé et des mots de passe en lieu sûr : sans eux, aucune mise à jour ne pourra s'installer par-dessus. Changer de clé oblige à désinstaller l'application, donc à faire d'abord une sauvegarde complète (Paramètres, Sauvegardes).

## Paquet Debian

```bash
python3 tool/build_deb.py          # compile en release puis assemble
python3 tool/build_deb.py --skip-build   # réutilise build/linux/…/release
```

L'architecture du paquet est celle de la machine de compilation : `amd64` sur un PC x86-64, `arm64` sur une machine ARM 64 bits. Seul `amd64` a été compilé et essayé. Le script lit les bibliothèques liées avec `ldd` et en déduit le champ `Depends` avec `dpkg -S` : compilez sur la plus ancienne version d'Ubuntu visée (ici 22.04).

Le paquet installe :

- l'application dans `/opt/druide-and-droiid/` ;
- la commande `druide-and-droiid` dans `/usr/bin/` ;
- le lanceur `druide-and-droiid.desktop` et l'icône en 64, 128, 256 et 512 pixels ;
- la documentation dans `/usr/share/doc/druide-and-droiid/`.

Installer, puis désinstaller :

```bash
sudo apt install ./dist/Druide_And-Droiid_v1.0.0_amd64.deb
sudo apt remove druide-and-droiid
```

Les données de l'utilisateur restent dans `~/.local/share/com.druideanddroiid.druide_and_droiid/` après la désinstallation, comme pour toute application : supprimez ce dossier pour repartir de zéro.

## Archive des sources

```bash
tool/build_sources.sh
```

Le script refuse de travailler si des modifications ne sont pas commitées. Il archive le commit courant avec `git archive`, donc seulement les fichiers suivis : sources Flutter, ressources, cours, tests, documentation et scripts. `android/key.properties`, les clés `.jks`, `local.properties` et les dossiers de build n'y sont pas.

Depuis l'archive décompressée :

```bash
flutter pub get
flutter analyze && flutter test
flutter build apk --release
python3 tool/build_deb.py
```
