import 'dart:async';

/// Owns the demo completion delay; gestures, haptics and navigation stay in UI.
class PayoutCompletionFlow {
  Timer? _timer;
  Completer<bool>? _pending;
  bool _disposed = false;

  bool get isProcessing => _pending != null;

  Future<bool> complete() {
    if (_disposed || isProcessing) return Future<bool>.value(false);
    final Completer<bool> pending = Completer<bool>();
    _pending = pending;
    _timer = Timer(const Duration(seconds: 1), () {
      _timer = null;
      _pending = null;
      pending.complete(true);
    });
    return pending.future;
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _pending?.complete(false);
    _pending = null;
  }
}
