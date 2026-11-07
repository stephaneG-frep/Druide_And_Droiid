import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:druide_and_droiid/core/persistence/app_database.dart';
import 'package:druide_and_droiid/features/chaudron/data/bug_repository.dart';
import 'package:druide_and_droiid/features/chaudron/domain/bug_rule.dart';
import 'package:druide_and_droiid/features/chaudron/domain/log_tools.dart';
import 'package:flutter_test/flutter_test.dart';

List<BugRule> rules() => parseRules(
  jsonDecode(File('assets/bugs/rules.json').readAsStringSync())
      as Map<String, Object?>,
);

void main() {
  group('fiches', () {
    test('chaque famille du programme est couverte', () {
      final all = rules();
      for (final family in BugFamily.values) {
        expect(
          all.where((rule) => rule.family == family).length,
          greaterThanOrEqualTo(2),
          reason: family.name,
        );
      }
    });

    test('chaque fiche contient les six parties attendues', () {
      for (final rule in rules()) {
        expect(rule.summary, isNotEmpty, reason: rule.id);
        expect(rule.causes, isNotEmpty, reason: rule.id);
        expect(rule.checks, isNotEmpty, reason: rule.id);
        expect(rule.fixes, isNotEmpty, reason: rule.id);
        expect(rule.lesson, isNotEmpty, reason: rule.id);
        expect(rule.validation, isNotEmpty, reason: rule.id);
      }
    });

    test('aucune fiche ne se déclare résolue', () {
      for (final rule in rules()) {
        final text = jsonEncode([rule.summary, rule.fixes, rule.validation])
            .toLowerCase();
        expect(text, isNot(contains('résolu')), reason: rule.id);
      }
    });

    test('chaque message d\'exemple déclenche sa propre fiche', () {
      final all = rules();
      for (final rule in all) {
        expect(rule.samples, isNotEmpty, reason: rule.id);
        for (final sample in rule.samples) {
          expect(
            matchRules(all, sample).map((match) => match.id),
            contains(rule.id),
            reason: sample,
          );
        }
      }
    });

    test('un message ordinaire ne déclenche rien', () {
      const clean = '''
> Task :app:assembleDebug
BUILD SUCCESSFUL in 41s
I/flutter ( 1234): Bonjour
D/Activity: onResume
✓ Built build/app/outputs/flutter-apk/app-debug.apk
List of devices attached
AYGJVB6203002787	device
''';
      expect(matchRules(rules(), clean), isEmpty);
    });

    test('les messages réels relevés sur cette machine sont reconnus', () {
      final all = rules();
      List<String> idsOf(String text) =>
          matchRules(all, text).map((rule) => rule.id).toList();

      expect(idsOf("adb: device 'nope' not found"), contains('adb-no-device'));
      expect(
        idsOf(
          "Because a depends on retrofit_x_inexistant any which doesn't exist "
          '(could not find package retrofit_x_inexistant at https://pub.dev), '
          'version solving failed.',
        ),
        contains('deps-pub'),
      );
      expect(
        idsOf(
          "1.  Dependency ':flutter_local_notifications' requires core library "
          'desugaring to be enabled',
        ),
        contains('gradle-desugaring'),
      );
      expect(
        idsOf(
          "2.  Dependency ':permission_handler_android' requires libraries and "
          'applications that\n           depend on it to compile against '
          'version 37 or later of the',
        ),
        contains('gradle-compilesdk'),
      );
      expect(
        idsOf(
          'MissingPluginException(No implementation found for method write on '
          'channel plugins.it_nomads.com/flutter_secure_storage)',
        ),
        contains('flutter-plugin'),
      );
    });

    test('la première erreur du journal passe en tête', () {
      const log = '''
e: Main.kt:1 Unresolved reference 'Foo'.
Failure [INSTALL_FAILED_NO_MATCHING_ABIS]
''';
      expect(matchRules(rules(), log).first.id, 'kotlin-unresolved');

      const reversed = '''
Failure [INSTALL_FAILED_NO_MATCHING_ABIS]
e: Main.kt:1 Unresolved reference 'Foo'.
''';
      expect(matchRules(rules(), reversed).first.id, 'abi-nomatch');
    });
  });

  group('masquage', () {
    test('masque les clés et jetons courants', () {
      const key = 'sk-ant-api03-abcdefghijklmnopqrstuvwxyz';
      const google = 'AIzaSyA1234567890abcdefghijklmnop';
      const token = 'ghp_abcdefghijklmnopqrstuvwxyz123456';
      const jwt = 'eyJhbGciOiJIUzI1.eyJzdWIiOiIxMjM0.abcdefghijk';

      final result = redactSecrets('$key $google $token $jwt');

      for (final secret in [key, google, token, jwt]) {
        expect(result.text, isNot(contains(secret)));
      }
      expect(result.count, 4);
    });

    test('masque les en-têtes et les affectations', () {
      final result = redactSecrets('''
Authorization: Bearer abcdefgh12345678
storePassword=MonMotDePasse
api_key: "valeur-secrete"
''');
      expect(result.text, isNot(contains('abcdefgh12345678')));
      expect(result.text, isNot(contains('MonMotDePasse')));
      expect(result.text, isNot(contains('valeur-secrete')));
      expect(result.text, contains('storePassword=[masqué]'));
    });

    test('masque les courriels et le nom d\'utilisateur des chemins', () {
      final result = redactSecrets(
        'Erreur pour ana@exemple.fr dans /home/ana/projet/Main.kt',
      );
      expect(
        result.text,
        'Erreur pour [courriel] dans /home/[utilisateur]/projet/Main.kt',
      );
    });

    test('laisse intact un message ordinaire', () {
      const text = "Unresolved reference 'Foo' at Main.kt:12";
      final result = redactSecrets(text);
      expect(result.text, text);
      expect(result.count, 0);
    });
  });

  group('extraction', () {
    test('un journal court reste entier', () {
      expect(extractRelevant('ligne', maxChars: 100), 'ligne');
    });

    test('garde les erreurs et leur voisinage', () {
      final log = [
        ...List.filled(500, 'I/app: tout va bien'),
        'avant',
        'E/app: FATAL EXCEPTION: main',
        'Caused by: java.lang.IllegalStateException',
        'après',
        ...List.filled(500, 'I/app: encore bien'),
      ].join('\n');

      final result = extractRelevant(log, maxChars: 2000);

      expect(result, contains('avant'));
      expect(result, contains('FATAL EXCEPTION'));
      expect(result, contains('Caused by'));
      expect(result, isNot(contains('tout va bien\nI/app')));
      expect(result.length, lessThanOrEqualTo(2000));
    });

    test('sans erreur visible, garde la fin', () {
      final log = '${'a' * 500}FIN';
      final result = extractRelevant(log, maxChars: 10);
      expect(result, endsWith('FIN'));
      expect(result.length, 10);
    });

    test('la limite tient même avec beaucoup d\'erreurs', () {
      final log = List.filled(5000, 'Error: encore une panne').join('\n');
      expect(
        extractRelevant(log, maxChars: 1000).length,
        lessThanOrEqualTo(1000),
      );
    });
  });

  group('dossiers', () {
    late AppDatabase database;
    late BugRepository repository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repository = BugRepository(database, DateTime.now);
    });

    tearDown(() => database.close());

    test('un nouveau dossier reste non vérifié', () async {
      final id = await repository.create(
        errorText: 'Une erreur\nsuite',
        description: '',
        code: '',
      );
      final row = await repository.watch(id).first;

      expect(row!.title, 'Une erreur');
      expect(BugStatus.byName(row.status), BugStatus.open);
    });

    test('une réussite exige un résultat de vérification', () async {
      final id = await repository.create(
        errorText: 'x',
        description: '',
        code: '',
      );

      await expectLater(
        repository.recordVerification(id, BugStatus.verified, '   '),
        throwsArgumentError,
      );
      await repository.recordVerification(
        id,
        BugStatus.verified,
        'adb logcat -b crash -d : vide',
      );

      final row = await repository.watch(id).first;
      expect(BugStatus.byName(row!.status), BugStatus.verified);
      expect(row.verification, 'adb logcat -b crash -d : vide');
    });

    test('un échec se note sans résultat détaillé', () async {
      final id = await repository.create(
        errorText: 'x',
        description: '',
        code: '',
      );
      await repository.recordVerification(id, BugStatus.stillBroken, '');

      final row = await repository.watch(id).first;
      expect(BugStatus.byName(row!.status), BugStatus.stillBroken);
    });

    test('supprimer efface le dossier', () async {
      final id = await repository.create(
        errorText: 'x',
        description: '',
        code: '',
      );
      await repository.delete(id);
      expect(await repository.watch(id).first, isNull);
    });
  });
}
