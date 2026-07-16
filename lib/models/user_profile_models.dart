enum UserVerificationEntry { name, address, idCard, email, phone, twoFactor }

enum UserVerificationStatus { unverified, pending, verified }

enum UserPaymentMethodType { paypal, applePay }

enum UserPayoutAccountType { paypal, visa, giftCard }

class UserProfileData {
  const UserProfileData({
    required this.profile,
    required this.verificationStatuses,
    required this.payments,
  });

  factory UserProfileData.fromJson(Map<String, Object?> json) {
    final Map<String, Object?> profileJson =
        json['profile'] as Map<String, Object?>;
    final Map<String, Object?> verificationJson =
        json['verification'] as Map<String, Object?>;
    final Map<String, Object?> paymentsJson =
        json['payments'] as Map<String, Object?>;

    return UserProfileData(
      profile: UserProfileSummaryData.fromJson(profileJson),
      verificationStatuses: {
        for (final UserVerificationEntry entry in UserVerificationEntry.values)
          entry: UserVerificationStatus.values.byName(
            verificationJson[entry.name] as String,
          ),
      },
      payments: UserPaymentsData.fromJson(paymentsJson),
    );
  }

  final UserProfileSummaryData profile;
  final Map<UserVerificationEntry, UserVerificationStatus> verificationStatuses;
  final UserPaymentsData payments;
}

class UserProfileSummaryData {
  const UserProfileSummaryData({
    required this.displayName,
    required this.avatarInitial,
    required this.rating,
    required this.completedJobs,
    required this.skillInputHint,
    required this.skills,
  });

  factory UserProfileSummaryData.fromJson(Map<String, Object?> json) {
    return UserProfileSummaryData(
      displayName: json['displayName'] as String,
      avatarInitial: json['avatarInitial'] as String,
      rating: (json['rating'] as num).toDouble(),
      completedJobs: json['completedJobs'] as int,
      skillInputHint: json['skillInputHint'] as String,
      skills: (json['skills'] as List<Object?>).cast<String>(),
    );
  }

  final String displayName;
  final String avatarInitial;
  final double rating;
  final int completedJobs;
  final String skillInputHint;
  final List<String> skills;

  String get formattedRating =>
      rating.toStringAsFixed(1).replaceFirst('.', ',');
}

class UserPaymentsData {
  const UserPaymentsData({
    required this.paymentMethods,
    required this.payoutAccounts,
  });

  factory UserPaymentsData.fromJson(Map<String, Object?> json) {
    return UserPaymentsData(
      paymentMethods: (json['paymentMethods'] as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(UserPaymentMethodData.fromJson)
          .toList(growable: false),
      payoutAccounts: (json['payoutAccounts'] as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(UserPayoutAccountData.fromJson)
          .toList(growable: false),
    );
  }

  final List<UserPaymentMethodData> paymentMethods;
  final List<UserPayoutAccountData> payoutAccounts;
}

class UserPaymentMethodData {
  const UserPaymentMethodData({required this.id, required this.type});

  factory UserPaymentMethodData.fromJson(Map<String, Object?> json) {
    return UserPaymentMethodData(
      id: json['id'] as String,
      type: UserPaymentMethodType.values.byName(json['type'] as String),
    );
  }

  final String id;
  final UserPaymentMethodType type;
}

class UserPayoutAccountData {
  const UserPayoutAccountData({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    required this.statusText,
    required this.feeLabel,
    required this.minLabel,
    required this.nextLabel,
    required this.minAmount,
    required this.brandLabel,
  });

  factory UserPayoutAccountData.fromJson(Map<String, Object?> json) {
    return UserPayoutAccountData(
      id: json['id'] as String,
      type: UserPayoutAccountType.values.byName(json['type'] as String),
      title: json['title'] as String,
      amount: json['amount'] as String,
      statusText: json['statusText'] as String,
      feeLabel: json['feeLabel'] as String,
      minLabel: json['minLabel'] as String,
      nextLabel: json['nextLabel'] as String,
      minAmount: json['minAmount'] as String,
      brandLabel: json['brandLabel'] as String,
    );
  }

  final String id;
  final UserPayoutAccountType type;
  final String title;
  final String amount;
  final String statusText;
  final String feeLabel;
  final String minLabel;
  final String nextLabel;
  final String minAmount;
  final String brandLabel;
}
