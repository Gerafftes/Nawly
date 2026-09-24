import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nawly/data/activity_repository.dart';
import 'package:nawly/main.dart';
import 'package:nawly/models/activity_models.dart';
import 'package:nawly/models/user_profile_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('unknown route can return to the home page', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MyApp(
        userProfile: _testUserProfile,
        activityRepository: const _EmptyActivityRepository(),
      ),
    );
    await tester.pump();

    final NavigatorState rootNavigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    rootNavigator.pushNamed('/missing-page');
    await tester.pumpAndSettle();

    expect(find.text('Seite nicht gefunden'), findsOneWidget);

    await tester.tap(find.text('Zur Startseite'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Seite nicht gefunden'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}

final UserProfileData _testUserProfile = UserProfileData(
  profile: UserProfileSummaryData(
    name: 'Test',
    nickname: 'Test',
    rating: 5,
    completedJobs: 0,
    skillInputHint: '',
    skills: <String>[],
  ),
  verificationStatuses: const {},
  payments: const UserPaymentsData(paymentMethods: [], payoutAccounts: []),
);

class _EmptyActivityRepository extends ActivityRepository {
  const _EmptyActivityRepository();

  @override
  Future<List<ActivitySectionData>> loadSections() async => const [];
}
