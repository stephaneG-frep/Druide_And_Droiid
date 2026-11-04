import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/motion.dart';
import '../data/appearance_repository.dart';
import '../domain/appearance.dart';

/// Apparence affichée au premier rendu, avant toute restauration.
final initialAppearanceProvider = Provider<Appearance>(
  (ref) => Appearance.defaults,
);

class AppearanceController extends Notifier<Appearance> {
  @override
  Appearance build() => ref.read(initialAppearanceProvider);

  /// Recharge les réglages enregistrés. Un échec ne doit pas empêcher le
  /// démarrage : l'application garde alors l'apparence par défaut.
  Future<void> restore() async {
    try {
      state = await ref
          .read(appearanceRepositoryProvider)
          .load()
          .timeout(const Duration(seconds: 3));
    } on Exception catch (error) {
      debugPrint('Restauration de l\'apparence impossible : $error');
    }
  }

  /// Renvoie `false` si le réglage est appliqué sans avoir pu être enregistré.
  Future<bool> setThemeMode(ThemeMode mode) {
    return _apply(state.copyWith(themeMode: mode));
  }

  Future<bool> setMotion(MotionLevel motion) {
    return _apply(state.copyWith(motion: motion));
  }

  Future<bool> _apply(Appearance appearance) async {
    state = appearance;
    try {
      await ref.read(appearanceRepositoryProvider).save(appearance);
      return true;
    } on Exception catch (error) {
      debugPrint('Enregistrement de l\'apparence impossible : $error');
      return false;
    }
  }
}

final appearanceProvider = NotifierProvider<AppearanceController, Appearance>(
  AppearanceController.new,
);
