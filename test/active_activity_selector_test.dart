import 'package:flutter_test/flutter_test.dart';
import 'package:nawly/models/active_activity.dart';
import 'package:nawly/models/activity_models.dart';

void main() {
  test('filters out pending, helper-needed, and completed activities', () {
    final ActiveActivitySummary? selected = ActiveActivitySelector.select(
      <ActivitySectionData>[
        _section(ActivitySectionType.running, <ActivityCardData>[
          _activity(
            id: 'pending',
            sectionType: ActivitySectionType.running,
            chip: ActivityChip.jobAccepted,
            status: ActivityStatus.agreementPending,
          ),
          _activity(
            id: 'confirmed',
            sectionType: ActivitySectionType.running,
            chip: ActivityChip.serviceBooked,
            status: ActivityStatus.confirmed,
          ),
        ]),
        _section(ActivitySectionType.created, <ActivityCardData>[
          _activity(
            id: 'helper-needed',
            sectionType: ActivitySectionType.created,
            chip: ActivityChip.jobCreated,
            status: ActivityStatus.helperNeeded,
          ),
        ]),
        _section(ActivitySectionType.completedForYou, <ActivityCardData>[
          _activity(
            id: 'completed',
            sectionType: ActivitySectionType.completedForYou,
            chip: ActivityChip.jobCreated,
            status: ActivityStatus.completed,
          ),
        ]),
      ],
    );

    expect(selected?.activity.id, 'confirmed');
  });

  test(
    'prioritizes completion actions over in-progress and confirmed work',
    () {
      final ActiveActivitySummary? selected = ActiveActivitySelector.select(
        <ActivitySectionData>[
          _section(ActivitySectionType.running, <ActivityCardData>[
            _activity(
              id: 'confirmed',
              sectionType: ActivitySectionType.running,
              chip: ActivityChip.serviceBooked,
              status: ActivityStatus.confirmed,
            ),
            _activity(
              id: 'in-progress',
              sectionType: ActivitySectionType.running,
              chip: ActivityChip.serviceBookedWithYou,
              status: ActivityStatus.inProgress,
            ),
          ]),
          _section(ActivitySectionType.created, <ActivityCardData>[
            _activity(
              id: 'completion-confirmation',
              sectionType: ActivitySectionType.created,
              chip: ActivityChip.jobCreated,
              status: ActivityStatus.completionConfirmation,
            ),
          ]),
        ],
      );

      expect(selected?.activity.id, 'completion-confirmation');
      expect(selected?.priority, 0);
    },
  );

  test('keeps repository order when priorities are equal', () {
    final ActiveActivitySummary? selected = ActiveActivitySelector.select(
      <ActivitySectionData>[
        _section(ActivitySectionType.running, <ActivityCardData>[
          _activity(
            id: 'first',
            sectionType: ActivitySectionType.running,
            chip: ActivityChip.serviceBooked,
            status: ActivityStatus.completionReported,
          ),
          _activity(
            id: 'second',
            sectionType: ActivitySectionType.running,
            chip: ActivityChip.serviceBooked,
            status: ActivityStatus.completionReported,
          ),
        ]),
      ],
    );

    expect(selected?.activity.id, 'first');
  });

  test('includes an offered service once it is in progress', () {
    final ActiveActivitySummary? selected = ActiveActivitySelector.select(
      <ActivitySectionData>[
        _section(ActivitySectionType.created, <ActivityCardData>[
          _activity(
            id: 'offered-service',
            sectionType: ActivitySectionType.created,
            chip: ActivityChip.serviceOffered,
            status: ActivityStatus.inProgress,
          ),
        ]),
      ],
    );

    expect(selected?.activity.id, 'offered-service');
  });
}

ActivitySectionData _section(
  ActivitySectionType type,
  List<ActivityCardData> cards,
) {
  return ActivitySectionData(type: type, cards: cards);
}

ActivityCardData _activity({
  required String id,
  required ActivitySectionType sectionType,
  required ActivityChip chip,
  required ActivityStatus status,
}) {
  return ActivityCardData(
    id: id,
    sectionType: sectionType,
    title: id,
    chip: chip,
    scheduleText: 'Heute, 14:00',
    compensationText: '20 €',
    locationText: '1 km entfernt',
    description: 'Testbeschreibung',
    status: status,
    iconPath: 'assets/icons/briefcase.fill.svg',
  );
}
