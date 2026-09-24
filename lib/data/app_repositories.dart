import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/account_deletion_service.dart';
import 'activity_demo_repository.dart';
import 'activity_repository.dart';
import 'job_map_region_repository.dart';
import 'jobs_find_repository.dart';
import 'supabase_activity_repository.dart';
import 'supabase_data_gateway.dart';
import 'supabase_jobs_find_repository.dart';
import 'supabase_user_profile_repository.dart';
import 'user_profile_repository.dart';

class AppRepositories {
  const AppRepositories({
    required this.userProfile,
    required this.activities,
    required this.jobs,
    required this.mapRegion,
    required this.accountDeletion,
  });

  factory AppRepositories.demo() {
    return const AppRepositories(
      userProfile: UserProfileDemoRepository(),
      activities: ActivityDemoRepository(),
      jobs: JobsFindDemoRepository(),
      mapRegion: JobMapRegionDemoRepository(),
      accountDeletion: DemoAccountDeletionService(),
    );
  }

  factory AppRepositories.supabase(SupabaseClient client) {
    final SupabaseDataGateway publicGateway = SupabaseClientDataGateway(client);
    final SupabasePrivateDataGateway privateGateway =
        SupabaseClientPrivateDataGateway(client);
    return AppRepositories(
      userProfile: SupabaseUserProfileRepository(privateGateway),
      activities: SupabaseActivityRepository(privateGateway),
      jobs: SupabaseJobsFindRepository(publicGateway),
      mapRegion: const JobMapRegionDemoRepository(),
      accountDeletion: SupabaseAccountDeletionService(client),
    );
  }

  final UserProfileRepository userProfile;
  final ActivityRepository activities;
  final JobsFindRepository jobs;
  final JobMapRegionRepository mapRegion;
  final AccountDeletionService accountDeletion;
}
