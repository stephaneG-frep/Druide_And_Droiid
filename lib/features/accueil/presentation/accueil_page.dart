import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/sections.dart';
import '../../../app/theme/app_theme.dart';
import '../../../design_system/adaptive_grid.dart';
import '../../../design_system/arcane_button.dart';
import '../../../design_system/mascot/maitre_and_droiid.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/quiz_card.dart';
import '../../../design_system/stat_tile.dart';
import '../../../design_system/techno_card.dart';
import '../../../design_system/xp_bar.dart';
import '../../academie/domain/module_catalog.dart';
import '../../academie/presentation/next_lesson.dart';
import '../../academie/presentation/paths.dart';
import '../../../design_system/druide_toast.dart';
import '../../progression/data/progress_repository.dart';
import '../../progression/domain/progression.dart';
import '../domain/flash_questions.dart';

class AccueilPage extends ConsumerWidget {
  const AccueilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(progressProvider);
    final progress = snapshot.value ?? ProgressSnapshot.start;
    final today = DateTime.now();

    return PageFrame(
      title: AppSection.accueil.label,
      children: [
        _Hero(progress: progress, next: ref.watch(nextLessonProvider).value),
        if (snapshot.hasError)
          const ErrorNotice(
            message:
                'Impossible de lire votre progression : les chiffres '
                'ci-dessous ne sont peut-être pas à jour.',
          ),
        AdaptiveGrid(
          minItemWidth: 140,
          maxColumns: 4,
          children: [
            StatTile(
              icon: Icons.menu_book_outlined,
              value: '${academyModules.length}',
              label: 'Modules au programme',
            ),
            StatTile(
              icon: Icons.task_alt,
              value: '${progress.lessonsCompleted}',
              label: 'Leçons terminées',
            ),
            StatTile(
              icon: Icons.quiz_outlined,
              value: '${progress.quizzesPassed}',
              label: 'Quiz réussis',
            ),
            StatTile(
              icon: Icons.bolt,
              value: '${progress.xp}',
              label: 'Points d\'expérience',
            ),
          ],
        ),
        const SectionTitle('Question flash'),
        _FlashQuiz(date: today),
        const SectionTitle('Explorer'),
        AdaptiveGrid(
          minItemWidth: 240,
          maxColumns: 4,
          children: [
            for (final section in const [
              AppSection.maitre,
              AppSection.lab,
              AppSection.chaudron,
              AppSection.projets,
            ])
              _ShortcutCard(section: section),
          ],
        ),
      ],
    );
  }
}

class _FlashQuiz extends ConsumerWidget {
  const _FlashQuiz({required this.date});

  final DateTime date;

  Future<void> _record(
    BuildContext context,
    WidgetRef ref,
    bool correct,
  ) async {
    try {
      final outcome = await ref
          .read(progressRepositoryProvider)
          .recordQuizAttempt(
            quizId: flashQuizId(date),
            score: correct ? 1 : 0,
            maxScore: 1,
            passed: correct,
            xp: flashQuizXp,
            onlyFirstAttempt: true,
          );
      if (outcome.xpEarned > 0 && context.mounted) {
        showDruideToast(context, '+${outcome.xpEarned} XP gagnés !');
      }
    } on Exception catch (error) {
      debugPrint('Enregistrement du quiz impossible : $error');
      if (context.mounted) {
        showDruideToast(
          context,
          'Votre résultat n\'a pas pu être enregistré.',
          kind: ToastKind.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attempted =
        ref.watch(quizAttemptedProvider(flashQuizId(date))).value ?? false;

    return QuizCard(
      question: flashQuestionFor(date),
      footnote: attempted
          ? 'Votre réponse du jour est enregistrée. Revenez demain !'
          : 'Une bonne réponse du premier coup rapporte $flashQuizXp XP.',
      onAnswered: (correct) => _record(context, ref, correct),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.progress, required this.next});

  final ProgressSnapshot progress;
  final NextLesson? next;

  @override
  Widget build(BuildContext context) {
    final techno = context.techno;
    final rank = progress.rank;

    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: BeveledRectangleBorder(
          borderRadius: bevel,
          side: BorderSide(color: techno.violet),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [techno.heroStart, techno.heroEnd],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const MaitreAndDroiid(width: 104, mood: MascotMood.joyeux),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenue à l\'Académie !',
                    style: context.text.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'La magie d\'Android, du premier sort au code expert !',
                    style: context.text.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  TechnoTag(label: rank.title, color: techno.emeraude),
                  const SizedBox(height: 8),
                  XpBar(
                    xp: progress.xp,
                    floor: rank.minXp,
                    ceiling: rank.next?.minXp ?? rank.minXp,
                  ),
                  const SizedBox(height: 8),
                  ArcaneButton(
                    label: next == null
                        ? 'Découvrir l\'Académie'
                        : 'Continuer : ${next!.lesson.title}',
                    icon: Icons.school_outlined,
                    onPressed: () => context.go(
                      next == null
                          ? AppSection.academie.path
                          : lessonPath(next!.moduleId, next!.lesson.id),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({required this.section});

  final AppSection section;

  @override
  Widget build(BuildContext context) {
    final techno = context.techno;

    return TechnoCard(
      onTap: () => context.go(section.path),
      child: Row(
        children: [
          Icon(section.icon, color: techno.cyan, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(section.label, style: context.text.titleSmall),
                Text(
                  section.description,
                  style: context.text.bodySmall!.copyWith(color: techno.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
