import 'activity_models.dart';

class ActiveActivitySummary {
  const ActiveActivitySummary({required this.activity, required this.priority});

  final ActivityCardData activity;
  final int priority;

  String get toastKey => '${activity.id}:${activity.status.name}';
}

class ActiveActivitySelector {
  const ActiveActivitySelector._();

  static ActiveActivitySummary? select(Iterable<ActivitySectionData> sections) {
    ActiveActivitySummary? selected;

    for (final ActivitySectionData section in sections) {
      for (final ActivityCardData activity in section.cards) {
        final int? priority = priorityFor(activity.status);
        if (priority == null) {
          continue;
        }

        final ActiveActivitySummary candidate = ActiveActivitySummary(
          activity: activity,
          priority: priority,
        );
        if (selected == null || priority < selected.priority) {
          selected = candidate;
        }
      }
    }

    return selected;
  }

  static int? priorityFor(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.completionConfirmation:
      case ActivityStatus.completionReported:
        return 0;
      case ActivityStatus.inProgress:
        return 1;
      case ActivityStatus.confirmed:
        return 2;
      case ActivityStatus.agreementPending:
      case ActivityStatus.helperNeeded:
      case ActivityStatus.completed:
        return null;
    }
  }
}
