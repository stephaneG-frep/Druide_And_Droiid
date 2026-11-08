import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Version affichée dans l'écran « Licences ». À garder alignée sur pubspec.
const appVersion = '1.0.0';

/// Polices embarquées et fichier de licence SIL OFL 1.1 de chacune.
const fontLicenses = {
  'Atkinson Hyperlegible': 'assets/fonts/atkinsonhyperlegible-OFL.txt',
  'Chakra Petch': 'assets/fonts/chakrapetch-OFL.txt',
  'IBM Plex Mono': 'assets/fonts/ibmplexmono-OFL.txt',
};

/// Ajoute les licences des polices à celles des paquets, que Flutter
/// enregistre déjà, pour qu'elles apparaissent dans `showLicensePage`.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final entry in fontLicenses.entries) {
      final text = await rootBundle.loadString(entry.value);
      yield LicenseEntryWithLineBreaks([entry.key], text);
    }
  });
}
