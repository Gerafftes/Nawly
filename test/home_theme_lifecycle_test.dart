import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nawly/data/activity_repository.dart';
import 'package:nawly/main.dart';
import 'package:nawly/models/activity_models.dart';
import 'package:nawly/models/user_profile_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Completer<Map<String, Object>> loaded;
  late SharedPreferencesStorePlatform previousStore;
  setUp(() {
    SharedPreferences.resetStatic();
    previousStore = SharedPreferencesStorePlatform.instance;
  });
  tearDown(() {
    SharedPreferencesStorePlatform.instance = previousStore;
    SharedPreferences.resetStatic();
  });

  Future<void> mount(WidgetTester tester) async {
    loaded = Completer<Map<String, Object>>();
    SharedPreferencesStorePlatform.instance = _DelayedPreferences(
      loaded.future,
    );
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          userProfile: UserProfileData(
            profile: UserProfileSummaryData(
              name: 'Test',
              nickname: 'Test',
              rating: 5,
              completedJobs: 0,
              skillInputHint: '',
              skills: <String>[],
            ),
            verificationStatuses: const {},
            payments: const UserPaymentsData(
              paymentMethods: [],
              payoutAccounts: [],
            ),
          ),
          activityRepository: const _EmptyActivities(),
        ),
      ),
    );
  }

  testWidgets('a delayed preference response is ignored after disposal', (
    tester,
  ) async {
    await mount(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    loaded.complete(<String, Object>{'flutter.theme_mode': 'dark'});
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final String? mode in <String?>['dark', null]) {
    testWidgets('a mounted home applies ${mode ?? 'auto'} theme', (
      tester,
    ) async {
      await mount(tester);
      loaded.complete(<String, Object>{'flutter.theme_mode': ?mode});
      await tester.pump();
      await tester.pump();
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
        mode == 'dark' ? const Color(0xFF020202) : const Color(0xFFE6E6E6),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}

class _EmptyActivities extends ActivityRepository {
  const _EmptyActivities();
  @override
  Future<List<ActivitySectionData>> loadSections() async => const [];
}

class _DelayedPreferences extends InMemorySharedPreferencesStore {
  _DelayedPreferences(this.loaded) : super.empty();
  final Future<Map<String, Object>> loaded;
  @override
  Future<Map<String, Object>> getAllWithParameters(
    GetAllParameters parameters,
  ) => loaded;
  @override
  Future<Map<String, Object>> getAll() => loaded;
}
