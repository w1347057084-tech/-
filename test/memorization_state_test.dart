import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:periodic_table_study/data/element_repository.dart';
import 'package:periodic_table_study/models/element_data.dart';
import 'package:periodic_table_study/state/memorization_state.dart';

void main() {
  late List<ElementData> elements;

  setUpAll(() async {
    final repository = ElementRepository(
      loader: () => File('assets/data/elements.json').readAsString(),
    );
    await repository.load();
    elements = repository.elements;
  });

  test('queue contains every element in periods 1 through 6 exactly once', () {
    final state = MemorizationState(elements: elements, random: Random(7))
      ..start();
    final expected = elements
        .where((element) => element.period <= 6)
        .map((e) => e.atomicNumber);

    expect(state.totalCount, 86);
    expect(
      state.queue.map((element) => element.atomicNumber).toSet(),
      expected.toSet(),
    );
    expect(
      state.queue.map((element) => element.atomicNumber).toSet(),
      hasLength(86),
    );
  });

  test('period 7 stays visible while period 6 f block is hidden', () {
    final state = MemorizationState(elements: elements, random: Random(1))
      ..start();

    expect(
      state.isHidden(elements.firstWhere((e) => e.atomicNumber == 57)),
      isTrue,
    );
    expect(
      state.isHidden(elements.firstWhere((e) => e.atomicNumber == 68)),
      isTrue,
    );
    expect(
      state.isHidden(elements.firstWhere((e) => e.atomicNumber == 89)),
      isFalse,
    );
    expect(
      state.isHidden(elements.firstWhere((e) => e.atomicNumber == 118)),
      isFalse,
    );
  });

  test(
    'wrong taps do not change progress and correct taps restore content',
    () {
      final state = MemorizationState(elements: elements, random: Random(3))
        ..start();
      final target = state.currentElement!;
      final wrong = elements.firstWhere(
        (element) => element.atomicNumber != target.atomicNumber,
      );

      expect(state.submit(wrong), AttemptResult.wrong);
      expect(state.completedCount, 0);
      expect(state.isHidden(target), isTrue);

      expect(state.submit(target), AttemptResult.correct);
      expect(state.completedCount, 1);
      expect(state.isHidden(target), isFalse);
      expect(state.isCompleted(target), isTrue);
    },
  );

  test('restart clears progress and creates a fresh queue', () {
    final state = MemorizationState(elements: elements, random: Random(11))
      ..start();
    final target = state.currentElement!;
    state.submit(target);
    expect(state.completedCount, 1);

    state.restart();
    expect(state.completedCount, 0);
    expect(state.currentIndex, 0);
    expect(state.totalCount, 86);
  });

  test('exit restores all elements to normal visibility', () {
    final state = MemorizationState(elements: elements, random: Random(5))
      ..start();
    final lanthanum = elements.firstWhere(
      (element) => element.atomicNumber == 57,
    );
    expect(state.isHidden(lanthanum), isTrue);

    state.exit();
    expect(state.phase, MemorizationPhase.idle);
    expect(state.isHidden(lanthanum), isFalse);
  });
}
