import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/sections.dart';
import '../../../app/theme/app_theme.dart';
import '../../../design_system/druide_toast.dart';
import '../../../design_system/techno_card.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';
import 'note_draft.dart';

/// Éditeur d'une note, enregistrée automatiquement pendant la saisie.
class NoteEditorPage extends ConsumerStatefulWidget {
  const NoteEditorPage({this.noteId, this.moduleId, super.key});

  final int? noteId;
  final String? moduleId;

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  late final _lifecycle = AppLifecycleListener(
    // L'application peut être tuée sans préavis une fois en arrière-plan.
    onInactive: () => _draft?.flush(),
    onPause: () => _draft?.flush(),
  );
  final _title = TextEditingController();
  final _body = TextEditingController();
  NoteDraft? _draft;
  var _loading = true;
  var _missing = false;

  @override
  void initState() {
    super.initState();
    _lifecycle;
    _load();
  }

  Future<void> _load() async {
    final repository = ref.read(notesRepositoryProvider);
    final noteId = widget.noteId;
    Note? note;
    var missing = false;

    if (noteId != null) {
      try {
        note = await repository.find(noteId);
      } on Exception catch (error) {
        debugPrint('Lecture de la note impossible : $error');
      }
      missing = note == null;
    }
    if (!mounted) return;

    setState(() {
      _loading = false;
      _missing = missing;
      if (missing) return;
      _title.text = note?.title ?? '';
      _body.text = note?.body ?? '';
      _draft = NoteDraft(repository, note: note, moduleId: widget.moduleId);
    });
  }

  void _onChanged(String _) {
    _draft?.update(title: _title.text, body: _body.text);
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppSection.notes.path);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette note ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final draft = _draft!;
    await draft.discard();
    final id = draft.id;

    try {
      if (id != null) await ref.read(notesRepositoryProvider).delete(id);
      if (mounted) _leave();
    } on Exception catch (error) {
      debugPrint('Suppression de la note impossible : $error');
      if (mounted) {
        showDruideToast(
          context,
          'Impossible de supprimer cette note.',
          kind: ToastKind.error,
        );
      }
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    final draft = _draft;
    if (draft != null) {
      draft.flush();
      draft.dispose();
    }
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.noteId == null ? 'Nouvelle note' : 'Note'),
        actions: [
          if (draft != null)
            IconButton(
              tooltip: 'Supprimer la note',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: switch ((_loading, _missing)) {
        (true, _) => const Center(child: CircularProgressIndicator()),
        (_, true) => const Padding(
          padding: EdgeInsets.all(16),
          child: ErrorNotice(message: 'Cette note est introuvable.'),
        ),
        _ => _buildForm(draft!),
      },
    );
  }

  Widget _buildForm(NoteDraft draft) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _title,
                  onChanged: _onChanged,
                  textCapitalization: TextCapitalization.sentences,
                  style: context.text.titleMedium,
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                    border: InputBorder.none,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: TextField(
                    controller: _body,
                    onChanged: _onChanged,
                    autofocus: widget.noteId == null,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    keyboardType: TextInputType.multiline,
                    style: context.text.bodyLarge,
                    decoration: const InputDecoration(
                      hintText: 'Écrivez votre note…',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                ListenableBuilder(
                  listenable: draft,
                  builder: (context, _) => _SaveIndicator(draft: draft),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveIndicator extends StatelessWidget {
  const _SaveIndicator({required this.draft});

  final NoteDraft draft;

  @override
  Widget build(BuildContext context) {
    final techno = context.techno;
    final style = context.text.labelSmall!;

    if (draft.status == SaveStatus.failed) {
      return Row(
        children: [
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                'Échec de l\'enregistrement. Votre texte reste ici.',
                style: style.copyWith(color: techno.danger),
              ),
            ),
          ),
          TextButton(onPressed: draft.flush, child: const Text('Réessayer')),
        ],
      );
    }

    final label = switch (draft.status) {
      SaveStatus.pending || SaveStatus.saving => 'Enregistrement…',
      SaveStatus.saved => 'Enregistré',
      _ => 'Enregistrement automatique',
    };
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 32),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(label, style: style.copyWith(color: techno.muted)),
      ),
    );
  }
}
