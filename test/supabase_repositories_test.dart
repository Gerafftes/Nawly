import 'package:flutter_test/flutter_test.dart';
import 'package:nawly/data/supabase_activity_repository.dart';
import 'package:nawly/data/supabase_data_gateway.dart';
import 'package:nawly/data/supabase_jobs_find_repository.dart';
import 'package:nawly/data/supabase_user_profile_repository.dart';
import 'package:nawly/models/activity_models.dart';

void main() {
  test('maps Supabase job rows to the existing job model', () async {
    final _FakeSupabaseGateway gateway = _FakeSupabaseGateway(
      jobs: <Map<String, Object?>>[
        <String, Object?>{
          'id': 'job-1',
          'title': 'Gassi gehen',
          'time_text': 'Heute, 14:00',
          'price_text': '10 €',
          'distance_text': '1,2km',
          'show_verified': true,
          'public_latitude': 52.4992,
          'public_longitude': 13.4076,
        },
      ],
    );

    final jobs = await SupabaseJobsFindRepository(gateway).loadJobs();

    expect(jobs, hasLength(1));
    expect(jobs.single.id, 'job-1');
    expect(jobs.single.price, '10 €');
    expect(jobs.single.showVerified, isTrue);
    expect(jobs.single.approximateLocation?.latitude, 52.4992);
    expect(jobs.single.approximateLocation?.longitude, 13.4076);
  });

  test('does not expose an incomplete public job location', () async {
    final _FakeSupabaseGateway gateway = _FakeSupabaseGateway(
      jobs: <Map<String, Object?>>[
        <String, Object?>{
          'id': 'job-1',
          'title': 'Gassi gehen',
          'time_text': 'Heute, 14:00',
          'price_text': '10 €',
          'distance_text': '1,2km',
          'show_verified': true,
          'public_latitude': 52.4992,
          'public_longitude': null,
        },
      ],
    );

    final jobs = await SupabaseJobsFindRepository(gateway).loadJobs();

    expect(jobs.single.approximateLocation, isNull);
  });

  test('requires authentication before loading private profile data', () {
    final _FakeSupabaseGateway gateway = _FakeSupabaseGateway();

    expect(
      SupabaseUserProfileRepository(gateway).loadProfile,
      throwsStateError,
    );
  });

  test('maps the Supabase profile row to the existing profile model', () async {
    final _FakeSupabaseGateway gateway = _FakeSupabaseGateway(
      authenticated: true,
      profile: <String, Object?>{
        'user_id': 'user-1',
        'name': 'Johann',
        'nickname': 'Gerafftes',
        'rating': 4.9,
        'completed_jobs': 5,
        'skill_input_hint': 'Nachhilfe',
        'skills': <Object?>['Garten...'],
        'verification': <String, Object?>{
          'name': 'unverified',
          'address': 'unverified',
          'idCard': 'unverified',
          'email': 'unverified',
          'phone': 'unverified',
          'twoFactor': 'unverified',
        },
        'payment_methods': <Object?>[
          <String, Object?>{'id': 'paypal', 'type': 'paypal'},
        ],
        'payout_accounts': <Object?>[],
      },
    );

    final profile = await SupabaseUserProfileRepository(gateway).loadProfile();

    expect(profile.profile.nickname, 'Gerafftes');
    expect(profile.profile.completedJobs, 5);
    expect(profile.payments.paymentMethods.single.id, 'paypal');
  });

  test('groups Supabase activity rows and ordered status history', () async {
    final _FakeSupabaseGateway gateway = _FakeSupabaseGateway(
      authenticated: true,
      activities: <Map<String, Object?>>[
        <String, Object?>{
          'id': 'activity-1',
          'owner_id': 'user-1',
          'section_type': 'running',
          'title': 'Gassi gehen',
          'chip': 'jobAccepted',
          'schedule_text': 'Heute, 14:00',
          'compensation_text': '15 €',
          'location_text': '1,2 km entfernt',
          'description': 'Eine Runde mit dem Hund.',
          'status': 'confirmed',
          'icon_path': 'assets/icons/briefcase.fill.svg',
          'contact': <String, Object?>{
            'name': 'Mara König',
            'nickname': 'MaraK',
            'role': 'Auftraggeberin',
            'summary': 'Verifiziert · ★ 4,9',
          },
          'shows_visibility_badge': false,
        },
      ],
      activityHistory: <Map<String, Object?>>[
        <String, Object?>{
          'activity_id': 'activity-1',
          'position': 0,
          'status': 'agreementPending',
          'timestamp_text': 'Heute, 09:12',
        },
      ],
    );

    final sections = await SupabaseActivityRepository(gateway).loadSections();

    expect(sections, hasLength(ActivitySectionType.values.length));
    final running = sections.singleWhere(
      (ActivitySectionData section) =>
          section.type == ActivitySectionType.running,
    );
    expect(running.cards, hasLength(1));
    expect(running.cards.single.status, ActivityStatus.confirmed);
    expect(
      running.cards.single.statusHistory.single.status,
      ActivityStatus.agreementPending,
    );
  });
}

class _FakeSupabaseGateway extends SupabaseDataGateway
    implements SupabasePrivateDataGateway {
  const _FakeSupabaseGateway({
    this.authenticated = false,
    this.jobs = const <Map<String, Object?>>[],
    this.profile,
    this.activities = const <Map<String, Object?>>[],
    this.activityHistory = const <Map<String, Object?>>[],
  });

  final bool authenticated;
  final List<Map<String, Object?>> jobs;
  final Map<String, Object?>? profile;
  final List<Map<String, Object?>> activities;
  final List<Map<String, Object?>> activityHistory;

  @override
  Future<List<Map<String, Object?>>> loadJobs() async => jobs;

  @override
  bool get isAuthenticated => authenticated;

  @override
  Future<Map<String, Object?>?> loadProfile() async => profile;

  @override
  Future<List<Map<String, Object?>>> loadActivities() async {
    return activities;
  }

  @override
  Future<List<Map<String, Object?>>> loadActivityStatusHistory(
    List<String> activityIds,
  ) async {
    return activityHistory;
  }
}
