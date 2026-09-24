import 'package:flutter_test/flutter_test.dart';
import 'package:nawly/data/activity_demo_repository.dart';
import 'package:nawly/models/activity_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('activity sections expose only their fixed status sets', () {
    expect(ActivitySectionType.running.allowedStatuses, const <ActivityStatus>{
      ActivityStatus.agreementPending,
      ActivityStatus.confirmed,
      ActivityStatus.inProgress,
      ActivityStatus.completionReported,
    });
    expect(ActivitySectionType.created.allowedStatuses, const <ActivityStatus>{
      ActivityStatus.helperNeeded,
      ActivityStatus.inProgress,
      ActivityStatus.completionConfirmation,
    });
    expect(
      ActivitySectionType.completedForOthers.allowedStatuses,
      const <ActivityStatus>{ActivityStatus.completed},
    );
    expect(
      ActivitySectionType.completedForYou.allowedStatuses,
      const <ActivityStatus>{ActivityStatus.completed},
    );
  });

  test('demo activities cover every allowed visible status', () async {
    final List<ActivitySectionData> sections =
        await const ActivityDemoRepository().loadSections();
    final Map<ActivitySectionType, ActivitySectionData> sectionsByType =
        <ActivitySectionType, ActivitySectionData>{
          for (final ActivitySectionData section in sections)
            section.type: section,
        };

    expect(sectionsByType.keys, containsAll(ActivitySectionType.values));
    for (final ActivitySectionType type in ActivitySectionType.values) {
      final ActivitySectionData section = sectionsByType[type]!;
      expect(
        section.cards.map((ActivityCardData card) => card.status).toSet(),
        type.allowedStatuses,
      );
      expect(
        section.cards,
        everyElement(
          isA<ActivityCardData>().having(
            (ActivityCardData card) => type.allowedChips.contains(card.chip),
            'chip allowed in section',
            isTrue,
          ),
        ),
      );
      for (final ActivityCardData card in section.cards) {
        final int currentStatusIndex = card.chip.statusPath.indexOf(
          card.status,
        );
        expect(
          card.statusHistory.map(
            (ActivityStatusHistoryEntry entry) => entry.status,
          ),
          card.chip.statusPath.take(currentStatusIndex),
          reason: '${card.id} should expose every past state in flow order',
        );
      }
    }
  });

  test('demo contacts expose real names and nickname-based avatars', () async {
    final List<ActivitySectionData> sections =
        await const ActivityDemoRepository().loadSections();
    final List<ActivityContactData> contacts = sections
        .expand((ActivitySectionData section) => section.cards)
        .map((ActivityCardData card) => card.contact)
        .whereType<ActivityContactData>()
        .toList(growable: false);

    expect(contacts, isNotEmpty);
    expect(
      contacts,
      everyElement(
        isA<ActivityContactData>()
            .having(
              (ActivityContactData contact) => contact.name.contains(' '),
              'real name',
              isTrue,
            )
            .having(
              (ActivityContactData contact) =>
                  contact.nickname.runes.length <= 10,
              'nickname length',
              isTrue,
            )
            .having(
              (ActivityContactData contact) =>
                  contact.avatarSystemImage.endsWith('.circle.fill'),
              'nickname avatar',
              isTrue,
            ),
      ),
    );
  });

  test('activity types resolve the users role consistently', () {
    expect(ActivityChip.jobAccepted.userRole, ActivityUserRole.helper);
    expect(ActivityChip.jobCompletedByYou.userRole, ActivityUserRole.helper);
    expect(ActivityChip.serviceBooked.userRole, ActivityUserRole.customer);
    expect(
      ActivityChip.serviceBookedWithYou.userRole,
      ActivityUserRole.provider,
    );
    expect(ActivityChip.serviceOffered.userRole, ActivityUserRole.provider);
    expect(ActivityChip.jobCreated.userRole, ActivityUserRole.client);
  });

  test('rejects a status that is not allowed in its section', () {
    expect(
      () => ActivitySectionData.fromJson(<String, Object?>{
        'id': 'created',
        'cards': <Object?>[
          _activityJson(
            chip: ActivityChip.jobCreated,
            status: ActivityStatus.confirmed,
          ),
        ],
      }),
      throwsFormatException,
    );
  });

  test('rejects an activity type that is not allowed in its section', () {
    expect(
      () => ActivitySectionData.fromJson(<String, Object?>{
        'id': 'created',
        'cards': <Object?>[
          _activityJson(
            chip: ActivityChip.serviceBooked,
            status: ActivityStatus.inProgress,
          ),
        ],
      }),
      throwsFormatException,
    );
  });

  test('rejects invalid programmatic activity construction', () {
    expect(
      () => ActivityCardData(
        id: 'invalid-activity',
        sectionType: ActivitySectionType.completedForYou,
        title: 'Testaktivität',
        chip: ActivityChip.jobCreated,
        scheduleText: 'Heute, 14:00',
        compensationText: '20 €',
        locationText: '1 km entfernt',
        description: 'Testbeschreibung',
        status: ActivityStatus.inProgress,
        iconPath: 'briefcase.fill',
      ),
      throwsArgumentError,
    );
  });

  test('rejects a card placed in a different programmatic section', () {
    final ActivityCardData runningCard = ActivityCardData(
      id: 'running-activity',
      sectionType: ActivitySectionType.running,
      title: 'Testaktivität',
      chip: ActivityChip.jobAccepted,
      scheduleText: 'Heute, 14:00',
      compensationText: '20 €',
      locationText: '1 km entfernt',
      description: 'Testbeschreibung',
      status: ActivityStatus.confirmed,
      iconPath: 'briefcase.fill',
    );

    expect(
      () => ActivitySectionData(
        type: ActivitySectionType.created,
        cards: <ActivityCardData>[runningCard],
      ),
      throwsArgumentError,
    );
  });

  test('rejects past states outside the activity flow order', () {
    expect(
      () => ActivityCardData(
        id: 'invalid-history',
        sectionType: ActivitySectionType.running,
        title: 'Testaktivität',
        chip: ActivityChip.jobAccepted,
        scheduleText: 'Heute, 14:00',
        compensationText: '20 €',
        locationText: '1 km entfernt',
        description: 'Testbeschreibung',
        status: ActivityStatus.inProgress,
        iconPath: 'briefcase.fill',
        statusHistory: const <ActivityStatusHistoryEntry>[
          ActivityStatusHistoryEntry(
            status: ActivityStatus.confirmed,
            timestampText: 'Heute, 09:00',
          ),
          ActivityStatusHistoryEntry(
            status: ActivityStatus.agreementPending,
            timestampText: 'Heute, 08:00',
          ),
        ],
      ),
      throwsArgumentError,
    );
  });
}

Map<String, Object?> _activityJson({
  required ActivityChip chip,
  required ActivityStatus status,
}) {
  return <String, Object?>{
    'id': 'test-activity',
    'title': 'Testaktivität',
    'chip': chip.name,
    'scheduleText': 'Heute, 14:00',
    'compensationText': '20 €',
    'locationText': '1 km entfernt',
    'description': 'Testbeschreibung',
    'status': status.name,
    'iconPath': 'briefcase.fill',
  };
}
