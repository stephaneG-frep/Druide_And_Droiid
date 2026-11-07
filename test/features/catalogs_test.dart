import 'package:druide_and_droiid/features/academie/domain/module_catalog.dart';
import 'package:druide_and_droiid/features/academie/presentation/academie_page.dart';
import 'package:druide_and_droiid/features/accueil/domain/flash_questions.dart';
import 'package:druide_and_droiid/features/progression/domain/progression.dart';
import 'package:druide_and_droiid/features/projets/domain/project_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Académie', () {
    test('contient les douze modules, numérotés dans l\'ordre', () {
      expect(academyModules.map((m) => m.number), [
        for (var i = 1; i <= 12; i++) i,
      ]);
    });

    test('les identifiants sont uniques et utilisables dans une URL', () {
      final ids = academyModules.map((m) => m.id).toSet();

      expect(ids.length, academyModules.length);
      expect(ids.every(RegExp(r'^[a-z0-9-]+$').hasMatch), isTrue);
    });

    test('moduleById retrouve un module ou renvoie null', () {
      expect(moduleById('kotlin')?.number, 2);
      expect(moduleById('inconnu'), isNull);
    });

    test('aucun module n\'a un programme vide', () {
      expect(academyModules.every((m) => m.topics.isNotEmpty), isTrue);
    });
  });

  test('l\'annonce des modules rédigés s\'accorde en nombre', () {
    expect(pendingMessage([]), contains('en cours de rédaction'));
    expect(pendingMessage([1]), contains('dans le module 1.'));
    expect(pendingMessage([1, 2]), contains('dans les modules 1 et 2.'));
    expect(pendingMessage([1, 2, 3]), contains('dans les modules 1, 2 et 3.'));
  });

  test('vingt projets répartis sur quatre niveaux', () {
    expect(projectTracks.length, 4);
    expect(projectTracks.every((track) => track.projects.length == 5), isTrue);
  });

  group('Grades', () {
    test('commencent à Apprenti et finissent à Grand Druide', () {
      expect(Rank.values.length, 8);
      expect(ProgressSnapshot.start.rank, Rank.apprenti);
      expect(Rank.grandDruide.next, isNull);
    });

    test('les seuils sont strictement croissants', () {
      for (final rank in Rank.values.skip(1)) {
        expect(rank.minXp, greaterThan(Rank.values[rank.index - 1].minXp));
      }
    });

    test('forXp respecte les bornes de chaque grade', () {
      expect(Rank.forXp(149), Rank.apprenti);
      expect(Rank.forXp(150), Rank.initie);
      expect(Rank.forXp(1000000), Rank.grandDruide);
    });
  });

  group('Questions flash', () {
    test('sont valides', () {
      for (final question in flashQuestions) {
        expect(
          question.answerIndex,
          inInclusiveRange(0, question.options.length - 1),
        );
        expect(question.explanation, isNotEmpty);
      }
    });

    test('restent stables sur une journée et changent le lendemain', () {
      final morning = DateTime(2026, 11, 4, 8);

      expect(
        flashQuestionFor(DateTime(2026, 11, 4, 23)),
        same(flashQuestionFor(morning)),
      );
      expect(
        flashQuestionFor(DateTime(2026, 11, 5)),
        isNot(same(flashQuestionFor(morning))),
      );
    });
  });
}
