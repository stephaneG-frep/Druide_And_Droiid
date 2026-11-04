import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/shell/not_found_page.dart';
import '../../../app/theme/app_theme.dart';
import '../../../design_system/druide_toast.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';
import '../../progression/data/progress_repository.dart';
import '../data/course_repository.dart';
import '../domain/course.dart';
import '../domain/rewards.dart';
import 'quiz_runner.dart';

/// Évaluation d'un module, ouverte une fois toutes ses leçons terminées.
class EvaluationPage extends ConsumerWidget {
  const EvaluationPage({required this.moduleId, super.key});

  final String moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseProvider(moduleId));

    return switch (course.value) {
      CourseReady(:final course) => _EvaluationContent(course),
      CourseUnreadable() => const PageFrame(
        title: 'Évaluation',
        children: [
          ErrorNotice(message: 'Cette évaluation n\'a pas pu être chargée.'),
        ],
      ),
      CourseAbsent() => NotFoundPage(uri: GoRouterState.of(context).uri),
      null => const PageFrame(
        title: 'Évaluation',
        children: [Center(child: CircularProgressIndicator())],
      ),
    };
  }
}

class _EvaluationContent extends ConsumerWidget {
  const _EvaluationContent(this.course);

  final Course course;

  Future<void> _record(BuildContext context, WidgetRef ref, int score) async {
    final evaluation = course.evaluation;
    final maxScore = evaluation.questions.length;
    try {
      final outcome = await ref
          .read(progressRepositoryProvider)
          .recordQuizAttempt(
            quizId: evaluationQuizId(course.moduleId),
            score: score,
            maxScore: maxScore,
            passed: hasPassed(score, maxScore, evaluation.passPercent),
            xp: Rewards.evaluation,
          );
      if (outcome.xpEarned > 0 && context.mounted) {
        showDruideToast(context, '+${outcome.xpEarned} XP gagnés !');
      }
    } on Exception catch (error) {
      debugPrint('Enregistrement de l\'évaluation impossible : $error');
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
    final completed = ref.watch(completedLessonsProvider);
    final evaluation = course.evaluation;
    final remaining = course.lessons
        .where((lesson) => !(completed.value ?? const {}).contains(lesson.id))
        .length;

    return PageFrame(
      title: 'Évaluation',
      children: [
        Text('Évaluation du module', style: context.text.headlineSmall),
        if (completed.isLoading && !completed.hasValue)
          const Center(child: CircularProgressIndicator())
        else if (remaining > 0)
          PhaseNotice(
            message:
                'Terminez d\'abord les leçons de ce module : il en '
                'reste $remaining.',
          )
        else ...[
          Text(
            '${evaluation.questions.length} questions. Il faut '
            '${evaluation.passPercent} % pour réussir, et vous pouvez '
            'recommencer autant de fois que vous voulez. Cette évaluation '
            'interne n\'est pas une certification professionnelle.',
            style: context.text.bodyLarge,
          ),
          QuizRunner(
            questions: evaluation.questions,
            passPercent: evaluation.passPercent,
            onSubmitted: (score) => _record(context, ref, score),
          ),
        ],
      ],
    );
  }
}
