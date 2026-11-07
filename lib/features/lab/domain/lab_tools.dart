/// Outils que le Lab sait trouver sur Linux, avec leur procédure d'installation.
enum LabTool {
  java(
    'JDK',
    'Exécute le code Java et Kotlin.',
    'Le JDK livré avec Android Studio convient. Sinon :',
    'sudo apt install openjdk-21-jdk',
  ),
  kotlinc(
    'Compilateur Kotlin',
    'Compile le code Kotlin.',
    'Android Studio le fournit dans son extension Kotlin. Sinon :',
    'sudo snap install kotlin --classic',
  ),
  dart(
    'Dart',
    'Exécute le code Dart.',
    'Dart est livré avec Flutter :',
    'sudo snap install flutter --classic',
  ),
  flutter(
    'Flutter',
    'Compile les projets Flutter.',
    'Installez le SDK, puis lancez une première fois flutter doctor :',
    'sudo snap install flutter --classic',
  ),
  androidStudio(
    'Android Studio',
    'Développe, débogue et gère le SDK.',
    'Téléchargez-le sur developer.android.com/studio, ou :',
    'sudo snap install android-studio --classic',
  ),
  androidSdk(
    'SDK Android',
    'Contient les plateformes et les outils de compilation.',
    'Ouvrez Android Studio, puis Tools, SDK Manager. Le dossier habituel est '
        '~/Android/Sdk. Pour un autre dossier, indiquez-le :',
    'export ANDROID_HOME=~/Android/Sdk',
  ),
  adb(
    'ADB',
    'Communique avec un téléphone ou un émulateur.',
    'Installez Platform-Tools depuis le SDK Manager d\'Android Studio, ou :',
    'sudo apt install adb',
  ),
  gradle(
    'Gradle',
    'Compile les projets Android. Facultatif : un projet fournit son ./gradlew.',
    'Utilisez de préférence ./gradlew dans votre projet. Pour une version '
        'globale :',
    'sudo apt install gradle',
  ),
  emulator(
    'Émulateur Android',
    'Lance un appareil virtuel.',
    'Installez Android Emulator depuis le SDK Manager, puis créez un appareil '
        'dans Device Manager. En ligne de commande :',
    'sdkmanager "emulator"',
  );

  const LabTool(this.label, this.role, this.install, this.command);

  final String label;
  final String role;
  final String install;
  final String command;
}

/// Seules ces commandes existent : le Lab n'offre aucun terminal libre.
enum LabCommand {
  adbDevices(LabTool.adb, 'Appareils connectés', ['devices', '-l']),
  adbVersion(LabTool.adb, 'Version d\'ADB', ['version']),
  adbCrashLog(LabTool.adb, 'Derniers plantages', [
    'logcat',
    '-b',
    'crash',
    '-d',
    '-t',
    '500',
  ]),
  listAvds(LabTool.emulator, 'Appareils virtuels', ['-list-avds']),
  gradleVersion(LabTool.gradle, 'Version de Gradle', ['--version']),
  javaVersion(LabTool.java, 'Version du JDK', ['-version']),
  flutterVersion(LabTool.flutter, 'Version de Flutter', ['--version']);

  const LabCommand(this.tool, this.label, this.arguments);

  final LabTool tool;
  final String label;
  final List<String> arguments;
}

final _avdName = RegExp(r'^[A-Za-z0-9._-]+$');

/// Ne garde que de vrais noms d'appareil virtuels, sans journaux de l'outil.
List<String> parseAvds(String output) => [
  for (final line in output.split('\n'))
    if (_avdName.hasMatch(line.trim())) line.trim(),
];
