import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_environment.dart';
import 'data/app_repositories.dart';
import 'models/user_profile_models.dart';

/// Data loaded by the startup surface. Failures propagate to its retry state.
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
  // The SDK publishes its singleton before asynchronous auth initialization
  // finishes. A retry must dispose that partial instance rather than let the
  // SDK skip initialization. Startup serializes these calls before showing MyApp.
  Supabase? previous;
  try {
    previous = Supabase.instance;
  } on AssertionError {
    // The SDK has no initialized instance yet (its getter asserts in debug).
  }
  if (previous?.isInitialized ?? false) await previous!.dispose();
  final supabase = await Supabase.initialize(
    url: environment.supabaseUrl,
    publishableKey: environment.supabasePublishableKey,
    debug: false,
  );
  return AppRepositories.supabase(supabase.client);
}
