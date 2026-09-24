import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nawly/models/activity_models.dart';
import 'package:nawly/services/activity_toast_coordinator.dart';
import 'package:nawly/services/activity_toast_presenter.dart';
import 'package:nawly/services/activity_toast_reminder_store.dart';
import 'package:nawly/services/activity_toast_seen_store.dart';

void main() {
  ActivityToastCoordinator create(
    _Presenter presenter, {
    ActivityToastSeenStore? seen,
    ActivityToastReminderStore? reminders,
    void Function(String)? onOpen,
  }) => ActivityToastCoordinator(
    presenter: presenter,
    canShow: () => true,
    placementOffset: () => -93,
    scheduleFrame: (callback) => callback(),
    onOpen: onOpen ?? (_) {},
    reminderInterval: const Duration(hours: 2),
    seenStore: seen ?? _Seen(),
    reminderStore: reminders ?? _Reminders(),
  );

  testWidgets('the independent coordinator retries at most four times', (
    tester,
  ) async {
    final presenter = _Presenter(showResult: false);
    final coordinator = create(presenter);
    await coordinator.initialize(Future.value(_sections));
    await tester.pump();
    expect(presenter.shows, 1);
    for (int i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(presenter.shows, 4);
    await tester.pump(const Duration(seconds: 1));
    expect(presenter.shows, 4);
    coordinator.dispose();
    await tester.pump();
  });

  testWidgets('no toast appears when activity loading fails', (tester) async {
    final presenter = _Presenter();
    final coordinator = create(presenter);
    await coordinator.initialize(Future.error(StateError('unavailable')));
    await tester.pump();
    expect(presenter.shows, 0);
    coordinator.dispose();
    await tester.pump();
  });

  testWidgets('late persistence after disposal cannot restart the reminder', (
    tester,
  ) async {
    final gate = Completer<void>();
    final presenter = _Presenter();
    final coordinator = create(
      presenter,
      reminders: _Reminders(markGate: gate.future),
    );
    await coordinator.initialize(Future.value(_sections));
    await tester.pump();
    expect(presenter.shows, 1);
    coordinator.dispose();
    gate.complete();
    await tester.pump();
    await tester.pump(const Duration(hours: 3));
    expect(presenter.shows, 1);
    expect(presenter.visible, isFalse);
  });

  testWidgets(
    'preference and dismiss errors cannot block opening the activity',
    (tester) async {
      final opened = <String>[];
      final presenter = _Presenter(failDismiss: true);
      final coordinator = create(
        presenter,
        seen: _Seen(fail: true),
        reminders: _Reminders(fail: true),
        onOpen: opened.add,
      );
      await coordinator.initialize(Future.value(_sections));
      await tester.pump();
      expect(presenter.shows, 1);
      presenter.onOpen!();
      await tester.pump();
      expect(opened, <String>['activity-1']);
      coordinator.dispose();
      await tester.pump();
    },
  );
}

final _sections = <ActivitySectionData>[
  ActivitySectionData(
    type: ActivitySectionType.running,
    cards: <ActivityCardData>[
      ActivityCardData(
        id: 'activity-1',
        sectionType: ActivitySectionType.running,
        title: 'Test',
        chip: ActivityChip.jobAccepted,
        status: ActivityStatus.inProgress,
        scheduleText: 'Heute',
        compensationText: '25 €',
        locationText: '1 km',
        description: '',
        iconPath: 'briefcase.fill',
      ),
    ],
  ),
];

class _Presenter extends ActivityToastPresenter {
  _Presenter({this.showResult = true, this.failDismiss = false});
  final bool showResult;
  final bool failDismiss;
  int shows = 0;
  bool visible = false;
  VoidCallback? onOpen;
  @override
  Future<bool> show({
    required String title,
    required String systemImage,
    required double placementOffset,
    required VoidCallback onOpen,
  }) async {
    shows++;
    this.onOpen = onOpen;
    visible = showResult;
    return showResult;
  }

  @override
  Future<bool> dismiss() async {
    if (failDismiss) throw StateError('dismiss failed');
    visible = false;
    return true;
  }
}

class _Seen extends ActivityToastSeenStore {
  _Seen({this.fail = false});
  final bool fail;
  @override
  Future<Set<String>> loadSeenKeys({
    Iterable<String> completedActivityIds = const [],
  }) async {
    if (fail) throw StateError('read failed');
    return <String>{};
  }

  @override
  Future<void> markSeen(String key) async {
    if (fail) throw StateError('write failed');
  }
}

class _Reminders extends ActivityToastReminderStore {
  _Reminders({this.markGate, this.fail = false});
  final Future<void>? markGate;
  final bool fail;
  @override
  Future<DateTime?> loadLastShownAt(String toastKey) async {
    if (fail) throw StateError('read failed');
    return null;
  }

  @override
  Future<void> markShown(String toastKey, {DateTime? at}) async {
    if (fail) throw StateError('write failed');
    await markGate;
  }
}
