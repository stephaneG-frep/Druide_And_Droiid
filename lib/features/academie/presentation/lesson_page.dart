import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/shell/not_found_page.dart';
import '../../../app/theme/app_theme.dart';
import '../../../design_system/arcane_button.dart';
import '../../../design_system/druide_toast.dart';
import '../../../design_system/page_frame.dart';
import '../../../design_system/techno_card.dart';
import '../../maitre/data/ai_settings_repository.dart';
import '../../maitre/domain/teaching.dart';
import '../../maitre/presentation/ai_actions.dart';
import '../../notes/presentation/notes_page.dart';
import '../../progression/data/progress_repository.dart';
import '../data/course_repository.dart';
import '../domain/course.dart';
import '../domain/rewards.dart';
import 'exercise_card.dart';
import 'lesson_blocks.dart';
import 'paths.dart';
import 'quiz_runner.dart';

/// Lecture d'une leçon : contenu, quiz, exercices, puis validation.
class LessonPage extends ConsumerWidget {
  const LessonPage({required this.moduleId, required this.lessonId, super.key});

  final String moduleId;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseProvider(moduleId));

    final uri = GoRouterState.of(context).uri;

    return switch (course.value) {
      CourseReady(:final course) => switch (course.lessonById(lessonId)) {
        final Lesson lesson => _LessonContent(course: course, lesson: lesson),
        null => NotFoundPage(uri: uri),
      },
      CourseUnreadable() => const PageFrame(
        title: 'Leçon',
        children: [
          ErrorNotice(message: 'Cette leçon n\'a pas pu être chargée.'),
        ],
      ),
      CourseAbsent() => NotFoundPage(uri: uri),
      null => const PageFrame(
        title: 'Leçon',
        children: [Center(child: CircularProgressIndicator())],
      ),
    };
  }
}

class _LessonContent extends ConsumerWidget {
  const _LessonContent({required this.course, required this.lesson});

  final Course course;
  final Lesson lesson;

  String get _moduleId => course.moduleId;

  Future<void> _recordQuiz(
    BuildContext context,
    WidgetRef ref,
    int score,
  ) async {
    final maxScore = lesson.quiz.length;
    try {
      final outcome = await ref
          .read(progressRepositoryProvider)
          .recordQuizAttempt(
            quizId: lessonQuizId(lesson.id),
            score: score,
            maxScore: maxScore,
            passed: hasPassed(score, maxScore, lessonQuizPassPercent),
            xp: Rewards.quiz,
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

  void _goNext(BuildContext context) {
    final next = course.lessonAfter(lesson.id);
    context.go(
      next == null ? modulePath(_moduleId) : lessonPath(_moduleId, next.id),
    );
  }

  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    try {
      final earned = await ref
          .read(progressRepositoryProvider)
          .completeLesson(
            lessonId: lesson.id,
            moduleId: _moduleId,
            xp: Rewards.lesson,
          );
      if (!context.mounted) return;
      if (earned > 0) showDruideToast(context, '+$earned XP gagnés !');
      _goNext(context);
    } on Exception catch (error) {
      debugPrint('Enregistrement de la leçon impossible : $error');
      if (context.mounted) {
        showDruideToast(
          context,
          'Votre progression n\'a pas pu être enregistrée.',
          kind: ToastKind.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final techno = context.techno;
    final completed = ref.watch(completedLessonsProvider).value ?? const {};
    final isCompleted = completed.contains(lesson.id);
    final position = course.lessons.indexOf(lesson) + 1;
    final hasNext = course.lessonAfter(lesson.id) != null;
    final hasTeacher = ref.watch(
      aiSettingsProvider.select(
        (settings) => settings.value?.activeConfig != null,
      ),
    );

    return PageFrame(
      // La clé évite de réutiliser les réponses d'une leçon dans la suivante.
      key: ValueKey(lesson.id),
      title: 'Leçon $position / ${course.lessons.length}',
      children: [
        Text(lesson.title, style: context.text.headlineSmall),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            TechnoTag(label: '${lesson.minutes} min', color: techno.cyan),
            if (isCompleted)
              TechnoTag(label: 'Terminée', color: techno.emeraude),
          ],
        ),
        for (final block in lesson.blocks) LessonBlockView(block),
        if (lesson.quiz.isNotEmpty) ...[
          const SectionTitle('Quiz'),
          QuizRunner(
            questions: lesson.quiz,
            passPercent: lessonQuizPassPercent,
            onSubmitted: (score) => _recordQuiz(context, ref, score),
          ),
        ],
        if (lesson.exercises.isNotEmpty) ...[
          const SectionTitle('Exercices'),
          for (final exercise in lesson.exercises)
            ExerciseCard(
              key: ValueKey(exercise.id),
              exercise: exercise,
              moduleId: _moduleId,
            ),
        ],
        if (hasTeacher)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Demander au Maître'),
              onPressed: () => openNewConversation(
                context,
                ref,
                TeachingMode.explain,
                question: 'Explique-moi la leçon « ${lesson.title} ».',
              ),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ArcaneButton(
              label: isCompleted
                  ? (hasNext ? 'Leçon suivante' : 'Retour au module')
                  : 'Terminer la leçon',
              icon: Icons.arrow_forward,
              onPressed: () =>
                  isCompleted ? _goNext(context) : _complete(context, ref),
            ),
            ArcaneButton(
              label: 'Ajouter une note',
              icon: Icons.edit_note,
              secondary: true,
              onPressed: () => context.push('$newNotePath?module=$_moduleId'),
            ),
          ],
        ),
      ],
    );
  }
}
