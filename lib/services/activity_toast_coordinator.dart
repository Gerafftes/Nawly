import 'dart:async';
import '../models/active_activity.dart';
import '../models/activity_models.dart';
import 'activity_toast_presenter.dart';
import 'activity_toast_seen_store.dart';
import 'activity_toast_reminder_store.dart';

/// Owns toast eligibility, reminders and native operation ordering.
/// Geometry, Flutter frame scheduling and navigation belong to the caller.
class ActivityToastCoordinator {
  ActivityToastCoordinator({
    required this.presenter,
    required this.canShow,
    required this.placementOffset,
    required this.scheduleFrame,
    required this.onOpen,
    required this.reminderInterval,
    ActivityToastSeenStore seenStore = const ActivityToastSeenStore(),
    ActivityToastReminderStore reminderStore =
        const ActivityToastReminderStore(),
  }) : assert(reminderInterval > Duration.zero),
       _seenStore = seenStore,
       _reminderStore = reminderStore;

  final ActivityToastPresenter presenter;
  final bool Function() canShow;
  final double Function() placementOffset;
  final void Function(void Function()) scheduleFrame;
  final void Function(String activityId) onOpen;
  final Duration reminderInterval;
  final ActivityToastSeenStore _seenStore;
  final ActivityToastReminderStore _reminderStore;
  static const Duration _activityToastRetryDelay = Duration(milliseconds: 250);
  static const int _activityToastMaxAttempts = 4;
  bool _disposed = false;
  bool _hasLoadedSeenKeys = false;
  ActiveActivitySummary? _summary;
  final Set<String> _acknowledgedKeys = <String>{};
  final Set<String> _displayedKeys = <String>{};
  final Set<String> _scheduledKeys = <String>{};
  final Set<String> _reminderDueKeys = <String>{};
  // A navigation-only dismissal should make the current toast eligible again
  // as soon as the Start tab is visible.
  final Set<String> _showOnStartKeys = <String>{};
  Timer? _reminderTimer;
  String? _reminderTimerKey;
  String? _visibleKey;
  int _generation = 0;
  Future<bool>? _dismissal;

  Future<void> initialize(Future<List<ActivitySectionData>> activities) async {
    Set<String> completedIds = <String>{};
    try {
      final sections = await activities;
      if (_disposed) return;
      _summary = ActiveActivitySelector.select(sections);
      completedIds = sections
          .expand((section) => section.cards)
          .where((activity) => activity.status == ActivityStatus.completed)
          .map((activity) => activity.id)
          .toSet();
    } catch (_) {
      // Loading failure leaves existing acknowledgement keys untouched.
    }
    if (_disposed) return;
    try {
      final seenKeys = await _seenStore.loadSeenKeys(
        completedActivityIds: completedIds,
      );
      if (_disposed) return;
      _acknowledgedKeys.addAll(seenKeys);
    } catch (_) {
      // Local preference failures must not prevent showing an eligible toast.
    }
    if (_disposed) return;
    _hasLoadedSeenKeys = true;
    scheduleIfReady();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _reminderTimer?.cancel();
    _reminderTimer = null;
    unawaited(dismiss(restartReminder: false));
  }

  void scheduleIfReady() {
    final ActiveActivitySummary? summary = _summary;
    if (summary != null) {
      unawaited(_scheduleActiveActivityToast(summary));
    }
  }

  bool get _canShow => !_disposed && canShow();

  Future<void> _scheduleActiveActivityToast(
    ActiveActivitySummary summary,
  ) async {
    if (!_canShow ||
        !_hasLoadedSeenKeys ||
        _displayedKeys.contains(summary.toastKey) ||
        !_scheduledKeys.add(summary.toastKey)) {
      return;
    }

    if (!await _isActivityToastReminderDue(summary.toastKey)) {
      _scheduledKeys.remove(summary.toastKey);
      return;
    }

    if (!_canShow || _summary?.toastKey != summary.toastKey) {
      _scheduledKeys.remove(summary.toastKey);
      return;
    }

    scheduleFrame(() {
      unawaited(_showActiveActivityToast(summary));
    });
  }

  Future<bool> _isActivityToastReminderDue(String toastKey) async {
    if (_showOnStartKeys.remove(toastKey)) {
      _reminderDueKeys.remove(toastKey);
      return true;
    }

    if (_reminderDueKeys.remove(toastKey)) {
      await _releaseActivityToastAcknowledgement(toastKey);
      return true;
    }

    DateTime? lastShownAt;
    try {
      lastShownAt = await _reminderStore.loadLastShownAt(toastKey);
    } catch (_) {
      return true;
    }

    if (lastShownAt == null) {
      return true;
    }

    final Duration elapsed = DateTime.now().toUtc().difference(lastShownAt);
    if (elapsed >= reminderInterval) {
      await _releaseActivityToastAcknowledgement(toastKey);
      return true;
    }

    _scheduleActivityToastReminder(toastKey, reminderInterval - elapsed);
    return false;
  }

  void _scheduleActivityToastReminder(
    String toastKey,
    Duration delay, {
    bool restart = false,
  }) {
    if (_disposed) return;
    if (!restart &&
        _reminderTimerKey == toastKey &&
        _reminderTimer?.isActive == true) {
      return;
    }

    _reminderTimer?.cancel();
    _reminderTimerKey = toastKey;
    _reminderTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
      _reminderTimer = null;
      _reminderTimerKey = null;
      _reminderDueKeys.add(toastKey);
      final bool wasAcknowledged = _acknowledgedKeys.remove(toastKey);
      if (wasAcknowledged) {
        unawaited(_clearPersistedAcknowledgement(toastKey));
      }

      if (_disposed || _summary?.toastKey != toastKey) {
        return;
      }

      _displayedKeys.remove(toastKey);
      if (_canShow) {
        scheduleIfReady();
      }
    });
  }

  Future<void> _releaseActivityToastAcknowledgement(String toastKey) async {
    if (!_acknowledgedKeys.remove(toastKey)) {
      return;
    }

    await _clearPersistedAcknowledgement(toastKey);
  }

  Future<void> _clearPersistedAcknowledgement(String toastKey) async {
    try {
      await _seenStore.clear(toastKey);
    } catch (_) {
      // Reminder eligibility must not depend on persistence cleanup.
    }
  }

  Future<void> _showActiveActivityToast(ActiveActivitySummary summary) async {
    if (!_canShow ||
        _displayedKeys.contains(summary.toastKey) ||
        _summary?.toastKey != summary.toastKey) {
      _scheduledKeys.remove(summary.toastKey);
      return;
    }
    final int generation = _generation;
    final double offset = placementOffset();
    bool isCurrent() =>
        _canShow &&
        generation == _generation &&
        _summary?.toastKey == summary.toastKey;
    bool didShow = false;
    try {
      // A previous dismissal must finish before another presentation starts.
      await _dismissal;
      for (
        int attempt = 0;
        attempt < _activityToastMaxAttempts && isCurrent() && !didShow;
        attempt++
      ) {
        if (attempt > 0) await Future<void>.delayed(_activityToastRetryDelay);
        if (!isCurrent()) break;
        didShow = await presenter.show(
          title: '${summary.activity.title} · ${summary.activity.status.label}',
          systemImage: summary.activity.status.iconPath,
          placementOffset: offset,
          onOpen: () {
            if (isCurrent()) _openActivityFromToast(summary);
          },
        );
      }
      if (!didShow) return;
      if (!isCurrent()) {
        // Dismiss may have completed before a slow native show became visible.
        await _requestActivityToastDismissal();
        return;
      }
      try {
        await _reminderStore.markShown(summary.toastKey);
      } catch (_) {
        // Persistence failures must not block the toast.
      }
      if (!isCurrent()) {
        await _requestActivityToastDismissal();
        return;
      }
      _scheduleActivityToastReminder(
        summary.toastKey,
        reminderInterval,
        restart: true,
      );
      _visibleKey = summary.toastKey;
      _displayedKeys.add(summary.toastKey);
    } catch (_) {
      // Toast failures keep the start page usable.
    } finally {
      // Keep the key reserved until cleanup of an obsolete show has finished.
      _scheduledKeys.remove(summary.toastKey);
      if (_canShow && generation != _generation) {
        scheduleIfReady();
      }
    }
  }

  void _openActivityFromToast(ActiveActivitySummary summary) {
    _acknowledgedKeys.add(summary.toastKey);
    unawaited(_persistAcknowledgement(summary.toastKey));
    unawaited(_restartActivityToastReminder(summary.toastKey));
    unawaited(_dismissToastAndOpenActivity(summary.activity.id));
  }

  Future<void> _persistAcknowledgement(String toastKey) async {
    try {
      await _seenStore.markSeen(toastKey);
    } catch (_) {
      // The in-memory acknowledgement and activity navigation remain usable.
    }
  }

  Future<void> _restartActivityToastReminder(String toastKey) async {
    try {
      await _reminderStore.markShown(toastKey);
    } catch (_) {
      // Reminder persistence failures must not block the activity action.
    }
    _scheduleActivityToastReminder(toastKey, reminderInterval, restart: true);
  }

  Future<void> _dismissToastAndOpenActivity(String activityId) async {
    await dismiss(restartReminder: false);
    if (_disposed) {
      return;
    }
    onOpen(activityId);
  }

  Future<void> dismiss({
    bool restartReminder = true,
    bool resumeOnStart = false,
  }) async {
    _generation++;
    final String? toastKey =
        _visibleKey ?? (resumeOnStart ? _summary?.toastKey : null);
    _visibleKey = null;
    if (resumeOnStart &&
        toastKey != null &&
        !_acknowledgedKeys.contains(toastKey)) {
      _displayedKeys.remove(toastKey);
      _showOnStartKeys.add(toastKey);
    }
    // Start the native dismissal before persisting the reminder timestamp so
    // the visual response never waits for SharedPreferences.
    final Future<bool> dismissal = _requestActivityToastDismissal();
    if (restartReminder && toastKey != null) {
      await _restartActivityToastReminder(toastKey);
    }
    await dismissal;
  }

  Future<bool> _requestActivityToastDismissal() {
    final Future<bool>? existingDismissal = _dismissal;
    if (existingDismissal != null) {
      return existingDismissal;
    }

    final Future<bool> dismissal = Future<bool>.sync(
      presenter.dismiss,
    ).catchError((Object _) => false);
    late final Future<bool> trackedDismissal;
    trackedDismissal = dismissal.whenComplete(() {
      if (identical(_dismissal, trackedDismissal)) {
        _dismissal = null;
      }
    });
    _dismissal = trackedDismissal;
    return trackedDismissal;
  }
}
