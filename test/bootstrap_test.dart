import 'package:flutter_test/flutter_test.dart';
import 'package:nawly/bootstrap.dart';
import 'package:nawly/config/app_environment.dart';
import 'package:nawly/data/app_repositories.dart';
import 'package:nawly/data/user_profile_repository.dart';
import 'package:nawly/models/user_profile_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'demo bootstrap loads the real bundled profile without Supabase',
    () async {
      final bootstrap = await loadAppBootstrap(
        environment: AppEnvironment.fromValues(),
        supabaseRepositories: (_) =>
            throw StateError('Unexpected Supabase setup'),
      );
      expect(bootstrap.userProfile.profile.nickname, 'Gerafftes');
      expect(
        bootstrap.repositories.userProfile,
        isA<UserProfileDemoRepository>(),
      );
    },
  );

  test(
    'Supabase selection initializes once and loads the chosen repository',
    () async {
      final AppEnvironment environment = AppEnvironment.fromValues(
        dataSource: 'supabase',
        supabaseUrl: 'https://test.invalid',
        supabasePublishableKey: 'test-key',
      );
      final AppRepositories repositories = AppRepositories.demo();
      int calls = 0;
      final bootstrap = await loadAppBootstrap(
        environment: environment,
        demoRepositories: () => throw StateError('Unexpected demo fallback'),
        supabaseRepositories: (received) async {
          expect(identical(received, environment), isTrue);
          calls++;
          return repositories;
        },
      );
      expect(calls, 1);
      expect(bootstrap.repositories, same(repositories));
      expect(bootstrap.userProfile.profile.nickname, 'Gerafftes');
    },
  );

  test('profile failure propagates without substituting demo data', () async {
    final defaults = AppRepositories.demo();
    final failure = StateError('Profile unavailable');
    final repositories = AppRepositories(
      userProfile: _FailingProfile(failure),
      activities: defaults.activities,
      jobs: defaults.jobs,
      mapRegion: defaults.mapRegion,
      accountDeletion: defaults.accountDeletion,
    );
    await expectLater(
      loadAppBootstrap(
        environment: AppEnvironment.fromValues(),
        demoRepositories: () => repositories,
      ),
      throwsA(same(failure)),
    );
  });

  test('initialization failure propagates before any profile load', () async {
    final failure = StateError('Initialization failed');
    await expectLater(
      loadAppBootstrap(
        environment: AppEnvironment.fromValues(
          dataSource: 'supabase',
          supabaseUrl: 'https://test.invalid',
          supabasePublishableKey: 'test-key',
        ),
        supabaseRepositories: (_) async => throw failure,
      ),
      throwsA(same(failure)),
    );
  });

  test(
    'retry replaces an SDK singleton left by failed auth initialization',
    () async {
      SharedPreferences.setMockInitialValues({});
      final environment = AppEnvironment.fromValues(
        dataSource: 'supabase',
        supabaseUrl: 'https://test.invalid',
        supabasePublishableKey: 'test-key',
      );
      await expectLater(
        Supabase.initialize(
          url: environment.supabaseUrl,
          publishableKey: environment.supabasePublishableKey,
          debug: false,
          authOptions: const FlutterAuthClientOptions(
            localStorage: _FailingStorage(),
            detectSessionInUri: false,
          ),
        ),
        throwsStateError,
      );
      final partialClient = Supabase.instance.client;
      try {
        // No session is seeded. A clean initialization must reach the private
        // profile's auth guard rather than reuse the broken auth instance.
        await expectLater(
          loadAppBootstrap(environment: environment),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('authentication is required'),
            ),
          ),
        );
        expect(Supabase.instance.client, isNot(same(partialClient)));
      } finally {
        await Supabase.instance.dispose();
      }
    },
  );
}

class _FailingStorage extends EmptyLocalStorage {
  const _FailingStorage();

  @override
  Future<void> initialize() async =>
      throw StateError('synthetic storage failure');
}

class _FailingProfile extends UserProfileRepository {
  const _FailingProfile(this.failure);
  final Object failure;
  @override
  Future<UserProfileData> loadProfile() async => throw failure;
}
