import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nawly/data/activity_repository.dart';
import 'package:nawly/main.dart';
import 'package:nawly/models/activity_models.dart';
import 'package:nawly/models/user_profile_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  testWidgets('Start returns from notifications to the start tab', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    SharedPreferences.setMockInitialValues(<String, Object>{});
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          userProfile: _testUserProfile,
          activityRepository: const _EmptyActivityRepository(),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.notifications_none));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Notifications'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('notifications-start-tab-tap-target')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Notifications'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('notifications-start-tab-tap-target')),
      findsNothing,
    );
  });
}

class _EmptyActivityRepository extends ActivityRepository {
  const _EmptyActivityRepository();

  @override
  Future<List<ActivitySectionData>> loadSections() async =>
      <ActivitySectionData>[];
}
