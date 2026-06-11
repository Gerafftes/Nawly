enum ActivityChip {
  jobAccepted,
  serviceBooked,
  serviceBookedWithYou,
  jobCreated,
  serviceOffered,
  jobCompletedByYou,
}

extension ActivityChipLabel on ActivityChip {
  String get label {
    switch (this) {
      case ActivityChip.jobAccepted:
        return 'Job angenommen';
      case ActivityChip.serviceBooked:
        return 'Service gebucht';
      case ActivityChip.serviceBookedWithYou:
        return 'Service bei dir gebucht';
      case ActivityChip.jobCreated:
        return 'Job erstellt';
      case ActivityChip.serviceOffered:
        return 'Service angeboten';
      case ActivityChip.jobCompletedByYou:
        return 'Job von dir Erledigt';
    }
  }

  static ActivityChip fromJson(String value) {
    return ActivityChip.values.firstWhere(
      (chip) => chip.name == value,
      orElse: () => throw FormatException('Unknown activity chip: $value'),
    );
  }
}

enum ActivityStatus {
  agreementPending,
  confirmed,
  inProgress,
  completionReported,
  helperNeeded,
  completionConfirmation,
  completed,
}

extension ActivityStatusContent on ActivityStatus {
  String get label {
    switch (this) {
      case ActivityStatus.agreementPending:
        return 'Zusage ausstehend';
      case ActivityStatus.confirmed:
        return 'Bestätigt';
      case ActivityStatus.inProgress:
        return 'In Arbeit';
      case ActivityStatus.completionReported:
        return 'Fertig gemeldet';
      case ActivityStatus.helperNeeded:
        return 'Helfer gesucht';
      case ActivityStatus.completionConfirmation:
        return 'Abschluss bestätigen';
      case ActivityStatus.completed:
        return 'Erledigt';
    }
  }

  String get iconPath {
    switch (this) {
      case ActivityStatus.agreementPending:
      case ActivityStatus.helperNeeded:
        return 'arrow.left.arrow.right';
      case ActivityStatus.confirmed:
        return 'clock';
      case ActivityStatus.inProgress:
        return 'alarm.fill';
      case ActivityStatus.completionReported:
      case ActivityStatus.completionConfirmation:
        return 'hourglass';
      case ActivityStatus.completed:
        return 'checkmark';
    }
  }

  static ActivityStatus fromJson(String value) {
    return ActivityStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => throw FormatException('Unknown activity status: $value'),
    );
  }
}

class ActivityCardData {
  const ActivityCardData({
    required this.id,
    required this.title,
    required this.chip,
    required this.metaText,
    required this.status,
    required this.iconPath,
    this.showsVisibilityBadge = false,
  });

  factory ActivityCardData.fromJson(Map<String, Object?> json) {
    return ActivityCardData(
      id: json['id'] as String,
      title: json['title'] as String,
      chip: ActivityChipLabel.fromJson(json['chip'] as String),
      metaText: json['metaText'] as String,
      status: ActivityStatusContent.fromJson(json['status'] as String),
      iconPath: json['iconPath'] as String,
      showsVisibilityBadge: json['showsVisibilityBadge'] as bool? ?? false,
    );
  }

  final String id;
  final String title;
  final ActivityChip chip;
  final String metaText;
  final ActivityStatus status;
  final String iconPath;
  final bool showsVisibilityBadge;
}

class ActivitySectionData {
  const ActivitySectionData({
    required this.id,
    required this.title,
    required this.availableStates,
    required this.cards,
  });

  factory ActivitySectionData.fromJson(Map<String, Object?> json) {
    final List<Object?> rawStates = json['availableStates'] as List<Object?>;
    final List<Object?> rawCards = json['cards'] as List<Object?>;

    return ActivitySectionData(
      id: json['id'] as String,
      title: json['title'] as String,
      availableStates: rawStates
          .cast<String>()
          .map(ActivityStatusContent.fromJson)
          .toList(growable: false),
      cards: rawCards
          .cast<Map<String, Object?>>()
          .map(ActivityCardData.fromJson)
          .toList(growable: false),
    );
  }

  final String id;
  final String title;
  final List<ActivityStatus> availableStates;
  final List<ActivityCardData> cards;
}
