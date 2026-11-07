import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../design_system/arcane_button.dart';
import '../../../design_system/druide_toast.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';
import '../../../design_system/xp_bar.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/presentation/notes_page.dart';
import '../../progression/data/progress_repository.dart';
import '../data/course_repository.dart';
import '../data/favorites_repository.dart';
import '../domain/course.dart';
import '../domain/module_catalog.dart';
import '../domain/rewards.dart';
import 'level_color.dart';
import 'paths.dart';
import '../../sauvegarde/presentation/pdf_action.dart';
import '../../sauvegarde/data/document_exports.dart';

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
    final course = ref.watch(courseProvider(module.id));

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
        if (course.value case CourseReady(:final course))
          PdfExportButton(
            fileName: 'module-${module.number}-${module.id}.pdf',
            build: (ref) =>
                ref.read(pdfExporterProvider).course(module, course),
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
        ...switch (course.value) {
          CourseReady(:final course) => [
            _CourseSection(moduleId: module.id, course: course),
          ],
          CourseUnreadable() => const [
            ErrorNotice(
              message: 'Le contenu de ce module n\'a pas pu être chargé.',
            ),
          ],
          CourseAbsent() => const [
            PhaseNotice(
              message: 'Les leçons de ce module ne sont pas encore rédigées.',
            ),
          ],
          null => const <Widget>[],
        },
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

class _CourseSection extends ConsumerWidget {
  const _CourseSection({required this.moduleId, required this.course});

  final String moduleId;
  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final techno = context.techno;
    final completed = ref.watch(completedLessonsProvider).value ?? const {};
    final best = ref.watch(bestAttemptsProvider).value ?? const {};
    final evaluation = best[evaluationQuizId(moduleId)];
    final done = course.lessons.where((l) => completed.contains(l.id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        const SectionTitle('Leçons'),
        StepProgress(done: done, total: course.lessons.length, unit: 'leçons'),
        for (final (index, lesson) in course.lessons.indexed)
          TechnoCard(
            onTap: () => context.go(lessonPath(moduleId, lesson.id)),
            child: Row(
              children: [
                Icon(
                  completed.contains(lesson.id)
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: completed.contains(lesson.id)
                      ? techno.emeraude
                      : techno.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}. ${lesson.title}',
                        style: context.text.titleSmall,
                      ),
                      Text(
                        '${lesson.minutes} min',
                        style: context.text.bodySmall!.copyWith(
                          color: techno.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        const SectionTitle('Évaluation'),
        TechnoCard(
          accent: evaluation?.passed ?? false ? techno.emeraude : null,
          onTap: () => context.go(evaluationPath(moduleId)),
          child: Row(
            children: [
              Icon(Icons.military_tech_outlined, color: techno.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Évaluation du module',
                      style: context.text.titleSmall,
                    ),
                    Text(
                      evaluation == null
                          ? '${course.evaluation.questions.length} questions, '
                                '${course.evaluation.passPercent} % pour réussir'
                          : 'Meilleur score : ${evaluation.score} / '
                                '${evaluation.maxScore}'
                                '${evaluation.passed ? ', réussie' : ''}',
                      style: context.text.bodySmall!.copyWith(
                        color: techno.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
        if (course.resources.isNotEmpty) ...[
          const SectionTitle('Pour aller plus loin'),
          TechnoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                for (final resource in course.resources)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(resource.title, style: context.text.titleSmall),
                      SelectableText(
                        resource.url,
                        style: context.text.bodySmall!.copyWith(
                          color: techno.cyan,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
