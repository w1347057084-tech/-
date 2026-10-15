import 'dart:ui';

class PeriodicTableLayout {
  const PeriodicTableLayout._();

  static const int columnCount = 18;
  static const int rowCount = 10;
  static const int mainTableRows = 7;
  static const int lanthanideRow = 9;
  static const int actinideRow = 10;

  static const Set<int> displayRows = <int>{1, 2, 3, 4, 5, 6, 7, 9, 10};

  static LayoutMetrics metrics(Size available, {double gap = 4}) {
    final safeWidth = available.width <= 0 ? 1.0 : available.width;
    final safeHeight = available.height <= 0 ? 1.0 : available.height;
    return LayoutMetrics(
      cellWidth: (safeWidth - gap * (columnCount - 1)) / columnCount,
      cellHeight: (safeHeight - gap * (rowCount - 1)) / rowCount,
      gap: gap,
    );
  }

  static Rect cellRect({
    required Size available,
    required int row,
    required int column,
    required double gap,
  }) {
    final metrics = PeriodicTableLayout.metrics(available, gap: gap);
    final left = (column - 1) * (metrics.cellWidth + gap);
    final top = (row - 1) * (metrics.cellHeight + gap);
    return Rect.fromLTWH(left, top, metrics.cellWidth, metrics.cellHeight);
  }

  static bool hasCollision(List<({int row, int column})> coordinates) {
    final seen = <String>{};
    for (final coordinate in coordinates) {
      if (!displayRows.contains(coordinate.row)) return true;
      if (coordinate.column < 1 || coordinate.column > columnCount) return true;
      if (!seen.add('${coordinate.row}:${coordinate.column}')) return true;
    }
    return false;
  }
}

class LayoutMetrics {
  const LayoutMetrics({
    required this.cellWidth,
    required this.cellHeight,
    required this.gap,
  });

  final double cellWidth;
  final double cellHeight;
  final double gap;
}
