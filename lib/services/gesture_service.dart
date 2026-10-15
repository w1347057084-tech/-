import 'package:flutter/gestures.dart';

class GestureService {
  GestureService({
    this.pairWindow = const Duration(milliseconds: 140),
    this.doubleTapWindow = const Duration(milliseconds: 520),
    this.maximumTravel = 48,
  });

  final Duration pairWindow;
  final Duration doubleTapWindow;
  final double maximumTravel;

  final Map<int, _PointerSnapshot> _activePointers = {};
  Duration? _previousPairTime;
  Offset? _previousPairCenter;

  bool handlePointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = _PointerSnapshot(
      time: event.timeStamp,
      position: event.position,
    );
    if (_activePointers.length != 2) return false;

    final values = _activePointers.values.toList(growable: false);
    final elapsed = (values[0].time - values[1].time).abs();
    if (elapsed > pairWindow) {
      _resetPairCandidate();
      return false;
    }

    final center = Offset(
      (values[0].position.dx + values[1].position.dx) / 2,
      (values[0].position.dy + values[1].position.dy) / 2,
    );
    final time = values[0].time > values[1].time
        ? values[0].time
        : values[1].time;

    if (_previousPairTime != null &&
        time - _previousPairTime! <= doubleTapWindow &&
        (center - (_previousPairCenter ?? center)).distance <= maximumTravel) {
      _previousPairTime = null;
      _previousPairCenter = null;
      return true;
    }

    _previousPairTime = time;
    _previousPairCenter = center;
    return false;
  }

  void handlePointerUp(PointerEvent event) {
    _activePointers.remove(event.pointer);
  }

  void handlePointerCancel(PointerEvent event) {
    _activePointers.remove(event.pointer);
  }

  void reset() {
    _activePointers.clear();
    _resetPairCandidate();
  }

  void _resetPairCandidate() {
    _previousPairTime = null;
    _previousPairCenter = null;
  }
}

class _PointerSnapshot {
  const _PointerSnapshot({required this.time, required this.position});

  final Duration time;
  final Offset position;
}
