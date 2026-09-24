import 'package:flutter_test/flutter_test.dart';
import 'package:nawly/config/app_environment.dart';
import 'package:nawly/data/activity_demo_repository.dart';
import 'package:nawly/data/app_repositories.dart';
import 'package:nawly/data/job_map_region_repository.dart';
import 'package:nawly/data/jobs_find_repository.dart';
import 'package:nawly/data/user_profile_repository.dart';
import 'package:nawly/services/account_deletion_service.dart';

void main() {
  test('uses local demo data by default', () {
    final AppEnvironment environment = AppEnvironment.fromValues();

    expect(environment.dataSource, AppDataSource.demo);
    expect(environment.usesSupabase, isFalse);
  });

  test('demo mode keeps every repository on local fixtures', () {
    final AppRepositories repositories = AppRepositories.demo();

    expect(repositories.userProfile, isA<UserProfileDemoRepository>());
    expect(repositories.activities, isA<ActivityDemoRepository>());
    expect(repositories.jobs, isA<JobsFindDemoRepository>());
    expect(repositories.mapRegion, isA<JobMapRegionDemoRepository>());
    expect(repositories.accountDeletion, isA<DemoAccountDeletionService>());
  });

  test('accepts an HTTPS Supabase configuration', () {
    final AppEnvironment environment = AppEnvironment.fromValues(
      dataSource: 'supabase',
      supabaseUrl: 'https://example.supabase.co',
      supabasePublishableKey: 'test-publishable-key',
    );

    expect(environment.dataSource, AppDataSource.supabase);
    expect(environment.usesSupabase, isTrue);
  });

  test('accepts HTTP only for numeric loopback addresses', () {
    for (final String url in <String>[
      'http://127.0.0.1:54321',
      'http://127.24.0.1:54321',
      'HTTP://127.0.0.1:54321',
      'http://[::1]:54321',
    ]) {
      expect(
        AppEnvironment.fromValues(
          dataSource: 'supabase',
          supabaseUrl: url,
          supabasePublishableKey: 'test-publishable-key',
        ).usesSupabase,
        isTrue,
        reason: url,
      );
    }
  });

  test('rejects Supabase URLs without secure transport', () {
    for (final String url in <String>[
      'http://evil.example',
      'http://192.168.1.10:54321',
      'http://10.0.2.2:54321',
      'http://localhost:54321',
      'http://0.0.0.0:54321',
      'http://[::]:54321',
      'http://127.0.0.1.evil.example',
      'http://127.0.0.1@evil.example',
      'http://127.000.000.001:54321',
      'http://127.0.0.256:54321',
      'http://2130706433:54321',
      'http://[::ffff:127.0.0.1]:54321',
      'ftp://example.supabase.co',
      'ws://example.supabase.co',
    ]) {
      expect(
        () => AppEnvironment.fromValues(
          dataSource: 'supabase',
          supabaseUrl: url,
          supabasePublishableKey: 'test-publishable-key',
        ),
        throwsA(
          isA<FormatException>().having(
            (FormatException error) => error.message,
            'message',
            contains('HTTPS'),
          ),
        ),
        reason: url,
      );
    }
  });

  test('rejects an unknown data source', () {
    expect(
      () => AppEnvironment.fromValues(dataSource: 'firebase'),
      throwsFormatException,
    );
  });

  test('rejects incomplete Supabase configuration', () {
    expect(
      () => AppEnvironment.fromValues(dataSource: 'supabase'),
      throwsFormatException,
    );
    expect(
      () => AppEnvironment.fromValues(
        dataSource: 'supabase',
        supabaseUrl: 'http://127.0.0.1:54321',
      ),
      throwsFormatException,
    );
  });
}
