import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:periodic_table_study/services/gesture_service.dart';

void main() {
  test('single-finger double tap does not trigger', () {
    final service = GestureService();
    expect(
      service.handlePointerDown(_down(1, 0, const Offset(10, 10))),
      isFalse,
    );
    service.handlePointerUp(_up(1, 50));
    expect(
      service.handlePointerDown(_down(1, 100, const Offset(10, 10))),
      isFalse,
    );
    service.handlePointerUp(_up(1, 150));
  });

  test('two-finger double tap triggers once', () {
    final service = GestureService();
    expect(
      service.handlePointerDown(_down(1, 0, const Offset(20, 20))),
      isFalse,
    );
    expect(
      service.handlePointerDown(_down(2, 20, const Offset(60, 20))),
      isFalse,
    );
    service.handlePointerUp(_up(1, 60));
    service.handlePointerUp(_up(2, 60));

    expect(
      service.handlePointerDown(_down(1, 180, const Offset(22, 22))),
      isFalse,
    );
    expect(
      service.handlePointerDown(_down(2, 200, const Offset(62, 22))),
      isTrue,
    );
  });

  test('slow or far-apart pair does not trigger', () {
    final service = GestureService();
    service.handlePointerDown(_down(1, 0, const Offset(20, 20)));
    expect(
      service.handlePointerDown(_down(2, 200, const Offset(20, 20))),
      isFalse,
    );
    service.handlePointerUp(_up(1, 240));
    service.handlePointerUp(_up(2, 260));

    service.handlePointerDown(_down(1, 300, const Offset(100, 100)));
    expect(
      service.handlePointerDown(_down(2, 320, const Offset(100, 100))),
      isFalse,
    );
  });
}

PointerDownEvent _down(int pointer, int time, Offset offset) {
  return PointerDownEvent(
    pointer: pointer,
    timeStamp: Duration(milliseconds: time),
    position: offset,
  );
}

PointerUpEvent _up(int pointer, int time) {
  return PointerUpEvent(
    pointer: pointer,
    timeStamp: Duration(milliseconds: time),
  );
}
