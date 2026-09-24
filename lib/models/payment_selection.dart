/// Local demo choices. Closing the preferences sheet discards its draft.
class PaymentSelection {
  int payoutIndex = 0;
  int payoutSchedule = 0;
  int? standardPayoutIndex;
  int? paymentMethodIndex;

  PayoutPreferencesDraft editPreferences() => PayoutPreferencesDraft(
    schedule: payoutSchedule,
    standardPayoutIndex: standardPayoutIndex,
  );

  void applyPreferences(PayoutPreferencesDraft draft) {
    payoutSchedule = draft.schedule;
    standardPayoutIndex = draft.standardPayoutIndex;
  }
}

class PayoutPreferencesDraft {
  PayoutPreferencesDraft({
    required this.schedule,
    required this.standardPayoutIndex,
  });
  int schedule;
  int? standardPayoutIndex;
}
