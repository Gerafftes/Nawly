import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nawly/services/shake_detector.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  test(
    'listens once, detects alternating motion and cancels on dispose',
    () async {
      int listens = 0;
      int cancels = 0;
      int shakes = 0;
      final StreamController<AccelerometerEvent> events =
          StreamController<AccelerometerEvent>.broadcast(
            sync: true,
            onListen: () => listens++,
            onCancel: () => cancels++,
          );
      final ShakeDetector detector = ShakeDetector(
        events: events.stream,
        onShake: () => shakes++,
      );
      detector.startListening();
      detector.startListening();
      expect(listens, 1);
      void emit(double x, double y, double z) =>
          events.add(AccelerometerEvent(x, y, z, DateTime.now()));
      emit(0, 0, 0);
      emit(30, 0, 0);
      emit(30, 30, 0);
      emit(30, 30, 30);
      expect(shakes, 1);
      // The unchanged cooldown suppresses a second immediate shake.
      emit(0, 30, 30);
      emit(0, 0, 30);
      emit(0, 0, 0);
      expect(shakes, 1);
      await detector.dispose();
      await detector.dispose();
      detector.startListening();
      emit(30, 0, 0);
      expect(cancels, 1);
      expect(listens, 1);
      expect(shakes, 1);
      await events.close();
    },
  );

  test('disposing before start never subscribes', () async {
    final events = StreamController<AccelerometerEvent>.broadcast();
    final detector = ShakeDetector(events: events.stream, onShake: () {});
    await detector.dispose();
    detector.startListening();
    expect(events.hasListener, isFalse);
    await events.close();
  });
}
