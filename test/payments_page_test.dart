import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nawly/data/user_profile_repository.dart';
import 'package:nawly/pages/profile_details/payments_page.dart';
import 'package:nawly/pages/profile_details/payout_processing_page.dart';

void main() {
  testWidgets(
    'manual payout keeps an aborted swipe on the page and completes once',
    (tester) async {
      tester.view.physicalSize = const Size(402, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final profile = await tester.runAsync(
        () => const UserProfileDemoRepository().loadProfile(),
      );
      await tester.pumpWidget(
        MaterialApp(home: PaymentsPage(userProfile: profile!, prewarm: true)),
      );
      await tester.pump();
      final addPayout = find.text('Jetzt Auszahlung hinzufügen');
      await tester.ensureVisible(addPayout);
      await tester.tap(addPayout);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Manuell').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('PayPal als Standart verwenden').last);
      await tester.pump();
      await tester.tap(find.text('Speichern').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final swipe = find
          .byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == 'Wischen zum Auszahlen',
          )
          .first;
      await tester.ensureVisible(swipe);
      await tester.pump();
      final rect = tester.getRect(swipe);
      final gesture = await tester.startGesture(
        Offset(rect.left + 20, rect.center.dy),
      );
      await gesture.moveBy(const Offset(20, 0));
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(PayoutProcessingPage), findsNothing);
      final finish = await tester.startGesture(
        Offset(rect.left + 20, rect.center.dy),
      );
      await finish.moveBy(const Offset(20, 0));
      await finish.moveBy(Offset(rect.width - 30, 0));
      await finish.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(PayoutProcessingPage), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    },
  );
}
