import 'package:druide_and_droiid/design_system/adaptive_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<double> firstItemWidth(WidgetTester tester, {int? maxColumns}) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 600,
          child: AdaptiveGrid(
            minItemWidth: 100,
            spacing: 0,
            maxColumns: maxColumns,
            children: const [
              SizedBox(key: Key('premier'), height: 10),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    ),
  );
  return tester.getSize(find.byKey(const Key('premier'))).width;
}

void main() {
  testWidgets('remplit la largeur avec autant de colonnes que possible', (
    tester,
  ) async {
    expect(await firstItemWidth(tester), 100);
  });

  testWidgets('maxColumns élargit les éléments au lieu de laisser du vide', (
    tester,
  ) async {
    expect(await firstItemWidth(tester, maxColumns: 2), 300);
  });
}
