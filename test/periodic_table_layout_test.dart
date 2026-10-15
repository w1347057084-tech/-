import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:periodic_table_study/data/periodic_table_layout.dart';

void main() {
  test('layout creates non-overlapping cells for every display row', () {
    const size = Size(1800, 900);
    const gap = 5.0;
    final metrics = PeriodicTableLayout.metrics(size, gap: gap);
    final occupied = <Rect>[];

    for (final row in PeriodicTableLayout.displayRows) {
      for (var column = 1; column <= 18; column++) {
        final rect = PeriodicTableLayout.cellRect(
          available: size,
          row: row,
          column: column,
          gap: gap,
        );
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width + 0.001));
        expect(rect.bottom, lessThanOrEqualTo(size.height + 0.001));
        for (final other in occupied) {
          expect(rect.overlaps(other), isFalse);
        }
        occupied.add(rect);
      }
    }

    expect(metrics.cellWidth, greaterThan(0));
    expect(metrics.cellHeight, greaterThan(0));
    expect(occupied, hasLength(162));
  });

  test('coordinate validation catches collisions and invalid cells', () {
    expect(
      PeriodicTableLayout.hasCollision([
        (row: 1, column: 1),
        (row: 1, column: 1),
      ]),
      isTrue,
    );
    expect(PeriodicTableLayout.hasCollision([(row: 8, column: 1)]), isTrue);
    expect(
      PeriodicTableLayout.hasCollision([
        (row: 1, column: 1),
        (row: 9, column: 17),
      ]),
      isFalse,
    );
  });
}
