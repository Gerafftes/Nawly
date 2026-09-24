import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_environment.dart';
import 'data/app_repositories.dart';
import 'models/user_profile_models.dart';

/// Data needed before the first application frame. Platform setup and runApp
/// stay in main; loading failures deliberately propagate to the caller.
class AppBootstrapData {
  const AppBootstrapData({
    required this.repositories,
    required this.userProfile,
  });

  final AppRepositories repositories;
  final UserProfileData userProfile;
}

Future<AppBootstrapData> loadAppBootstrap({
  required AppEnvironment environment,
  AppRepositories Function() demoRepositories = AppRepositories.demo,
  Future<AppRepositories> Function(AppEnvironment) supabaseRepositories =
      _initializeSupabaseRepositories,
}) async {
  final AppRepositories repositories = environment.usesSupabase
      ? await supabaseRepositories(environment)
      : demoRepositories();
  final UserProfileData userProfile = await repositories.userProfile
      .loadProfile();
  return AppBootstrapData(repositories: repositories, userProfile: userProfile);
}

Future<AppRepositories> _initializeSupabaseRepositories(
  AppEnvironment environment,
) async {
  await Supabase.initialize(
    url: environment.supabaseUrl,
    publishableKey: environment.supabasePublishableKey,
  );
  return AppRepositories.supabase(Supabase.instance.client);
}
