import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/sections.dart';
import '../../../app/theme/app_theme.dart';
import '../../../design_system/arcane_button.dart';
import '../../../design_system/dialogue_bubble.dart';
import '../../../design_system/mascot/maitre_and_droiid.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';
import '../../academie/domain/module_catalog.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';

const newNotePath = '/note/nouvelle';

String notePath(int id) => '/note/$id';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);

    return PageFrame(
      title: AppSection.notes.label,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: ArcaneButton(
            label: 'Nouvelle note',
            icon: Icons.add,
            onPressed: () => context.push(newNotePath),
          ),
        ),
        ...switch (notes) {
          AsyncValue(hasError: true) => const [
            ErrorNotice(message: 'Impossible de lire vos notes.'),
          ],
          AsyncValue(value: final list?) when list.isEmpty => const [
            DialogueBubble(
              origin: 'Message préenregistré',
              mood: MascotMood.encourageant,
              message:
                  'Votre grimoire personnel est encore vierge. Notez-y '
                  'ce que vous voulez retenir !',
            ),
          ],
          AsyncValue(value: final list?) => [
            for (final note in list) NoteCard(note: note),
          ],
          _ => const <Widget>[],
        },
      ],
    );
  }
}

class NoteCard extends StatelessWidget {
  const NoteCard({required this.note, super.key});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final techno = context.techno;
    final module = note.moduleId == null ? null : moduleById(note.moduleId!);
    final excerpt = note.body.trim();

    return TechnoCard(
      onTap: () => context.push(notePath(note.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(note.displayTitle, style: context.text.titleSmall),
          if (excerpt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              excerpt,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall!.copyWith(color: techno.muted),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (module != null)
                TechnoTag(label: 'Module ${module.number}', color: techno.cyan),
              Text(
                'Modifiée le ${_formatDate(note.updatedAt)}',
                style: context.text.labelSmall!.copyWith(color: techno.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} '
        'à ${two(date.hour)}:${two(date.minute)}';
  }
}
