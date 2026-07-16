import 'package:flutter_test/flutter_test.dart';
import 'package:nawly/data/user_profile_repository.dart';
import 'package:nawly/models/user_profile_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads all user-specific demo profile data from the asset', () async {
    final UserProfileData userProfile = await const UserProfileDemoRepository()
        .loadProfile();

    expect(userProfile.profile.displayName, 'Gerafftes');
    expect(userProfile.profile.formattedRating, '4,9');
    expect(userProfile.profile.completedJobs, 5);
    expect(userProfile.profile.skills, hasLength(3));
    expect(
      userProfile.verificationStatuses.values,
      everyElement(UserVerificationStatus.unverified),
    );
    expect(userProfile.payments.paymentMethods, hasLength(2));
    expect(userProfile.payments.payoutAccounts, hasLength(3));
    expect(
      userProfile.payments.payoutAccounts.first.title,
      'Johann Eugen Mün...',
    );
    expect(userProfile.payments.payoutAccounts[1].title, 'Visa •••• 4242');
  });
}
