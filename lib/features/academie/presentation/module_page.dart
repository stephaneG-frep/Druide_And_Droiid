import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../design_system/arcane_button.dart';
import '../../../design_system/druide_toast.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/presentation/notes_page.dart';
import '../data/favorites_repository.dart';
import '../domain/module_catalog.dart';
import 'level_color.dart';

/// Programme d'un module. Les leçons elles-mêmes arrivent en phases 4 et 5.
class ModulePage extends ConsumerWidget {
  const ModulePage({required this.module, super.key});

  final AcademyModule module;

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref, {
    required bool favorite,
  }) async {
    try {
      await ref
          .read(favoritesRepositoryProvider)
          .setFavorite(FavoriteKind.module, module.id, favorite: favorite);
    } on Exception catch (error) {
      debugPrint('Enregistrement du favori impossible : $error');
      if (context.mounted) {
        showDruideToast(
          context,
          'Impossible d\'enregistrer ce favori.',
          kind: ToastKind.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final techno = context.techno;
    final favorites = ref.watch(favoriteModulesProvider).value ?? const {};
    final isFavorite = favorites.contains(module.id);
    final notes = ref.watch(moduleNotesProvider(module.id)).value ?? const [];

    return PageFrame(
      title: 'Module ${module.number}',
      actions: [
        IconButton(
          tooltip: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
          isSelected: isFavorite,
          icon: const Icon(Icons.star_border),
          selectedIcon: Icon(Icons.star, color: techno.orange),
          onPressed: () => _toggleFavorite(context, ref, favorite: !isFavorite),
        ),
      ],
      children: [
        Text(module.title, style: context.text.headlineSmall),
        Text(module.summary, style: context.text.bodyLarge),
        Align(
          alignment: Alignment.centerLeft,
          child: TechnoTag(
            label: module.level.label,
            color: levelColor(context, module.level),
          ),
        ),
        const SectionTitle('Au programme'),
        TechnoCard(
          child: Column(
            children: [
              for (final topic in module.topics)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome, size: 18, color: techno.cyan),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(topic, style: context.text.bodyMedium),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const PhaseNotice(
          message: 'Les leçons de ce module ne sont pas encore rédigées.',
        ),
        const SectionTitle('Mes notes sur ce module'),
        for (final note in notes) NoteCard(note: note),
        Align(
          alignment: Alignment.centerLeft,
          child: ArcaneButton(
            label: 'Ajouter une note',
            icon: Icons.add,
            secondary: true,
            onPressed: () => context.push('$newNotePath?module=${module.id}'),
          ),
        ),
      ],
    );
  }
}
