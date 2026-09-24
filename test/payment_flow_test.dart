import 'package:flutter_test/flutter_test.dart';
import 'package:nawly/models/payment_selection.dart';
import 'package:nawly/services/payout_completion_flow.dart';

void main() {
  test(
    'payment choices preserve independent account and preferences drafts',
    () {
      final selection = PaymentSelection();
      expect(selection.payoutIndex, 0);
      expect(selection.payoutSchedule, 0);
      expect(selection.standardPayoutIndex, isNull);
      final cancelled = selection.editPreferences()
        ..schedule = 1
        ..standardPayoutIndex = 2;
      expect(cancelled.schedule, 1);
      expect(selection.editPreferences().schedule, 0);
      final accepted = selection.editPreferences()
        ..schedule = 1
        ..standardPayoutIndex = 1;
      selection.applyPreferences(accepted);
      selection.payoutIndex = 2;
      selection.paymentMethodIndex = 0;
      expect(selection.payoutSchedule, 1);
      expect(selection.standardPayoutIndex, 1);
      expect(selection.paymentMethodIndex, 0);
      accepted.schedule = 0;
      expect(selection.payoutSchedule, 1);
    },
  );

  testWidgets('completion remains single flight and lasts one second', (
    tester,
  ) async {
    final flow = PayoutCompletionFlow();
    final results = <bool>[];
    flow.complete().then(results.add);
    expect(flow.isProcessing, isTrue);
    expect(await flow.complete(), isFalse);
    await tester.pump(const Duration(milliseconds: 999));
    expect(results, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(results, <bool>[true]);
    expect(flow.isProcessing, isFalse);
    flow.dispose();
  });

  testWidgets('dispose cancels pending completion without navigating', (
    tester,
  ) async {
    final flow = PayoutCompletionFlow();
    final completion = flow.complete();
    flow.dispose();
    flow.dispose();
    expect(await completion, isFalse);
    expect(await flow.complete(), isFalse);
    await tester.pump(const Duration(seconds: 2));
    expect(flow.isProcessing, isFalse);
  });
}
