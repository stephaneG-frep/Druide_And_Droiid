import 'package:druide_and_droiid/design_system/code_highlighter.dart';
import 'package:druide_and_droiid/features/academie/domain/course.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> question({
  List<Object?> options = const ['A', 'B'],
  List<Object?> answers = const [0],
}) => {
  'prompt': 'Question ?',
  'options': options,
  'answers': answers,
  'explanation': 'Parce que.',
};

Map<String, Object?> course({
  List<Object?>? blocks,
  List<Object?>? quiz,
  List<Object?>? exercises,
  int passPercent = 80,
}) => {
  'moduleId': 'kotlin',
  'lessons': [
    {
      'id': 'lecon',
      'title': 'Leçon',
      'minutes': 5,
      'blocks':
          blocks ??
          [
            {'type': 'paragraph', 'text': 'Texte'},
          ],
      'quiz': quiz ?? [question()],
      'exercises': exercises ?? [],
    },
  ],
  'evaluation': {
    'passPercent': passPercent,
    'questions': [question()],
  },
  'resources': [],
};

Matcher failsWith(String message) => throwsA(
  isA<FormatException>().having((e) => e.message, 'message', contains(message)),
);

void main() {
  group('lecture', () {
    test('un cours valide est lu', () {
      final parsed = Course.fromJson(course());

      expect(parsed.lessons.single.title, 'Leçon');
      expect(parsed.evaluation.passPercent, 80);
    });

    test('lit chaque type de bloc', () {
      final parsed = Course.fromJson(
        course(
          blocks: [
            {'type': 'heading', 'text': 'Titre'},
            {'type': 'paragraph', 'text': 'Texte'},
            {
              'type': 'list',
              'items': ['a'],
            },
            {'type': 'code', 'language': 'kotlin', 'code': 'val a = 1'},
            {'type': 'info', 'text': 'Info'},
            {'type': 'warning', 'text': 'Attention'},
            {'type': 'tip', 'text': 'Conseil'},
            {
              'type': 'layers',
              'title': 'Couches',
              'layers': [
                {'name': 'Haut', 'detail': 'Détail'},
              ],
            },
          ],
        ),
      );

      final blocks = parsed.lessons.single.blocks;
      expect(blocks.length, 8);
      expect((blocks[3] as CodeBlock).language, CodeLanguage.kotlin);
      expect((blocks[5] as CalloutBlock).kind, CalloutKind.warning);
    });
  });

  group('erreurs de contenu', () {
    test('indique le champ manquant et son emplacement', () {
      final broken = course()..remove('resources');

      expect(() => Course.fromJson(broken), failsWith('« resources »'));
    });

    test('situe une erreur dans une leçon', () {
      final broken = course(
        blocks: [
          {'type': 'hologramme', 'text': 'x'},
        ],
      );

      expect(() => Course.fromJson(broken), failsWith('lessons[0]'));
      expect(() => Course.fromJson(broken), failsWith('hologramme'));
    });

    test('refuse une leçon vide', () {
      expect(() => Course.fromJson(course(blocks: [])), failsWith('contenu'));
    });

    test('refuse un cours sans leçon', () {
      final broken = course()..['lessons'] = <Object?>[];

      expect(() => Course.fromJson(broken), failsWith('aucune leçon'));
    });

    test('refuse une bonne réponse hors des options', () {
      final broken = course(
        quiz: [
          question(answers: [5]),
        ],
      );

      expect(() => Course.fromJson(broken), failsWith('hors des options'));
    });

    test('refuse une question sans bonne réponse', () {
      final broken = course(quiz: [question(answers: [])]);

      expect(() => Course.fromJson(broken), failsWith('aucune bonne réponse'));
    });

    test('refuse un langage inconnu', () {
      final broken = course(
        blocks: [
          {'type': 'code', 'language': 'cobol', 'code': 'x'},
        ],
      );

      expect(() => Course.fromJson(broken), failsWith('cobol'));
    });

    test('refuse un exercice court sans réponse acceptée', () {
      final broken = course(
        exercises: [
          {
            'id': 'e',
            'kind': 'fill',
            'prompt': 'P',
            'solution': 'S',
            'accepted': [],
          },
        ],
      );

      expect(() => Course.fromJson(broken), failsWith('réponse acceptée'));
    });

    test('refuse un seuil de réussite invalide', () {
      expect(
        () => Course.fromJson(course(passPercent: 150)),
        failsWith('seuil'),
      );
    });

    test('refuse un texte vide', () {
      final broken = course(
        blocks: [
          {'type': 'paragraph', 'text': '   '},
        ],
      );

      expect(() => Course.fromJson(broken), failsWith('vide'));
    });
  });

  group('notation', () {
    const single = CourseQuestion(
      prompt: 'P',
      options: ['A', 'B', 'C'],
      answers: {1},
      explanation: 'E',
    );
    const multiple = CourseQuestion(
      prompt: 'P',
      options: ['A', 'B', 'C'],
      answers: {0, 2},
      explanation: 'E',
    );

    test('une question multiple exige toutes les bonnes réponses', () {
      expect(multiple.isCorrect({0, 2}), isTrue);
      expect(multiple.isCorrect({0}), isFalse);
      expect(multiple.isCorrect({0, 1, 2}), isFalse);
    });

    test(
      'compte les bonnes questions, et 0 pour une question sans réponse',
      () {
        expect(
          scoreOf(
            [single, multiple],
            {
              0: {1},
            },
          ),
          1,
        );
      },
    );

    test('le seuil de réussite est inclusif', () {
      expect(hasPassed(4, 5, 80), isTrue);
      expect(hasPassed(3, 5, 80), isFalse);
      expect(hasPassed(7, 10, 70), isTrue);
      expect(hasPassed(0, 0, 70), isFalse);
    });

    test('un calcul entier évite les erreurs d\'arrondi', () {
      // 0,7 × 3 vaut 2,1 : 2 / 3 ne doit pas passer, 3 / 3 si.
      expect(hasPassed(2, 3, 70), isFalse);
      expect(hasPassed(3, 3, 70), isTrue);
    });
  });

  test('une réponse courte ignore casse et espaces', () {
    const exercise = Exercise(
      id: 'e',
      kind: ExerciseKind.fill,
      prompt: 'P',
      solution: 'S',
      accepted: ['Android Runtime', 'ART'],
      solutionLanguage: null,
    );

    expect(exercise.accepts('  android   runtime '), isTrue);
    expect(exercise.accepts('art'), isTrue);
    expect(exercise.accepts('dalvik'), isFalse);
    expect(exercise.accepts(''), isFalse);
  });

  test('lessonAfter renvoie la suivante, puis null', () {
    final parsed = Course.fromJson(course());

    expect(parsed.lessonAfter('lecon'), isNull);
    expect(parsed.lessonAfter('inconnue'), isNull);
    expect(parsed.lessonById('lecon'), isNotNull);
    expect(parsed.lessonById('inconnue'), isNull);
  });
}
