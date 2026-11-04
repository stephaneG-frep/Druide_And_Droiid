// Génère l'icône de l'application et des aperçus PNG des écrans.
//
//   RENDER_DIR=/chemin/sortie flutter test tool/render_brand_test.dart
//
// Les polices réelles sont chargées : le rendu reflète l'application.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:druide_and_droiid/app/router.dart';
import 'package:druide_and_droiid/app/sections.dart';
import 'package:druide_and_droiid/app/theme/palette.dart';
import 'package:druide_and_droiid/design_system/mascot/mascot_painter.dart';
import 'package:druide_and_droiid/features/academie/domain/module_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/support/pump_app.dart';

final outputDir = Platform.environment['RENDER_DIR'] ?? 'build/render';

Future<void> loadFonts() async {
  const families = {
    'ChakraPetch': ['Medium', 'SemiBold', 'Bold'],
    'AtkinsonHyperlegible': ['Regular', 'Bold'],
    'IBMPlexMono': ['Regular', 'SemiBold'],
  };
  for (final MapEntry(key: family, value: weights) in families.entries) {
    final loader = FontLoader(family);
    for (final weight in weights) {
      loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
    }
    await loader.load();
  }

  final flutterRoot = Platform.environment['FLUTTER_ROOT']!;
  final icons = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  await (FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync()))))
      .load();
}

Future<void> writePng(ui.Image image, String name) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('$outputDir/$name.png')..createSync(recursive: true);
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
}

/// Dessine la mascotte, cadrée sur la tête et la barbe, centrée sur le canevas.
void paintEmblem(Canvas canvas, double size) {
  canvas.save();
  final scale = size / 200;
  canvas.scale(scale);
  canvas.translate(4, 2);
  MascotPainter(mood: MascotMood.joyeux).paint(canvas, const Size(200, 240));
  canvas.restore();
}

Future<ui.Image> renderIcon({required bool withBackground}) {
  const size = 1024.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  if (withBackground) {
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, size, size),
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF2E2470), Palette.fondSombre],
        ).createShader(const Rect.fromLTWH(0, 0, size, size)),
    );
  }

  // La zone sûre d'une icône adaptative occupe les 66 % centraux.
  final emblem = size * (withBackground ? 0.78 : 0.56);
  final height = emblem * 1.2;
  canvas.translate((size - emblem) / 2, (size - height) / 2);
  paintEmblem(canvas, emblem);
  return recorder.endRecording().toImage(1024, 1024);
}

void main() {
  testWidgets('icônes', (tester) async {
    await tester.runAsync(() async {
      await writePng(await renderIcon(withBackground: true), 'icon_full');
      await writePng(
        await renderIcon(withBackground: false),
        'icon_foreground',
      );
    });
  });

  final previews = <String, String>{
    'accueil': AppSection.accueil.path,
    'academie': AppSection.academie.path,
    'module': '${AppSection.academie.path}/${academyModules[1].id}',
    'maitre': AppSection.maitre.path,
    'lab': AppSection.lab.path,
    'chaudron': AppSection.chaudron.path,
    'projets': AppSection.projets.path,
    'progression': AppSection.progression.path,
    'grimoire': AppSection.grimoire.path,
    'parametres': AppSection.parametres.path,
    'plus': plusPath,
  };

  for (final (label, size, mode) in [
    ('tel_sombre', phone, ThemeMode.dark),
    ('tel_clair', phone, ThemeMode.light),
    ('pc_sombre', desktop, ThemeMode.dark),
    ('pc_clair', desktop, ThemeMode.light),
  ]) {
    testWidgets('aperçus $label', (tester) async {
      await tester.runAsync(loadFonts);
      final container = await pumpApp(tester, size: size, themeMode: mode);

      for (final MapEntry(key: name, value: path) in previews.entries) {
        await goTo(tester, container, path);
        await tester.runAsync(() async {
          // Laisse le moteur décoder les polices avant la capture.
          await Future<void>.delayed(const Duration(milliseconds: 30));
        });
        await tester.pump();
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byType(RepaintBoundary).first,
        );
        await tester.runAsync(() async {
          await writePng(await boundary.toImage(), '${label}_$name');
        });
      }
    });
  }
}
