import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

class ShakeDetector {
  static const double _shakeThreshold =
      20.0; // Increased threshold for less sensitivity
  static const int _shakeCountTimeReset = 1000; // Increased time window
  static const int _minTimeBetweenShakes = 2000; // Increased cooldown

  final Function() onShake;
  final double shakeThreshold;
  final int shakeCountTimeReset;
  final int minTimeBetweenShakes;
  final Stream<AccelerometerEvent>? _events;
  StreamSubscription<AccelerometerEvent>? _subscription;
  bool _disposed = false;

  DateTime? _lastShakeTime;
  DateTime? _lastUpdateTime;
  double _lastX = 0.0;
  double _lastY = 0.0;
  double _lastZ = 0.0;
  int _shakeCount = 0;
  String? _lastShakeDirection; // Track the last shake direction

  ShakeDetector({
    required this.onShake,
    this.shakeThreshold = _shakeThreshold,
    this.shakeCountTimeReset = _shakeCountTimeReset,
    this.minTimeBetweenShakes = _minTimeBetweenShakes,
    Stream<AccelerometerEvent>? events,
  }) : _events = events;

  void startListening() {
    if (_disposed || _subscription != null) return;
    _subscription = (_events ?? accelerometerEventStream()).listen(
      _processAccelerometerEvent,
    );
  }

  Future<void> dispose() async {
    _disposed = true;
    final StreamSubscription<AccelerometerEvent>? subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }

  void _processAccelerometerEvent(AccelerometerEvent event) {
    if (_disposed) return;
    final DateTime now = DateTime.now();
    final double x = event.x;
    final double y = event.y;
    final double z = event.z;

    if (_lastUpdateTime != null) {
      final int timeDiff = now.difference(_lastUpdateTime!).inMilliseconds;
      if (timeDiff > shakeCountTimeReset) {
        _shakeCount = 0;
        _lastShakeDirection = null;
      }

      final double speed =
          (x - _lastX).abs() + (y - _lastY).abs() + (z - _lastZ).abs();

      if (speed > shakeThreshold) {
        // Determine the primary direction of this shake
        final double deltaX = (x - _lastX).abs();
        final double deltaY = (y - _lastY).abs();
        final double deltaZ = (z - _lastZ).abs();

        String currentDirection;
        if (deltaX > deltaY && deltaX > deltaZ) {
          currentDirection = 'x';
        } else if (deltaY > deltaX && deltaY > deltaZ) {
          currentDirection = 'y';
        } else {
          currentDirection = 'z';
        }

        // Check if this is a different direction than the last shake
        if (_lastShakeDirection == null ||
            _lastShakeDirection != currentDirection) {
          _shakeCount++;
          _lastShakeDirection = currentDirection;

          if (_shakeCount >= 3) {
            if (_lastShakeTime == null ||
                now.difference(_lastShakeTime!).inMilliseconds >
                    minTimeBetweenShakes) {
              _lastShakeTime = now;
              onShake();
            }
            _shakeCount = 0;
            _lastShakeDirection = null;
          }
        }
      }
    }

    _lastUpdateTime = now;
    _lastX = x;
    _lastY = y;
    _lastZ = z;
  }
}
