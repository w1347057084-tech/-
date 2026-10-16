import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:periodic_table_study/data/element_repository.dart';
import 'package:periodic_table_study/screens/periodic_table_screen.dart';
import 'package:periodic_table_study/theme/app_theme.dart';
import 'package:periodic_table_study/widgets/element_tile.dart';

void main() {
  late ElementRepository repository;

  setUpAll(() async {
    repository = ElementRepository(
      loader: () => File('assets/data/elements.json').readAsString(),
    );
    await repository.load();
  });

  testWidgets('screen renders all tiles plus period and group labels', (
    tester,
  ) async {
    await _pumpScreen(tester, repository);

    expect(find.byType(ElementTile), findsNWidgets(118));
    expect(find.byKey(const ValueKey('group-label-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('group-label-18')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('group-label-1')),
        matching: find.text('IA'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('group-label-18')),
        matching: find.text('VIIIA'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('group-label-8-10')), findsOneWidget);
    expect(find.byKey(const ValueKey('group-label-8')), findsNothing);
    expect(find.byKey(const ValueKey('group-label-9')), findsNothing);
    expect(find.byKey(const ValueKey('group-label-10')), findsNothing);
    expect(find.byKey(const ValueKey('period-label-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('period-label-7')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('series-axis-lanthanide')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('series-axis-actinide')), findsOneWidget);
    expect(find.text('Hydrogen'), findsNothing);

    final hydrogen = tester
        .widgetList<ElementTile>(find.byType(ElementTile))
        .firstWhere((tile) => tile.element.atomicNumber == 1);
    expect(
      find.descendant(
        of: find.byWidget(hydrogen),
        matching: find.text('1.008'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byWidget(hydrogen), matching: find.text('氢')),
      findsOneWidget,
    );
  });

  testWidgets('tapping an element opens matching details and closes', (
    tester,
  ) async {
    await _pumpScreen(tester, repository);

    await tester.tap(find.byType(ElementTile).first);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('基础属性'), findsOneWidget);
    expect(find.text('氢'), findsWidgets);
    expect(find.text('Hydrogen'), findsOneWidget);
    await tester.tap(find.byTooltip('关闭'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('基础属性'), findsNothing);
  });

  testWidgets('detail opens as a modal above the still-drawn table', (
    tester,
  ) async {
    await _pumpScreen(tester, repository);

    await tester.tap(find.byType(ElementTile).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // 非不透明路由：周期表仍在树里继续绘制，只是被半透明遮罩压暗。
    expect(find.byKey(const ValueKey('element-detail-1')), findsOneWidget);
    expect(find.byType(ElementTile), findsNWidgets(118));
    final route = ModalRoute.of(
      tester.element(find.byKey(const ValueKey('element-detail-1'))),
    );
    expect(route?.opaque, isFalse, reason: '浮层必须是非不透明路由，周期表才会继续绘制');
    expect(
      tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .any((box) => box.color.a > 0.5),
      isTrue,
      reason: '遮罩必须实际绘制，否则无法压暗背景的周期表',
    );

    // 点卡片外的遮罩即关闭。
    await tester.tapAt(const Offset(12, 12));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const ValueKey('element-detail-1')), findsNothing);
  });

  testWidgets('lanthanide marker opens all fifteen series elements', (
    tester,
  ) async {
    await _pumpScreen(tester, repository);

    await tester.tap(find.byKey(const ValueKey('series-container-lanthanide')));
    await tester.pump(const Duration(milliseconds: 550));

    expect(find.text('镧系元素'), findsOneWidget);
    expect(find.byType(ElementTile), findsNWidgets(133));
    for (var atomicNumber = 57; atomicNumber <= 71; atomicNumber++) {
      expect(
        find.byKey(ValueKey('series-element-$atomicNumber')),
        findsOneWidget,
      );
    }

    await tester.tap(find.byKey(const ValueKey('series-element-68')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('铒'), findsWidgets);
  });

  testWidgets('actinide marker opens all fifteen series elements', (
    tester,
  ) async {
    await _pumpScreen(tester, repository);

    await tester.tap(find.byKey(const ValueKey('series-container-actinide')));
    await tester.pump(const Duration(milliseconds: 550));

    expect(find.text('锕系元素'), findsOneWidget);
    expect(find.byType(ElementTile), findsNWidgets(133));
    for (var atomicNumber = 89; atomicNumber <= 103; atomicNumber++) {
      expect(
        find.byKey(ValueKey('series-element-$atomicNumber')),
        findsOneWidget,
      );
    }
  });

  testWidgets(
    'search matches Chinese symbol and atomic number then highlights',
    (tester) async {
      await _pumpScreen(tester, repository);

      final field = find.byKey(const ValueKey('element-search-field'));
      expect(field, findsOneWidget);

      await tester.enterText(field, ' 氧 ');
      await tester.pump();
      expect(find.byKey(const ValueKey('search-result-8')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('search-result-8')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      expect(find.byKey(const ValueKey('highlight-overlay-8')), findsOneWidget);

      await tester.enterText(field, 'o');
      await tester.pump();
      expect(find.byKey(const ValueKey('search-result-8')), findsOneWidget);

      await tester.enterText(field, '8');
      await tester.pump();
      expect(find.byKey(const ValueKey('search-result-8')), findsOneWidget);

      expect(find.byKey(const ValueKey('highlight-overlay-8')), findsOneWidget);
    },
  );

  testWidgets('search shows no-match text and locates f-block elements', (
    tester,
  ) async {
    await _pumpScreen(tester, repository);

    final field = find.byKey(const ValueKey('element-search-field'));
    await tester.enterText(field, '不存在');
    await tester.pump();
    expect(find.text('未找到匹配元素'), findsOneWidget);

    await tester.enterText(field, '铕');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('search-result-63')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byKey(const ValueKey('highlight-overlay-63')), findsOneWidget);
    final europium = repository.byAtomicNumber(63);
    expect(europium.displayRow, 9);
  });

  testWidgets('hint highlights the target without completing the answer', (
    tester,
  ) async {
    await _pumpScreen(tester, repository);
    await tester.tap(find.text('背诵模式'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const ValueKey('element-search-field')), findsNothing);
    expect(find.text('进度 0 / 86'), findsOneWidget);

    await tester.tap(find.text('提示'));
    await tester.pump(const Duration(milliseconds: 120));
    expect(_highlightOverlays(), findsOneWidget);
    var target = _highlightedTile(tester);
    expect(target.hidden, isTrue);
    expect(target.element.period, lessThanOrEqualTo(6));

    await tester.tap(find.text('提示'));
    await tester.pump(const Duration(milliseconds: 120));
    expect(_highlightOverlays(), findsOneWidget);
    expect(find.text('进度 0 / 86'), findsOneWidget);

    final francium = tester
        .widgetList<ElementTile>(find.byType(ElementTile))
        .firstWhere((tile) => tile.element.atomicNumber == 87);
    await tester.tap(find.byWidget(francium));
    await tester.pump(const Duration(milliseconds: 120));
    expect(_highlightOverlays(), findsNothing);
    expect(find.text('进度 0 / 86'), findsOneWidget);

    await tester.tap(find.text('提示'));
    await tester.pump(const Duration(milliseconds: 120));
    target = _highlightedTile(tester);
    await tester.tap(find.byWidget(target));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('进度 1 / 86'), findsOneWidget);
    expect(_highlightOverlays(), findsNothing);
  });

  testWidgets('mode switch fades out and in within one five hundred ms cycle', (
    tester,
  ) async {
    await _pumpScreen(tester, repository);

    await tester.tap(find.text('背诵模式'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 245));
    expect(find.text('待放置元素'), findsNothing);

    await tester.pump(const Duration(milliseconds: 20));
    expect(find.text('待放置元素'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('待放置元素'), findsOneWidget);
    expect(find.text('背诵模式'), findsNothing);
  });

  testWidgets('wrong memorization placement shows non-blocking feedback', (
    tester,
  ) async {
    await _pumpScreen(tester, repository);
    await tester.tap(find.text('背诵模式'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final francium = tester
        .widgetList<ElementTile>(find.byType(ElementTile))
        .firstWhere((tile) => tile.element.atomicNumber == 87);
    await tester.tap(find.byWidget(francium));
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('位置不对，请继续尝试'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('位置不对，请继续尝试'), findsNothing);
  });

  testWidgets('two-finger double tap returns from memorization to query mode', (
    tester,
  ) async {
    await _pumpScreen(tester, repository);
    await tester.tap(find.text('背诵模式'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('待放置元素'), findsOneWidget);

    for (var pair = 0; pair < 2; pair++) {
      final first = await tester.createGesture(pointer: 11 + pair * 2);
      final second = await tester.createGesture(pointer: 12 + pair * 2);
      await first.down(const Offset(650, 420));
      await second.down(const Offset(690, 420));
      await tester.pump(const Duration(milliseconds: 20));
      await first.up();
      await second.up();
      await tester.pump(const Duration(milliseconds: 110));
    }

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('待放置元素'), findsNothing);
    expect(find.text('元素周期表'), findsOneWidget);
  });

  testWidgets('compact landscape keeps search and hint controls usable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: PeriodicTableScreen(repository: repository),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(tester.takeException(), isNull);
    await tester.enterText(
      find.byKey(const ValueKey('element-search-field')),
      '氧',
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('search-result-8')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('背诵模式'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('提示'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Finder _highlightOverlays() {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> &&
        key.value.startsWith('highlight-overlay-');
  });
}

ElementTile _highlightedTile(WidgetTester tester) {
  final overlay = tester.widget<Widget>(_highlightOverlays());
  final key = overlay.key! as ValueKey<String>;
  final atomicNumber = int.parse(key.value.split('-').last);
  return tester
      .widgetList<ElementTile>(find.byType(ElementTile))
      .firstWhere((tile) => tile.element.atomicNumber == atomicNumber);
}

Future<void> _pumpScreen(
  WidgetTester tester,
  ElementRepository repository,
) async {
  await tester.binding.setSurfaceSize(const Size(1366, 768));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: PeriodicTableScreen(repository: repository),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}
