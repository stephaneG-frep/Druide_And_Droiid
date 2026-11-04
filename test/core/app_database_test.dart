import 'package:drift/native.dart';
import 'package:druide_and_droiid/core/persistence/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('une clé absente renvoie null', () async {
    expect(await database.readMeta('absente'), isNull);
  });

  test('écrire deux fois une clé remplace sa valeur', () async {
    await database.writeMeta('clé', 'première');
    await database.writeMeta('clé', 'seconde');

    expect(await database.readMeta('clé'), 'seconde');
  });
}
