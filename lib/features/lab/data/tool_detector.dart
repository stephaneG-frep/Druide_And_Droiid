import 'dart:io';

import '../domain/lab_tools.dart';

/// Chemins trouvés, avec ce qu'il faut pour lancer les outils.
class LabToolchain {
  const LabToolchain({this.paths = const {}, this.javaHome, this.sdkHome});

  final Map<LabTool, String> paths;
  final String? javaHome;
  final String? sdkHome;

  String? path(LabTool tool) => paths[tool];
  bool has(LabTool tool) => paths.containsKey(tool);
}

/// Cherche les outils dans le PATH, puis aux emplacements habituels : une
/// application lancée depuis le bureau n'hérite pas toujours du PATH du terminal.
class ToolDetector {
  const ToolDetector({required this.environment, required this.exists});

  factory ToolDetector.system() => ToolDetector(
    environment: Platform.environment,
    exists: (path) =>
        FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound,
  );

  final Map<String, String> environment;
  final bool Function(String path) exists;

  LabToolchain detect() {
    final home = environment['HOME'] ?? '';
    final pathDirectories = (environment['PATH'] ?? '')
        .split(':')
        .where((directory) => directory.isNotEmpty)
        .toList();

    String? find(String name, List<String> known) {
      for (final directory in pathDirectories) {
        final candidate = '$directory/$name';
        if (exists(candidate)) return candidate;
      }
      return known.where(exists).firstOrNull;
    }

    final sdkHome = [
      environment['ANDROID_HOME'],
      environment['ANDROID_SDK_ROOT'],
      '$home/Android/Sdk',
    ].whereType<String>().where(exists).firstOrNull;

    final javaHome = [
      environment['JAVA_HOME'],
      '/opt/android-studio/jbr',
      '$home/android-studio/jbr',
      '/snap/android-studio/current/jbr',
    ].whereType<String>().where((path) => exists('$path/bin/java')).firstOrNull;

    final flutterRoot =
        environment['FLUTTER_ROOT'] ?? '$home/snap/flutter/common/flutter';

    final paths = <LabTool, String?>{
      LabTool.java: javaHome != null
          ? '$javaHome/bin/java'
          : find('java', const []),
      LabTool.kotlinc: find('kotlinc', [
        '/opt/android-studio/plugins/Kotlin/kotlinc/bin/kotlinc',
        '$home/android-studio/plugins/Kotlin/kotlinc/bin/kotlinc',
        '/snap/android-studio/current/plugins/Kotlin/kotlinc/bin/kotlinc',
      ]),
      // Le lanceur de Flutter vérifie sa mise à jour : autant viser le vrai SDK.
      LabTool.dart: exists('$flutterRoot/bin/cache/dart-sdk/bin/dart')
          ? '$flutterRoot/bin/cache/dart-sdk/bin/dart'
          : find('dart', const []),
      LabTool.flutter: find('flutter', ['$flutterRoot/bin/flutter']),
      LabTool.androidStudio: find('android-studio', [
        '/opt/android-studio/bin/studio.sh',
        '$home/android-studio/bin/studio.sh',
        '/snap/bin/android-studio',
      ]),
      LabTool.androidSdk: sdkHome,
      LabTool.adb: sdkHome != null && exists('$sdkHome/platform-tools/adb')
          ? '$sdkHome/platform-tools/adb'
          : find('adb', const []),
      LabTool.gradle: find('gradle', const []),
      LabTool.emulator: sdkHome != null && exists('$sdkHome/emulator/emulator')
          ? '$sdkHome/emulator/emulator'
          : find('emulator', const []),
    };

    return LabToolchain(
      paths: {
        for (final entry in paths.entries)
          if (entry.value != null) entry.key: entry.value!,
      },
      javaHome: javaHome,
      sdkHome: sdkHome,
    );
  }
}
