import 'nickname.dart';

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

  String labelFor(ActivityChip chip) {
    switch (this) {
      case ActivityStatus.agreementPending:
        return chip == ActivityChip.serviceBooked
            ? 'Buchungsanfrage gesendet'
            : 'Warten auf Antwort';
      case ActivityStatus.confirmed:
        switch (chip) {
          case ActivityChip.serviceBooked:
          case ActivityChip.serviceBookedWithYou:
            return 'Buchung bestätigt';
          case ActivityChip.jobAccepted:
          case ActivityChip.jobCreated:
          case ActivityChip.serviceOffered:
          case ActivityChip.jobCompletedByYou:
            return 'Auftrag bestätigt';
        }
      case ActivityStatus.inProgress:
        switch (chip) {
          case ActivityChip.serviceBooked:
          case ActivityChip.serviceBookedWithYou:
          case ActivityChip.serviceOffered:
            return 'Service läuft';
          case ActivityChip.jobAccepted:
          case ActivityChip.jobCreated:
          case ActivityChip.jobCompletedByYou:
            return 'Auftrag läuft';
        }
      case ActivityStatus.completionReported:
      case ActivityStatus.completionConfirmation:
        return 'Abschluss gemeldet';
      case ActivityStatus.helperNeeded:
        return 'Helfer gesucht';
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
      (ActivityStatus status) => status.name == value,
      orElse: () => throw FormatException('Unknown activity status: $value'),
    );
  }
}

enum ActivityChip {
  jobAccepted,
  serviceBooked,
  serviceBookedWithYou,
  jobCreated,
  serviceOffered,
  jobCompletedByYou,
}

extension ActivityChipContent on ActivityChip {
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
        return 'Job von dir erledigt';
    }
  }

  ActivityUserRole get userRole {
    switch (this) {
      case ActivityChip.jobAccepted:
      case ActivityChip.jobCompletedByYou:
        return ActivityUserRole.helper;
      case ActivityChip.serviceBooked:
        return ActivityUserRole.customer;
      case ActivityChip.serviceBookedWithYou:
      case ActivityChip.serviceOffered:
        return ActivityUserRole.provider;
      case ActivityChip.jobCreated:
        return ActivityUserRole.client;
    }
  }

  List<ActivityStatus> get statusPath {
    switch (this) {
      case ActivityChip.jobAccepted:
      case ActivityChip.jobCompletedByYou:
      case ActivityChip.serviceBooked:
      case ActivityChip.serviceBookedWithYou:
        return const <ActivityStatus>[
          ActivityStatus.agreementPending,
          ActivityStatus.confirmed,
          ActivityStatus.inProgress,
          ActivityStatus.completionReported,
          ActivityStatus.completed,
        ];
      case ActivityChip.jobCreated:
        return const <ActivityStatus>[
          ActivityStatus.helperNeeded,
          ActivityStatus.inProgress,
          ActivityStatus.completionConfirmation,
          ActivityStatus.completed,
        ];
      case ActivityChip.serviceOffered:
        return const <ActivityStatus>[ActivityStatus.inProgress];
    }
  }

  static ActivityChip fromJson(String value) {
    return ActivityChip.values.firstWhere(
      (ActivityChip chip) => chip.name == value,
      orElse: () => throw FormatException('Unknown activity chip: $value'),
    );
  }
}

enum ActivityUserRole { helper, customer, provider, client }

extension ActivityUserRoleContent on ActivityUserRole {
  String get label {
    switch (this) {
      case ActivityUserRole.helper:
        return 'Helfer';
      case ActivityUserRole.customer:
        return 'Kunde';
      case ActivityUserRole.provider:
        return 'Anbieter';
      case ActivityUserRole.client:
        return 'Auftraggeber';
    }
  }
}

enum ActivitySectionType {
  running,
  created,
  completedForOthers,
  completedForYou,
}

extension ActivitySectionTypeContent on ActivitySectionType {
  String get id => name;

  String get title {
    switch (this) {
      case ActivitySectionType.running:
        return 'Laufend';
      case ActivitySectionType.created:
        return 'Von dir erstellt';
      case ActivitySectionType.completedForOthers:
        return 'Für andere erledigt';
      case ActivitySectionType.completedForYou:
        return 'Für dich erledigt';
    }
  }

  Set<ActivityStatus> get allowedStatuses {
    switch (this) {
      case ActivitySectionType.running:
        return const <ActivityStatus>{
          ActivityStatus.agreementPending,
          ActivityStatus.confirmed,
          ActivityStatus.inProgress,
          ActivityStatus.completionReported,
        };
      case ActivitySectionType.created:
        return const <ActivityStatus>{
          ActivityStatus.helperNeeded,
          ActivityStatus.inProgress,
          ActivityStatus.completionConfirmation,
        };
      case ActivitySectionType.completedForOthers:
      case ActivitySectionType.completedForYou:
        return const <ActivityStatus>{ActivityStatus.completed};
    }
  }

  Set<ActivityChip> get allowedChips {
    switch (this) {
      case ActivitySectionType.running:
        return const <ActivityChip>{
          ActivityChip.jobAccepted,
          ActivityChip.serviceBooked,
          ActivityChip.serviceBookedWithYou,
        };
      case ActivitySectionType.created:
        return const <ActivityChip>{
          ActivityChip.jobCreated,
          ActivityChip.serviceOffered,
        };
      case ActivitySectionType.completedForOthers:
        return const <ActivityChip>{
          ActivityChip.jobCompletedByYou,
          ActivityChip.serviceBookedWithYou,
        };
      case ActivitySectionType.completedForYou:
        return const <ActivityChip>{
          ActivityChip.jobCreated,
          ActivityChip.serviceBooked,
        };
    }
  }

  static ActivitySectionType fromJson(String value) {
    return ActivitySectionType.values.firstWhere(
      (ActivitySectionType type) => type.id == value,
      orElse: () => throw FormatException('Unknown activity section: $value'),
    );
  }
}

class ActivityContactData {
  ActivityContactData({
    required this.name,
    required String nickname,
    required this.role,
    required this.summary,
  }) : assert(name.isNotEmpty),
       nickname = NicknameRules.requireValid(nickname);

  factory ActivityContactData.fromJson(Map<String, Object?> json) {
    return ActivityContactData(
      name: json['name'] as String,
      nickname: NicknameRules.requireValid(json['nickname']),
      role: json['role'] as String,
      summary: json['summary'] as String,
    );
  }

  final String name;
  final String nickname;
  final String role;
  final String summary;

  String get avatarInitial => NicknameRules.initial(nickname);
  String get avatarSystemImage => NicknameRules.avatarSystemImage(nickname);
}

class ActivityStatusHistoryEntry {
  const ActivityStatusHistoryEntry({
    required this.status,
    required this.timestampText,
  });

  factory ActivityStatusHistoryEntry.fromJson(Map<String, Object?> json) {
    return ActivityStatusHistoryEntry(
      status: ActivityStatusContent.fromJson(json['status'] as String),
      timestampText: json['timestampText'] as String,
    );
  }

  final ActivityStatus status;
  final String timestampText;
}

class ActivityCardData {
  factory ActivityCardData({
    required String id,
    required ActivitySectionType sectionType,
    required String title,
    required ActivityChip chip,
    required String scheduleText,
    required String compensationText,
    required String locationText,
    required String description,
    required ActivityStatus status,
    required String iconPath,
    ActivityContactData? contact,
    List<ActivityStatusHistoryEntry> statusHistory =
        const <ActivityStatusHistoryEntry>[],
    bool showsVisibilityBadge = false,
  }) {
    if (!sectionType.allowedStatuses.contains(status)) {
      throw ArgumentError.value(
        status,
        'status',
        '${status.label} is not allowed in ${sectionType.title}',
      );
    }
    if (!sectionType.allowedChips.contains(chip)) {
      throw ArgumentError.value(
        chip,
        'chip',
        '${chip.label} is not allowed in ${sectionType.title}',
      );
    }
    _validateStatusHistory(
      chip: chip,
      currentStatus: status,
      statusHistory: statusHistory,
      error: (String message) =>
          ArgumentError.value(statusHistory, 'statusHistory', message),
    );

    return ActivityCardData._(
      id: id,
      sectionType: sectionType,
      title: title,
      chip: chip,
      scheduleText: scheduleText,
      compensationText: compensationText,
      locationText: locationText,
      description: description,
      status: status,
      iconPath: iconPath,
      contact: contact,
      statusHistory: List<ActivityStatusHistoryEntry>.unmodifiable(
        statusHistory,
      ),
      showsVisibilityBadge: showsVisibilityBadge,
    );
  }

  const ActivityCardData._({
    required this.id,
    required this.sectionType,
    required this.title,
    required this.chip,
    required this.scheduleText,
    required this.compensationText,
    required this.locationText,
    required this.description,
    required this.status,
    required this.iconPath,
    required this.contact,
    required this.statusHistory,
    required this.showsVisibilityBadge,
  });

  factory ActivityCardData.fromJson(
    Map<String, Object?> json, {
    required ActivitySectionType sectionType,
  }) {
    final ActivityStatus status = ActivityStatusContent.fromJson(
      json['status'] as String,
    );
    final ActivityChip chip = ActivityChipContent.fromJson(
      json['chip'] as String,
    );

    if (!sectionType.allowedStatuses.contains(status)) {
      throw FormatException(
        '${status.label} is not allowed in ${sectionType.title}',
      );
    }
    if (!sectionType.allowedChips.contains(chip)) {
      throw FormatException(
        '${chip.label} is not allowed in ${sectionType.title}',
      );
    }

    final Object? rawContact = json['contact'];
    if (rawContact != null && rawContact is! Map<String, Object?>) {
      throw const FormatException('Activity contact must be a JSON object');
    }
    final Object? rawStatusHistory = json['statusHistory'];
    if (rawStatusHistory != null && rawStatusHistory is! List<Object?>) {
      throw const FormatException(
        'Activity status history must be a JSON list',
      );
    }
    final List<ActivityStatusHistoryEntry> statusHistory =
        (rawStatusHistory as List<Object?>? ?? const <Object?>[])
            .cast<Map<String, Object?>>()
            .map(ActivityStatusHistoryEntry.fromJson)
            .toList(growable: false);
    _validateStatusHistory(
      chip: chip,
      currentStatus: status,
      statusHistory: statusHistory,
      error: (String message) => FormatException(message),
    );

    return ActivityCardData._(
      id: json['id'] as String,
      sectionType: sectionType,
      title: json['title'] as String,
      chip: chip,
      scheduleText: json['scheduleText'] as String,
      compensationText: json['compensationText'] as String,
      locationText: json['locationText'] as String,
      description: json['description'] as String,
      status: status,
      iconPath: json['iconPath'] as String,
      contact: rawContact is Map<String, Object?>
          ? ActivityContactData.fromJson(rawContact)
          : null,
      statusHistory: List<ActivityStatusHistoryEntry>.unmodifiable(
        statusHistory,
      ),
      showsVisibilityBadge: json['showsVisibilityBadge'] as bool? ?? false,
    );
  }

  final String id;
  final ActivitySectionType sectionType;
  final String title;
  final ActivityChip chip;
  final String scheduleText;
  final String compensationText;
  final String locationText;
  final String description;
  final ActivityStatus status;
  final String iconPath;
  final ActivityContactData? contact;
  final List<ActivityStatusHistoryEntry> statusHistory;
  final bool showsVisibilityBadge;

  String get metaText => '$scheduleText · $compensationText';
  ActivityUserRole get userRole => chip.userRole;

  String get identityActivityTypeLabel {
    if (chip == ActivityChip.jobAccepted &&
        status == ActivityStatus.agreementPending) {
      return 'Anfrage gesendet';
    }
    return chip.label;
  }
}

void _validateStatusHistory({
  required ActivityChip chip,
  required ActivityStatus currentStatus,
  required List<ActivityStatusHistoryEntry> statusHistory,
  required Object Function(String message) error,
}) {
  final List<ActivityStatus> statusPath = chip.statusPath;
  final int currentStatusIndex = statusPath.indexOf(currentStatus);
  if (currentStatusIndex < 0) {
    throw error('${currentStatus.label} is not part of the ${chip.label} flow');
  }

  int previousStatusIndex = -1;
  for (final ActivityStatusHistoryEntry entry in statusHistory) {
    final int statusIndex = statusPath.indexOf(entry.status);
    if (statusIndex < 0 || statusIndex >= currentStatusIndex) {
      throw error(
        '${entry.status.label} must occur before ${currentStatus.label}',
      );
    }
    if (statusIndex <= previousStatusIndex) {
      throw error('Activity status history must follow the flow order');
    }
    previousStatusIndex = statusIndex;
  }
}

class ActivitySectionData {
  factory ActivitySectionData({
    required ActivitySectionType type,
    required List<ActivityCardData> cards,
  }) {
    if (cards.any((ActivityCardData card) => card.sectionType != type)) {
      throw ArgumentError.value(
        cards,
        'cards',
        'Every activity card must belong to ${type.title}',
      );
    }

    return ActivitySectionData._(
      type: type,
      cards: List<ActivityCardData>.unmodifiable(cards),
    );
  }

  const ActivitySectionData._({required this.type, required this.cards});

  factory ActivitySectionData.fromJson(Map<String, Object?> json) {
    final ActivitySectionType type = ActivitySectionTypeContent.fromJson(
      json['id'] as String,
    );
    final List<Object?> rawCards = json['cards'] as List<Object?>;

    return ActivitySectionData._(
      type: type,
      cards: rawCards
          .cast<Map<String, Object?>>()
          .map(
            (Map<String, Object?> card) =>
                ActivityCardData.fromJson(card, sectionType: type),
          )
          .toList(growable: false),
    );
  }

  final ActivitySectionType type;
  final List<ActivityCardData> cards;

  String get id => type.id;
  String get title => type.title;
}
