import 'dart:convert';
import 'dart:io';

import 'package:druide_and_droiid/features/academie/domain/course.dart';
import 'package:druide_and_droiid/features/academie/domain/module_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _directory = 'assets/courses';

List<String> indexedModules() {
  final index = jsonDecode(File('$_directory/index.json').readAsStringSync());
  return ((index as Map<String, Object?>)['modules']! as List<Object?>)
      .cast<String>();
}

Course loadCourse(String moduleId) {
  final source = File('$_directory/$moduleId.json').readAsStringSync();
  return Course.fromJson(jsonDecode(source) as Map<String, Object?>);
}

void main() {
  test('l\'index et les fichiers de cours concordent', () {
    final files = {
      for (final entity in Directory(_directory).listSync())
        p.basenameWithoutExtension(entity.path),
    }..remove('index');

    expect(indexedModules().toSet(), files);
  });

  test('chaque cours indexé correspond à un module du programme', () {
    for (final moduleId in indexedModules()) {
      expect(moduleById(moduleId), isNotNull, reason: moduleId);
      expect(loadCourse(moduleId).moduleId, moduleId);
    }
  });

  test('les identifiants sont uniques dans toute l\'Académie', () {
    final ids = <String>[];
    for (final moduleId in indexedModules()) {
      for (final lesson in loadCourse(moduleId).lessons) {
        ids
          ..add(lesson.id)
          ..addAll(lesson.exercises.map((exercise) => exercise.id));
      }
    }

    expect(ids.toSet().length, ids.length);
  });

  test('chaque leçon est complète : durée, quiz et exercice', () {
    for (final moduleId in indexedModules()) {
      for (final lesson in loadCourse(moduleId).lessons) {
        expect(lesson.minutes, greaterThan(0), reason: lesson.id);
        expect(lesson.quiz, isNotEmpty, reason: lesson.id);
        expect(lesson.exercises, isNotEmpty, reason: lesson.id);
      }
    }
  });

  test('un exercice à réponse courte accepte sa solution', () {
    for (final moduleId in indexedModules()) {
      for (final lesson in loadCourse(moduleId).lessons) {
        for (final exercise in lesson.exercises) {
          for (final answer in exercise.accepted) {
            expect(exercise.accepts(answer), isTrue, reason: exercise.id);
          }
        }
      }
    }
  });

  test('l\'évaluation peut être réussie sans dépasser le maximum', () {
    for (final moduleId in indexedModules()) {
      final evaluation = loadCourse(moduleId).evaluation;
      final perfect = {
        for (final (index, question) in evaluation.questions.indexed)
          index: question.answers,
      };

      expect(
        scoreOf(evaluation.questions, perfect),
        evaluation.questions.length,
      );
    }
  });
}
