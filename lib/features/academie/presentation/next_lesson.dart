import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../progression/data/progress_repository.dart';
import '../data/course_repository.dart';
import '../domain/course.dart';
import '../domain/module_catalog.dart';

class NextLesson {
  const NextLesson({required this.moduleId, required this.lesson});

  final String moduleId;
  final Lesson lesson;
}

/// Première leçon non terminée, dans l'ordre du programme.
final nextLessonProvider = FutureProvider<NextLesson?>((ref) async {
  final completed = await ref.watch(completedLessonsProvider.future);

  for (final module in academyModules) {
    final load = await ref.watch(courseProvider(module.id).future);
    for (final lesson in load.course?.lessons ?? const <Lesson>[]) {
      if (!completed.contains(lesson.id)) {
        return NextLesson(moduleId: module.id, lesson: lesson);
      }
    }
  }
  return null;
}, retry: (_, _) => null);
