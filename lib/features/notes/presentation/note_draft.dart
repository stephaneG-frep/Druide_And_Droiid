import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/notes_repository.dart';
import '../domain/note.dart';

enum SaveStatus { idle, pending, saving, saved, failed }

/// Brouillon d'une note avec sauvegarde automatique.
///
/// Les écritures sont regroupées et strictement sérialisées : la création d'une
/// nouvelle note ne peut donc jamais être doublée. Une note neuve restée vide
/// n'est pas créée.
class NoteDraft extends ChangeNotifier {
  NoteDraft(
    this._repository, {
    Note? note,
    this.moduleId,
    this.debounce = const Duration(milliseconds: 300),
  }) : _id = note?.id,
       _title = note?.title ?? '',
       _body = note?.body ?? '';

  final NotesRepository _repository;
  final String? moduleId;
  final Duration debounce;

  int? _id;
  String _title;
  String _body;
  var _dirty = false;
  var _disposed = false;
  Timer? _timer;
  Future<void>? _running;
  SaveStatus _status = SaveStatus.idle;

  int? get id => _id;
  String get title => _title;
  String get body => _body;
  SaveStatus get status => _status;

  void update({required String title, required String body}) {
    if (title == _title && body == _body) return;
    _title = title;
    _body = body;
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
    while (_dirty) {
      _dirty = false;
      final title = _title;
      final body = _body;

      if (_id == null && title.trim().isEmpty && body.trim().isEmpty) {
        _setStatus(SaveStatus.idle);
        return;
      }

      _setStatus(SaveStatus.saving);
      try {
        final id = _id;
        if (id == null) {
          _id = await _repository.create(
            title: title,
            body: body,
            moduleId: moduleId,
          );
        } else {
          await _repository.update(id, title: title, body: body);
        }
      } on Exception catch (error) {
        debugPrint('Enregistrement de la note impossible : $error');
        _dirty = true;
        _setStatus(SaveStatus.failed);
        return;
      }
    }
    if (_status == SaveStatus.saving) _setStatus(SaveStatus.saved);
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
