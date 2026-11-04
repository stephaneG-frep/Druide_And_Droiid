import 'dart:async';

import 'package:flutter/foundation.dart';

enum SaveStatus { idle, pending, saving, saved, failed }

/// Sauvegarde automatique : écritures regroupées et strictement sérialisées.
///
/// Une nouvelle écriture ne démarre jamais avant la fin de la précédente. Une
/// frappe pendant une écriture relance donc une écriture, sans doublon.
abstract class Autosaver extends ChangeNotifier {
  Autosaver({required this.debounce});

  final Duration debounce;

  var _dirty = false;
  var _disposed = false;
  Timer? _timer;
  Future<void>? _running;
  SaveStatus _status = SaveStatus.idle;

  SaveStatus get status => _status;

  /// Écrit l'état courant. Renvoie `false` s'il n'y avait rien à écrire.
  @protected
  Future<bool> persist();

  /// À appeler à chaque modification.
  @protected
  void markDirty() {
    _dirty = true;
    _setStatus(SaveStatus.pending);
    _timer?.cancel();
    _timer = Timer(debounce, flush);
  }

  /// Écrit immédiatement ce qui reste à enregistrer.
  Future<void> flush() {
    _timer?.cancel();
    return _running ??= _drain().whenComplete(() => _running = null);
  }

  /// Abandonne les écritures en attente, avant une suppression.
  Future<void> discard() async {
    _timer?.cancel();
    _dirty = false;
    await _running;
    _dirty = false;
  }

  Future<void> _drain() async {
    var wrote = false;
    while (_dirty) {
      _dirty = false;
      _setStatus(SaveStatus.saving);
      try {
        wrote = await persist();
      } on Exception catch (error) {
        debugPrint('Sauvegarde automatique impossible : $error');
        _dirty = true;
        _setStatus(SaveStatus.failed);
        return;
      }
    }
    if (_status == SaveStatus.saving) {
      _setStatus(wrote ? SaveStatus.saved : SaveStatus.idle);
    }
  }

  void _setStatus(SaveStatus status) {
    _status = status;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
