import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nawly/models/user_profile_models.dart';
import 'package:nawly/pages/profile_details/general_page.dart';

void main() {
  Future<void> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: GeneralPage(
          prewarm: true,
          userProfile: UserProfileData(
            profile: UserProfileSummaryData(
              name: 'Johann',
              nickname: 'Alt',
              rating: 5,
              completedJobs: 0,
              skillInputHint: 'Nachhilfe',
              skills: <String>[],
            ),
            verificationStatuses: const {},
            payments: const UserPaymentsData(
              paymentMethods: [],
              payoutAccounts: [],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Flutter nickname editor saves, cancels and rejects empty input',
    (tester) async {
      await mount(tester);
      Future<void> open() async {
        await tester.tap(find.text('Bearbeiten').first);
        await tester.pumpAndSettle();
        await tester.pump();
        await tester.pumpAndSettle();
      }

      Finder field() => find.byType(TextFormField).first;
      await open();
      await tester.ensureVisible(find.byType(EditableText).first);
      await tester.enterText(field(), '  Neu  ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Neu').hitTestable(), findsOneWidget);
      await open();
      expect(tester.widget<TextFormField>(field()).controller!.text, 'Neu');
      await tester.enterText(field(), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Nickname darf nicht leer sein'), findsOneWidget);
      await tester.enterText(field(), 'Verwerfen');
      // System back cancels this local draft.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await open();
      expect(tester.widget<TextFormField>(field()).controller!.text, 'Neu');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('skills editor saves, cancels and validates its own draft', (
    tester,
  ) async {
    await mount(tester);
    Future<void> open(Finder action) async {
      await tester.tap(action);
      await tester.pumpAndSettle();
      await tester.pump();
      await tester.pumpAndSettle();
    }

    Finder field() => find.byType(TextFormField).first;
    await open(find.text('Hinzufügen').first);
    await tester.ensureVisible(find.byType(EditableText).first);
    await tester.enterText(field(), 'abc');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
      find.text('Skills müssen mindestens 4 Zeichen lang sein'),
      findsOneWidget,
    );
    await tester.enterText(field(), '  Kochen  ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Kochen').hitTestable(), findsOneWidget);
    expect(find.text('Alt').hitTestable(), findsOneWidget);
    await open(find.text('Bearbeiten').last);
    expect(tester.widget<TextFormField>(field()).controller!.text, 'Kochen');
    await tester.enterText(field(), 'Malen');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await open(find.text('Bearbeiten').last);
    expect(tester.widget<TextFormField>(field()).controller!.text, 'Kochen');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
