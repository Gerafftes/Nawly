import '../models/user_profile_models.dart';
import 'supabase_data_gateway.dart';
import 'user_profile_repository.dart';

class SupabaseUserProfileRepository extends UserProfileRepository {
  const SupabaseUserProfileRepository(this.gateway);

  final SupabasePrivateDataGateway gateway;

  @override
  Future<UserProfileData> loadProfile() async {
    _requireAuthenticatedUser(gateway.isAuthenticated);
    final Map<String, Object?>? row = await gateway.loadProfile();
    if (row == null) {
      throw StateError('No Supabase profile exists for the signed-in user.');
    }

    return UserProfileData.fromJson(<String, Object?>{
      'profile': <String, Object?>{
        'name': row['name'],
        'nickname': row['nickname'],
        'rating': row['rating'],
        'completedJobs': row['completed_jobs'],
        'skillInputHint': row['skill_input_hint'],
        'skills': List<Object?>.from(row['skills'] as List<Object?>),
      },
      'verification': Map<String, Object?>.from(
        row['verification'] as Map<String, Object?>,
      ),
      'payments': <String, Object?>{
        'paymentMethods': List<Object?>.from(
          row['payment_methods'] as List<Object?>,
        ),
        'payoutAccounts': List<Object?>.from(
          row['payout_accounts'] as List<Object?>,
        ),
      },
    });
  }
}

void _requireAuthenticatedUser(bool isAuthenticated) {
  if (!isAuthenticated) {
    throw StateError(
      'Supabase authentication is required for private Nawly data.',
    );
  }
}
