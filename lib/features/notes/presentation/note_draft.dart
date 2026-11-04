import '../../../core/autosave.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';

export '../../../core/autosave.dart' show SaveStatus;

/// Brouillon d'une note. Une note neuve restée vide n'est pas créée.
class NoteDraft extends Autosaver {
  NoteDraft(
    this._repository, {
    Note? note,
    this.moduleId,
    super.debounce = const Duration(milliseconds: 300),
  }) : _id = note?.id,
       _title = note?.title ?? '',
       _body = note?.body ?? '';

  final NotesRepository _repository;
  final String? moduleId;

  int? _id;
  String _title;
  String _body;

  int? get id => _id;
  String get title => _title;
  String get body => _body;

  void update({required String title, required String body}) {
    if (title == _title && body == _body) return;
    _title = title;
    _body = body;
    markDirty();
  }

  @override
  Future<bool> persist() async {
    final title = _title;
    final body = _body;
    final id = _id;

    if (id == null) {
      if (title.trim().isEmpty && body.trim().isEmpty) return false;
      _id = await _repository.create(
        title: title,
        body: body,
        moduleId: moduleId,
      );
    } else {
      await _repository.update(id, title: title, body: body);
    }
    return true;
  }
}
