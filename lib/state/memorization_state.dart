import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/element_data.dart';

enum MemorizationPhase { idle, practicing, complete }

enum AttemptResult { correct, wrong, ignored }

class MemorizationState extends ChangeNotifier {
  MemorizationState({required List<ElementData> elements, Random? random})
    : _allElements = List<ElementData>.unmodifiable(elements),
      _random = random ?? Random();

  final List<ElementData> _allElements;
  final Random _random;
  List<ElementData> _queue = const [];
  final Set<int> _completedNumbers = <int>{};
  int _currentIndex = 0;
  MemorizationPhase _phase = MemorizationPhase.idle;

  MemorizationPhase get phase => _phase;
  bool get isPracticing => _phase == MemorizationPhase.practicing;
  bool get isComplete => _phase == MemorizationPhase.complete;
  int get completedCount => _completedNumbers.length;
  int get totalCount => _queue.length;
  int get currentIndex => _currentIndex;
  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;
  ElementData? get currentElement =>
      isPracticing && _currentIndex < _queue.length
      ? _queue[_currentIndex]
      : null;
  List<ElementData> get queue => List.unmodifiable(_queue);

  void start() {
    _queue =
        _allElements
            .where((element) => element.period <= 6)
            .toList(growable: false)
          ..shuffle(_random);
    _completedNumbers.clear();
    _currentIndex = 0;
    _phase = MemorizationPhase.practicing;
    notifyListeners();
  }

  void restart() => start();

  void exit() {
    _phase = MemorizationPhase.idle;
    _queue = const [];
    _completedNumbers.clear();
    _currentIndex = 0;
    notifyListeners();
  }

  bool isHidden(ElementData element) {
    return isPracticing &&
        element.period <= 6 &&
        !_completedNumbers.contains(element.atomicNumber);
  }

  bool isCompleted(ElementData element) {
    return _completedNumbers.contains(element.atomicNumber);
  }

  AttemptResult submit(ElementData target) {
    final current = currentElement;
    if (current == null) return AttemptResult.ignored;
    if (target.atomicNumber != current.atomicNumber ||
        target.displayRow != current.displayRow ||
        target.displayColumn != current.displayColumn) {
      return AttemptResult.wrong;
    }

    _completedNumbers.add(current.atomicNumber);
    _currentIndex++;
    if (_currentIndex >= _queue.length) {
      _currentIndex = _queue.length;
      _phase = MemorizationPhase.complete;
    }
    notifyListeners();
    return AttemptResult.correct;
  }
}
