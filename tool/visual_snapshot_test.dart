import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:periodic_table_study/data/element_repository.dart';
import 'package:periodic_table_study/models/element_data.dart';
import 'package:periodic_table_study/screens/periodic_table_screen.dart';
import 'package:periodic_table_study/theme/app_theme.dart';
import 'package:periodic_table_study/widgets/element_detail_panel.dart';
import 'package:periodic_table_study/widgets/series_panel.dart';

void main() {
  late ElementRepository repository;

  setUpAll(() async {
    repository = ElementRepository(
      loader: () => File('assets/data/elements.json').readAsString(),
    );
    await repository.load();
  });

  testWidgets('capture periodic table', (tester) async {
    await _pump(tester, home: PeriodicTableScreen(repository: repository));
    await _capture(tester, 'periodic-table.png');
  });

  testWidgets('capture compact detail panel', (tester) async {
    await _pump(
      tester,
      home: ElementDetailPanel(
        element: repository.byAtomicNumber(68),
        onClose: () {},
      ),
    );
    await _capture(tester, 'element-detail.png');
  });

  testWidgets('capture detail opened over the periodic table', (tester) async {
    await _pump(tester, home: PeriodicTableScreen(repository: repository));
    await tester.tap(find.byKey(const ValueKey('element-container-26')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await _capture(tester, 'detail-over-table.png');
  });

  testWidgets('capture lanthanide panel', (tester) async {
    final lanthanides = repository.elements
        .where((element) => element.category == ElementCategory.lanthanide)
        .toList(growable: false);
    await _pump(
      tester,
      home: SeriesPanel(
        category: ElementCategory.lanthanide,
        elements: lanthanides,
        onClose: () {},
      ),
    );
    await _capture(tester, 'lanthanide-panel.png');
  });
}

Future<void> _pump(WidgetTester tester, {required Widget home}) async {
  await tester.binding.setSurfaceSize(const Size(1366, 768));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  // 边界包在最外层，这样弹出的路由（OpenContainer 的 open 页面）
  // 也会被截进同一张图里。
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('snapshot-boundary'),
      child: MaterialApp(theme: AppTheme.dark, home: home),
    ),
  );
  await tester.pump(const Duration(milliseconds: 120));
}

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('snapshot-boundary')),
    );
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('build/visuals')..createSync(recursive: true);
    await File(
      '${directory.path}/$name',
    ).writeAsBytes(data!.buffer.asUint8List());
  });
}
