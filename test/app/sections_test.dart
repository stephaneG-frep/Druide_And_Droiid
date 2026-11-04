import 'package:druide_and_droiid/app/router.dart';
import 'package:druide_and_droiid/app/sections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chaque rubrique est atteignable depuis un seul menu', () {
    expect({
      ...AppSection.primary,
      ...AppSection.secondary,
    }, AppSection.values.toSet());
    expect(
      AppSection.primary.length + AppSection.secondary.length,
      AppSection.values.length,
    );
  });

  test('les chemins sont uniques', () {
    final paths = AppSection.values.map((section) => section.path).toSet();
    expect(paths.length, AppSection.values.length);
  });

  test('les rubriques secondaires vivent sous /plus', () {
    for (final section in AppSection.secondary) {
      expect(section.path, startsWith('$plusPath/'));
    }
  });
}
