import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nawly/data/activity_repository.dart';
import 'package:nawly/main.dart';
import 'package:nawly/models/activity_models.dart';
import 'package:nawly/models/user_profile_models.dart';
import 'package:nawly/pages/tabs/activity_tab.dart';
import 'package:nawly/services/activity_toast_presenter.dart';
import 'package:nawly/services/activity_toast_reminder_store.dart';
import 'package:nawly/services/activity_toast_seen_store.dart';

final UserProfileData _testUserProfile = UserProfileData(
  profile: UserProfileSummaryData(
    name: 'Johann',
    nickname: 'Gerafftes',
    rating: 4.9,
    completedJobs: 5,
    skillInputHint: 'Nachhilfe',
    skills: <String>[],
  ),
  verificationStatuses: <UserVerificationEntry, UserVerificationStatus>{},
  payments: UserPaymentsData(
    paymentMethods: <UserPaymentMethodData>[],
    payoutAccounts: <UserPayoutAccountData>[],
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final bool disposeHome in <bool>[false, true]) {
    testWidgets(
      'late native show is removed after ${disposeHome ? 'dispose' : 'leaving Start'}',
      (tester) async {
        await _setPhoneSize(tester, const Size(402, 874));
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final presenter = _ControlledToastPresenter(delayFirstShow: true);
        await _mountControlledHome(tester, presenter);
        expect(presenter.showCount, 1);
        if (disposeHome) {
          await tester.pumpWidget(const SizedBox.shrink());
        } else {
          await tester.tap(find.text('Aktivität'));
          await tester.pump();
        }
        presenter.pendingShow.complete(true);
        await tester.pump();
        await tester.pump();
        expect(presenter.visible, isFalse);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  }

  testWidgets(
    'returning to Start while show is pending restores a current toast',
    (tester) async {
      await _setPhoneSize(tester, const Size(402, 874));
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final presenter = _ControlledToastPresenter(delayFirstShow: true);
      await _mountControlledHome(tester, presenter);
      await tester.tap(find.text('Aktivität'));
      await tester.pump();
      await tester.tap(find.text('Start'));
      await tester.pump();
      presenter.pendingShow.complete(true);
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(presenter.showCount, 2);
      expect(presenter.visible, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('a pending dismissal finishes before a new native show', (
    tester,
  ) async {
    await _setPhoneSize(tester, const Size(402, 874));
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final presenter = _ControlledToastPresenter(delayFirstDismiss: true);
    await _mountControlledHome(tester, presenter);
    await tester.tap(find.text('Aktivität'));
    await tester.pump();
    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump();
    expect(presenter.showCount, 1);
    presenter.pendingDismiss.complete(true);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(presenter.showCount, 2);
    expect(presenter.visible, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  test('mjn presenter requests a persistent native toast', () async {
    final TargetPlatform? previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final List<MethodCall> calls = <MethodCall>[];
    const MethodChannel channel = MethodChannel('mjn_liquid_ui/toasts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call);
          return true;
        });
    addTearDown(() {
      debugDefaultTargetPlatformOverride = previousPlatform;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    const MjnActivityToastPresenter presenter = MjnActivityToastPresenter();
    final bool didShow = await presenter.show(
      title: 'Gartenarbeit · In Arbeit',
      systemImage: 'alarm.fill',
      placementOffset: -128,
      onOpen: () {},
    );

    expect(didShow, isTrue);
    expect(calls, hasLength(1));
    expect(calls.single.method, 'show');
    expect(calls.single.arguments, isA<Map<Object?, Object?>>());
    final Map<Object?, Object?> arguments =
        calls.single.arguments as Map<Object?, Object?>;
    expect(arguments['duration'], isNull);
    expect(arguments['actionTitle'], 'Öffnen');

    await presenter.dismiss();
  });

  testWidgets('home requests one persistent plugin toast', (
    WidgetTester tester,
  ) async {
    await _setPhoneSize(tester, const Size(402, 874));
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final _FakeActivityToastPresenter presenter = _FakeActivityToastPresenter();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          userProfile: _testUserProfile,
          activityRepository: _FakeActivityRepository(_activitySections),
          activityToastPresenter: presenter,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(presenter.showCount, 1);
    expect(presenter.title, 'Gartenarbeit · In Arbeit');
    expect(presenter.systemImage, 'alarm.fill');
    expect(presenter.placementOffset, -93);

    const ActivityToastSeenStore seenStore = ActivityToastSeenStore();
    expect(await seenStore.loadSeenKeys(), isEmpty);

    await tester.pump(const Duration(seconds: 6));
    expect(presenter.showCount, 1);
    expect(presenter.dismissCount, 0);

    presenter.openCallback!.call();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(presenter.dismissCount, greaterThanOrEqualTo(1));
    expect(await seenStore.loadSeenKeys(), <String>{'garden:inProgress'});
    expect(find.text('Deine Aufträge'), findsOneWidget);
    expect(find.text('Gartenarbeit'), findsWidgets);
  });

  testWidgets('switching away from start dismisses the persistent toast', (
    WidgetTester tester,
  ) async {
    await _setPhoneSize(tester, const Size(402, 874));
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final _FakeActivityToastPresenter presenter = _FakeActivityToastPresenter();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          userProfile: _testUserProfile,
          activityRepository: _FakeActivityRepository(_activitySections),
          activityToastPresenter: presenter,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(presenter.showCount, 1);
    await tester.tap(find.text('Aktivität'));
    await tester.pump();

    expect(presenter.dismissCount, 1);
  });

  testWidgets('switching between non-start tabs does not dismiss twice', (
    WidgetTester tester,
  ) async {
    await _setPhoneSize(tester, const Size(402, 874));
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final _FakeActivityToastPresenter presenter = _FakeActivityToastPresenter();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          userProfile: _testUserProfile,
          activityRepository: _FakeActivityRepository(_activitySections),
          activityToastPresenter: presenter,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Aktivität'));
    await tester.pump();
    await tester.tap(find.text('Profil'));
    await tester.pump();

    expect(presenter.dismissCount, 1);
  });

  testWidgets('filter hides the toast until closing, then restores it', (
    WidgetTester tester,
  ) async {
    await _setPhoneSize(tester, const Size(402, 874));
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final List<String> events = <String>[];
    Completer<bool> sheetClosed = Completer<bool>();
    final _FakeActivityToastPresenter presenter = _FakeActivityToastPresenter(
      onDismiss: () => events.add('toastDismissed'),
    );
    final TargetPlatform? previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    const MethodChannel sheetChannel = MethodChannel('mjn_liquid_ui/sheets');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sheetChannel, (MethodCall call) async {
          if (call.method == 'showTemplateSheet') {
            events.add('sheetShown');
            return sheetClosed.future;
          }
          return false;
        });
    addTearDown(() {
      debugDefaultTargetPlatformOverride = previousPlatform;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(sheetChannel, null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          userProfile: _testUserProfile,
          activityRepository: _FakeActivityRepository(_activitySections),
          activityToastPresenter: presenter,
          activityToastReminderInterval: const Duration(seconds: 5),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(presenter.showCount, 1);
    for (final Duration openDuration in <Duration>[
      const Duration(seconds: 1),
      const Duration(seconds: 6),
    ]) {
      final int showsBeforeOpening = presenter.showCount;
      events.clear();
      sheetClosed = Completer<bool>();
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pump();

      expect(events, <String>['toastDismissed', 'sheetShown']);
      await tester.pump(openDuration);
      await tester.pump();
      expect(presenter.showCount, showsBeforeOpening);

      sheetClosed.complete(true);
      await tester.pump();
      await tester.pump();
      expect(presenter.showCount, showsBeforeOpening + 1);
      const ActivityToastSeenStore seenStore = ActivityToastSeenStore();
      expect(await seenStore.loadSeenKeys(), isEmpty);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 20));
    debugDefaultTargetPlatformOverride = previousPlatform;
  });

  testWidgets('temporary tab switch restores the toast on start', (
    WidgetTester tester,
  ) async {
    await _setPhoneSize(tester, const Size(402, 874));
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final _FakeActivityToastPresenter presenter = _FakeActivityToastPresenter();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          userProfile: _testUserProfile,
          activityRepository: _FakeActivityRepository(_activitySections),
          activityToastPresenter: presenter,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(presenter.showCount, 1);
    await tester.tap(find.text('Aktivität'));
    await tester.pump();
    expect(presenter.dismissCount, 1);

    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump();

    expect(presenter.showCount, 2);
  });

  testWidgets('unacknowledged toast returns after the reminder interval', (
    WidgetTester tester,
  ) async {
    await _setPhoneSize(tester, const Size(402, 874));
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final _FakeActivityToastPresenter presenter = _FakeActivityToastPresenter();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          userProfile: _testUserProfile,
          activityRepository: _FakeActivityRepository(_activitySections),
          activityToastPresenter: presenter,
          activityToastReminderInterval: const Duration(seconds: 2),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(presenter.showCount, 1);

    await tester.tap(find.text('Aktivität'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump();

    expect(presenter.showCount, 2);
  });

  testWidgets(
    'toast reminder returns when opening did not complete the action',
    (WidgetTester tester) async {
      await _setPhoneSize(tester, const Size(402, 874));
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final _FakeActivityToastPresenter presenter =
          _FakeActivityToastPresenter();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            userProfile: _testUserProfile,
            activityRepository: _FakeActivityRepository(_activitySections),
            activityToastPresenter: presenter,
            activityToastReminderInterval: const Duration(seconds: 2),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(presenter.showCount, 1);

      presenter.openCallback!.call();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text('Start'));
      await tester.pump();
      await tester.pump();

      expect(presenter.showCount, 2);
    },
  );

  testWidgets('legacy seen keys do not suppress an actionable toast', (
    WidgetTester tester,
  ) async {
    await _setPhoneSize(tester, const Size(402, 874));
    SharedPreferences.setMockInitialValues(<String, Object>{
      'nawly.active_activity_toast_seen_keys': <String>['garden:inProgress'],
    });
    final _FakeActivityToastPresenter presenter = _FakeActivityToastPresenter();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          userProfile: _testUserProfile,
          activityRepository: _FakeActivityRepository(_activitySections),
          activityToastPresenter: presenter,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(presenter.showCount, 1);
  });

  testWidgets('activity deep link retries and opens the matching sheet', (
    WidgetTester tester,
  ) async {
    await _setPhoneSize(tester, const Size(402, 874));
    final TargetPlatform? previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    int showAttempts = 0;
    Map<Object?, Object?>? shownArguments;
    const MethodChannel sheetChannel = MethodChannel('mjn_liquid_ui/sheets');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sheetChannel, (MethodCall call) async {
          if (call.method != 'showTemplateSheet') {
            return false;
          }
          showAttempts += 1;
          shownArguments = call.arguments as Map<Object?, Object?>;
          return showAttempts >= 3;
        });
    addTearDown(() {
      debugDefaultTargetPlatformOverride = previousPlatform;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(sheetChannel, null);
    });
    bool didHandleActivity = false;
    bool didDismissBeforeSheet = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ActivityTabContent(
              jobCardColor: const Color(0xFF0D0D0D),
              userProfile: _testUserProfile.profile,
              activityRepository: _FakeActivityRepository(_activitySections),
              initialActivityId: 'garden',
              onInitialActivityHandled: () => didHandleActivity = true,
              onBeforeSheetPresented: () async {
                didDismissBeforeSheet = true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(showAttempts, 3);
    expect(didHandleActivity, isTrue);
    expect(didDismissBeforeSheet, isTrue);
    final Map<Object?, Object?> content =
        shownArguments!['content'] as Map<Object?, Object?>;
    expect(content['title'], 'Gartenarbeit');
    expect(content['detents'], <Object?, Object?>{
      'initialHeight': 560.0,
      'allowsAutomaticExpansion': false,
    });

    debugDefaultTargetPlatformOverride = previousPlatform;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sheetChannel, null);
  });

  testWidgets('home dismisses the native toast when disposed', (
    WidgetTester tester,
  ) async {
    await _setPhoneSize(tester, const Size(402, 874));
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final _FakeActivityToastPresenter presenter = _FakeActivityToastPresenter();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          userProfile: _testUserProfile,
          activityRepository: _FakeActivityRepository(_activitySections),
          activityToastPresenter: presenter,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.pumpWidget(const SizedBox.shrink());
    expect(presenter.dismissCount, 1);
  });

  test('seen store persists a status-specific toast key', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const ActivityToastSeenStore store = ActivityToastSeenStore(
      preferenceKey: 'test_active_activity_toast_seen',
    );

    expect(await store.loadSeenKeys(), isEmpty);
    await store.markSeen('garden:inProgress');
    await store.markSeen('garden:inProgress');
    await store.markSeen('garden:completionReported');

    expect(await store.loadSeenKeys(), <String>{
      'garden:inProgress',
      'garden:completionReported',
    });
  });

  test('seen keys remain until the activity is completed', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const ActivityToastSeenStore store = ActivityToastSeenStore(
      preferenceKey: 'test_completed_activity_toast_seen',
    );

    await store.markSeen('garden:completionReported');
    expect(
      await store.loadSeenKeys(completedActivityIds: <String>{'other'}),
      <String>{'garden:completionReported'},
    );

    expect(
      await store.loadSeenKeys(completedActivityIds: <String>{'garden'}),
      isEmpty,
    );
    expect(await store.loadSeenKeys(), isEmpty);
  });

  test('reminder store persists and clears a toast timestamp', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const ActivityToastReminderStore store = ActivityToastReminderStore(
      preferencePrefix: 'test_activity_toast_reminder',
    );
    final DateTime timestamp = DateTime.utc(2026, 8, 27, 12);

    expect(await store.loadLastShownAt('garden:inProgress'), isNull);
    await store.markShown('garden:inProgress', at: timestamp);
    expect(await store.loadLastShownAt('garden:inProgress'), timestamp);

    await store.clear('garden:inProgress');
    expect(await store.loadLastShownAt('garden:inProgress'), isNull);
  });
}

class _FakeActivityToastPresenter extends ActivityToastPresenter {
  _FakeActivityToastPresenter({this.onDismiss});

  final VoidCallback? onDismiss;
  int showCount = 0;
  int dismissCount = 0;
  String? title;
  String? systemImage;
  double? placementOffset;
  VoidCallback? openCallback;

  @override
  Future<bool> show({
    required String title,
    required String systemImage,
    required double placementOffset,
    required VoidCallback onOpen,
  }) async {
    showCount += 1;
    this.title = title;
    this.systemImage = systemImage;
    this.placementOffset = placementOffset;
    openCallback = onOpen;
    return true;
  }

  @override
  Future<bool> dismiss() async {
    dismissCount += 1;
    onDismiss?.call();
    return true;
  }
}

Future<void> _setPhoneSize(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

final List<ActivitySectionData> _activitySections = <ActivitySectionData>[
  ActivitySectionData(
    type: ActivitySectionType.running,
    cards: <ActivityCardData>[
      _activity(
        id: 'confirmed-tutoring',
        title: 'Nachhilfe',
        sectionType: ActivitySectionType.running,
        chip: ActivityChip.serviceBooked,
        status: ActivityStatus.confirmed,
      ),
      _activity(
        id: 'garden',
        title: 'Gartenarbeit',
        sectionType: ActivitySectionType.running,
        chip: ActivityChip.serviceBookedWithYou,
        status: ActivityStatus.inProgress,
      ),
    ],
  ),
  ActivitySectionData(
    type: ActivitySectionType.created,
    cards: <ActivityCardData>[
      _activity(
        id: 'waiting-job',
        title: 'Umzugshilfe',
        sectionType: ActivitySectionType.created,
        chip: ActivityChip.jobCreated,
        status: ActivityStatus.helperNeeded,
      ),
    ],
  ),
  ActivitySectionData(
    type: ActivitySectionType.completedForOthers,
    cards: <ActivityCardData>[
      _activity(
        id: 'completed-other',
        title: 'Einkäufe tragen',
        sectionType: ActivitySectionType.completedForOthers,
        chip: ActivityChip.jobCompletedByYou,
        status: ActivityStatus.completed,
      ),
    ],
  ),
  ActivitySectionData(
    type: ActivitySectionType.completedForYou,
    cards: <ActivityCardData>[
      _activity(
        id: 'completed-you',
        title: 'Regal aufbauen',
        sectionType: ActivitySectionType.completedForYou,
        chip: ActivityChip.jobCreated,
        status: ActivityStatus.completed,
      ),
    ],
  ),
];

class _FakeActivityRepository extends ActivityRepository {
  const _FakeActivityRepository(this.sections);

  final List<ActivitySectionData> sections;

  @override
  Future<List<ActivitySectionData>> loadSections() async => sections;
}

ActivityCardData _activity({
  required String id,
  required String title,
  required ActivitySectionType sectionType,
  required ActivityChip chip,
  required ActivityStatus status,
}) {
  return ActivityCardData(
    id: id,
    sectionType: sectionType,
    title: title,
    chip: chip,
    scheduleText: 'Heute, 14:00',
    compensationText: '25 €',
    locationText: '1 km entfernt',
    description: 'Testbeschreibung',
    status: status,
    iconPath: 'assets/icons/briefcase.fill.svg',
  );
}

Future<void> _mountControlledHome(
  WidgetTester tester,
  ActivityToastPresenter presenter,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: HomeScreen(
        userProfile: _testUserProfile,
        activityRepository: _FakeActivityRepository(_activitySections),
        activityToastPresenter: presenter,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

class _ControlledToastPresenter extends ActivityToastPresenter {
  _ControlledToastPresenter({
    this.delayFirstShow = false,
    this.delayFirstDismiss = false,
  });
  final bool delayFirstShow;
  final bool delayFirstDismiss;
  final Completer<bool> pendingShow = Completer<bool>();
  final Completer<bool> pendingDismiss = Completer<bool>();
  int showCount = 0;
  int dismissCount = 0;
  bool visible = false;
  @override
  Future<bool> show({
    required String title,
    required String systemImage,
    required double placementOffset,
    required VoidCallback onOpen,
  }) async {
    showCount++;
    if (delayFirstShow && showCount == 1) await pendingShow.future;
    visible = true;
    return true;
  }

  @override
  Future<bool> dismiss() async {
    dismissCount++;
    if (delayFirstDismiss && dismissCount == 1) await pendingDismiss.future;
    visible = false;
    return true;
  }
}
