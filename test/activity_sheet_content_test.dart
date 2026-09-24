import 'package:flutter_test/flutter_test.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';
import 'package:nawly/models/activity_models.dart';
import 'package:nawly/models/user_profile_models.dart';
import 'package:nawly/pages/tabs/activity_sheet_content.dart';

final UserProfileSummaryData _currentUser = UserProfileSummaryData(
  name: 'Johann',
  nickname: 'Gerafftes',
  rating: 4.9,
  completedJobs: 5,
  skillInputHint: 'Nachhilfe',
  skills: <String>[],
);

void main() {
  test('every visible status builds a sheet without placeholder content', () {
    final List<ActivityCardData> activities = <ActivityCardData>[
      _activity(
        sectionType: ActivitySectionType.running,
        chip: ActivityChip.jobAccepted,
        status: ActivityStatus.agreementPending,
      ),
      _activity(
        sectionType: ActivitySectionType.running,
        chip: ActivityChip.serviceBooked,
        status: ActivityStatus.confirmed,
      ),
      _activity(
        sectionType: ActivitySectionType.running,
        chip: ActivityChip.serviceBookedWithYou,
        status: ActivityStatus.inProgress,
      ),
      _activity(
        sectionType: ActivitySectionType.running,
        chip: ActivityChip.serviceBooked,
        status: ActivityStatus.completionReported,
      ),
      _activity(
        sectionType: ActivitySectionType.created,
        chip: ActivityChip.jobCreated,
        status: ActivityStatus.helperNeeded,
      ),
      _activity(
        sectionType: ActivitySectionType.created,
        chip: ActivityChip.serviceOffered,
        status: ActivityStatus.inProgress,
      ),
      _activity(
        sectionType: ActivitySectionType.created,
        chip: ActivityChip.jobCreated,
        status: ActivityStatus.completionConfirmation,
      ),
      _activity(
        sectionType: ActivitySectionType.completedForYou,
        chip: ActivityChip.jobCreated,
        status: ActivityStatus.completed,
      ),
    ];

    for (final ActivityCardData activity in activities) {
      final AppleLiquidSheetContent sheet = activity.toSheetContent(
        userProfile: _currentUser,
        onAction: (_, _) {},
      );
      final Iterable<AppleLiquidSheetRow> rows = sheet.sections.expand(
        (AppleLiquidSheetSection section) => section.rows,
      );

      expect(sheet.title, activity.title);
      expect(sheet.detents?.initialHeight, 560);
      expect(sheet.detents?.expandedHeight, isNull);
      expect(sheet.detents?.allowsAutomaticExpansion, isFalse);
      expect(sheet.showsSectionBackgrounds, isFalse);
      expect(
        sheet.sections,
        everyElement(
          isA<AppleLiquidSheetSection>().having(
            (AppleLiquidSheetSection section) => section.showsBackground,
            'section background',
            isFalse,
          ),
        ),
      );
      expect(
        sheet.sections
            .where((AppleLiquidSheetSection section) => section.title != null)
            .map(
              (AppleLiquidSheetSection section) => section.titleHorizontalInset,
            ),
        everyElement(16),
      );
      final AppleLiquidSheetRow identity = sheet.sections.first.rows.first;
      expect(identity.type, AppleLiquidSheetRowType.identity);
      expect(identity.title, 'Du');
      expect(identity.role, activity.userRole.label);
      expect(identity.activityType, activity.identityActivityTypeLabel);
      expect(identity.systemImage, 'g.circle.fill');
      expect(
        identity.identityVariant,
        AppleLiquidSheetIdentityVariant.composed,
      );
      expect(identity.description, isNull);
      expect(identity.relatedPeople, hasLength(1));
      expect(identity.relatedPeople.single.title, 'Mara König');
      expect(identity.relatedPeople.single.subtitle, 'Kontakt');
      expect(
        identity.relatedPeople.single.badges.map(
          (AppleLiquidSheetIdentityBadge badge) => badge.label,
        ),
        <String>['Verifiziert', '4,9'],
      );
      final AppleLiquidSheetSection currentStatus = sheet.sections.firstWhere(
        (AppleLiquidSheetSection section) =>
            section.rows.first.type == AppleLiquidSheetRowType.timeline,
      );
      final AppleLiquidSheetRow timeline = currentStatus.rows.first;
      expect(currentStatus.title, isNull);
      expect(timeline.type, AppleLiquidSheetRowType.timeline);
      expect(timeline.title, 'Aktueller Status');
      expect(timeline.currentStepIndex, activity.currentStatusIndex);
      expect(timeline.collapsedStepLimit, 2);
      expect(timeline.initiallyExpanded, isFalse);
      expect(timeline.expandLabel, 'Gesamten Ablauf anzeigen');
      expect(timeline.collapseLabel, 'Weniger anzeigen');
      expect(
        timeline.timelineSteps[activity.currentStatusIndex].title,
        activity.status.labelFor(activity.chip),
      );
      expect(
        timeline.timelineSteps[activity.currentStatusIndex].systemImage,
        activity.status.iconPath,
      );
      expect(
        rows.any(
          (AppleLiquidSheetRow row) =>
              row.title.contains('Platzhalter') ||
              (row.subtitle?.contains('Platzhalter') ?? false),
        ),
        isFalse,
      );
    }
  });

  test('completion-reported booked service asks for confirmation', () {
    final ActivityCardData activity = _activity(
      sectionType: ActivitySectionType.running,
      chip: ActivityChip.serviceBooked,
      status: ActivityStatus.completionReported,
    );

    expect(activity.sheetActions, const <ActivitySheetAction>[
      ActivitySheetAction.confirmCompletion,
      ActivitySheetAction.message,
    ]);

    final AppleLiquidSheetContent sheet = activity.toSheetContent(
      userProfile: _currentUser,
      onAction: (_, _) {},
    );
    final AppleLiquidSheetSection currentStatus = sheet.sections.firstWhere(
      (AppleLiquidSheetSection section) =>
          section.rows.first.type == AppleLiquidSheetRowType.timeline,
    );
    expect(currentStatus.rows.last.title, 'Abschluss bestätigen');
  });

  test('service offer actions manage the reusable offer', () {
    final ActivityCardData activity = _activity(
      sectionType: ActivitySectionType.created,
      chip: ActivityChip.serviceOffered,
      status: ActivityStatus.inProgress,
    );

    expect(activity.sheetActions, const <ActivitySheetAction>[
      ActivitySheetAction.editService,
      ActivitySheetAction.pauseService,
    ]);

    final AppleLiquidSheetContent sheet = activity.toSheetContent(
      userProfile: _currentUser,
      onAction: (_, _) {},
    );
    final AppleLiquidSheetSection details = sheet.sections.firstWhere(
      (AppleLiquidSheetSection section) => section.title == 'Dein Angebot',
    );
    final AppleLiquidSheetRow facts = details.rows.first;

    expect(facts.type, AppleLiquidSheetRowType.factsGrid);
    expect(facts.columns, 3);
    expect(facts.facts.map((AppleLiquidSheetFact fact) => fact.label), <String>[
      'Verfügbarkeit',
      'Gebiet',
      'Preis',
    ]);
  });

  test('recommendation copy adapts status, details, and message actions', () {
    final ActivityCardData helperActivity = _activity(
      sectionType: ActivitySectionType.running,
      chip: ActivityChip.jobAccepted,
      status: ActivityStatus.agreementPending,
    );
    final AppleLiquidSheetContent helperSheet = helperActivity.toSheetContent(
      userProfile: _currentUser,
      onAction: (_, _) {},
    );
    final AppleLiquidSheetRow helperFacts = helperSheet.sections
        .expand((AppleLiquidSheetSection section) => section.rows)
        .firstWhere(
          (AppleLiquidSheetRow row) =>
              row.type == AppleLiquidSheetRowType.factsGrid,
        );
    final List<String> helperActionTitles = helperSheet.sections
        .expand((AppleLiquidSheetSection section) => section.rows)
        .where(
          (AppleLiquidSheetRow row) =>
              row.type == AppleLiquidSheetRowType.button,
        )
        .map((AppleLiquidSheetRow row) => row.title)
        .toList();

    expect(helperActivity.chip.label, 'Job angenommen');
    expect(helperActivity.identityActivityTypeLabel, 'Anfrage gesendet');
    expect(
      helperActivity.status.labelFor(helperActivity.chip),
      'Warten auf Antwort',
    );
    expect(
      helperFacts.facts.map((AppleLiquidSheetFact fact) => fact.label),
      <String>['Termin', 'Entfernung', 'Verdienst'],
    );
    expect(helperFacts.facts[1].value, '1 km');
    expect(helperActionTitles, contains('Mara schreiben'));

    final ActivityCardData customerActivity = _activity(
      sectionType: ActivitySectionType.running,
      chip: ActivityChip.serviceBooked,
      status: ActivityStatus.confirmed,
    );
    expect(
      customerActivity.status.labelFor(customerActivity.chip),
      'Buchung bestätigt',
    );
    final AppleLiquidSheetRow customerFacts = customerActivity
        .toSheetContent(userProfile: _currentUser, onAction: (_, _) {})
        .sections
        .expand((AppleLiquidSheetSection section) => section.rows)
        .firstWhere(
          (AppleLiquidSheetRow row) =>
              row.type == AppleLiquidSheetRowType.factsGrid,
        );
    expect(
      customerFacts.facts.map((AppleLiquidSheetFact fact) => fact.label),
      <String>['Termin', 'Entfernung', 'Preis'],
    );
  });

  test(
    'active order details hide the redundant title and compact description',
    () {
      const String longDescription =
          'Eine ausführliche Beschreibung mit mehreren Details zum Ablauf, '
          'zum benötigten Material und zu den besonderen Hinweisen vor Ort.';
      final ActivityCardData activity = _activity(
        sectionType: ActivitySectionType.running,
        chip: ActivityChip.jobAccepted,
        status: ActivityStatus.agreementPending,
        description: longDescription,
      );

      final AppleLiquidSheetContent sheet = activity.toSheetContent(
        userProfile: _currentUser,
        onAction: (_, _) {},
      );
      final AppleLiquidSheetSection details = sheet.sections.firstWhere(
        (AppleLiquidSheetSection section) => section.rows.any(
          (AppleLiquidSheetRow row) =>
              row.type == AppleLiquidSheetRowType.factsGrid,
        ),
      );
      final AppleLiquidSheetRow descriptionRow = details.rows.last;

      expect(details.title, isNull);
      expect(descriptionRow.type, AppleLiquidSheetRowType.navigation);
      expect(descriptionRow.title, 'Beschreibung');
      expect(descriptionRow.subtitle, isNotEmpty);
      expect(
        descriptionRow.subtitle!.split('\n'),
        hasLength(lessThanOrEqualTo(2)),
      );
      expect(descriptionRow.subtitle, endsWith('…'));

      final AppleLiquidSheetContent fullDescription = descriptionRow.content!;
      expect(fullDescription.title, 'Beschreibung');
      final AppleLiquidSheetRow fullDescriptionRow = fullDescription.sections
          .expand((AppleLiquidSheetSection section) => section.rows)
          .single;
      expect(fullDescriptionRow.type, AppleLiquidSheetRowType.text);
      expect(fullDescriptionRow.subtitle, longDescription);
    },
  );

  test('completed activity has no artificial next-step row', () {
    final ActivityCardData activity = _activity(
      sectionType: ActivitySectionType.completedForYou,
      chip: ActivityChip.jobCreated,
      status: ActivityStatus.completed,
    );

    final AppleLiquidSheetContent sheet = activity.toSheetContent(
      userProfile: _currentUser,
      onAction: (_, _) {},
    );
    final Iterable<AppleLiquidSheetRow> rows = sheet.sections.expand(
      (AppleLiquidSheetSection section) => section.rows,
    );

    expect(
      rows.any((AppleLiquidSheetRow row) => row.title == 'Als Nächstes'),
      isFalse,
    );
  });

  test('completed activities open order details on a nested sheet page', () {
    final List<ActivityCardData> activities = <ActivityCardData>[
      _activity(
        sectionType: ActivitySectionType.completedForYou,
        chip: ActivityChip.jobCreated,
        status: ActivityStatus.completed,
      ),
      _activity(
        sectionType: ActivitySectionType.completedForOthers,
        chip: ActivityChip.jobCompletedByYou,
        status: ActivityStatus.completed,
      ),
    ];

    for (final ActivityCardData activity in activities) {
      final AppleLiquidSheetContent sheet = activity.toSheetContent(
        userProfile: _currentUser,
        onAction: (_, _) {},
      );
      final List<AppleLiquidSheetRow> rootRows = sheet.sections
          .expand((AppleLiquidSheetSection section) => section.rows)
          .toList(growable: false);
      final AppleLiquidSheetRow identity = rootRows.singleWhere(
        (AppleLiquidSheetRow row) =>
            row.type == AppleLiquidSheetRowType.identity,
      );
      final AppleLiquidSheetRow detailsNavigation = rootRows.singleWhere(
        (AppleLiquidSheetRow row) =>
            row.type == AppleLiquidSheetRowType.navigation,
      );

      expect(identity.relatedPeople, hasLength(1));
      expect(identity.relatedPeople.single.title, 'Mara König');
      expect(identity.relatedPeople.single.subtitle, 'Kontakt');
      expect(detailsNavigation.title, 'Auftragsdetails');
      expect(detailsNavigation.systemImage, 'doc.text.fill');
      expect(
        rootRows.any(
          (AppleLiquidSheetRow row) =>
              row.type == AppleLiquidSheetRowType.factsGrid,
        ),
        isFalse,
      );

      final AppleLiquidSheetContent details = detailsNavigation.content!;
      expect(details.title, 'Auftrag');
      expect(details.detents?.initialHeight, 390);
      expect(details.detents?.expandedHeight, isNull);
      expect(details.detents?.allowsAutomaticExpansion, isFalse);
      expect(details.showsSectionBackgrounds, isFalse);
      expect(details.sections, hasLength(2));
      expect(
        sheet.sections.any(
          (AppleLiquidSheetSection section) =>
              section.title == 'Beteiligte Person',
        ),
        isFalse,
      );
      expect(details.sections.first.title, isNull);
      expect(details.sections.first.showsBackground, isFalse);
      expect(
        details.sections.first.rows.map((AppleLiquidSheetRow row) => row.type),
        <AppleLiquidSheetRowType>[
          AppleLiquidSheetRowType.factsGrid,
          AppleLiquidSheetRowType.text,
        ],
      );
      final AppleLiquidSheetSection participant = details.sections.last;
      expect(participant.title, 'Beteiligte Person');
      expect(participant.showsBackground, isFalse);
      expect(participant.rows.single.type, AppleLiquidSheetRowType.text);
      expect(participant.rows.single.title, 'Mara König');
      expect(participant.rows.single.subtitle, 'Kontakt · Verifiziert · ★ 4,9');
      expect(participant.rows.single.systemImage, 'm.circle.fill');
    }
  });

  test('timeline combines past, current, and upcoming states', () {
    final ActivityCardData activity = _activity(
      sectionType: ActivitySectionType.created,
      chip: ActivityChip.jobCreated,
      status: ActivityStatus.completionConfirmation,
      statusHistory: const <ActivityStatusHistoryEntry>[
        ActivityStatusHistoryEntry(
          status: ActivityStatus.helperNeeded,
          timestampText: 'Gestern, 12:10',
        ),
        ActivityStatusHistoryEntry(
          status: ActivityStatus.inProgress,
          timestampText: 'Heute, 13:05',
        ),
      ],
    );

    final AppleLiquidSheetContent sheet = activity.toSheetContent(
      userProfile: _currentUser,
      onAction: (_, _) {},
    );
    final AppleLiquidSheetSection currentStatus = sheet.sections.firstWhere(
      (AppleLiquidSheetSection section) =>
          section.rows.first.type == AppleLiquidSheetRowType.timeline,
    );
    final AppleLiquidSheetRow timeline = currentStatus.rows.first;

    expect(
      timeline.timelineSteps.map(
        (AppleLiquidSheetTimelineStep step) => step.title,
      ),
      <String>[
        'Helfer gesucht',
        'Auftrag läuft',
        'Abschluss gemeldet',
        'Erledigt',
      ],
    );
    expect(
      timeline.timelineSteps.map(
        (AppleLiquidSheetTimelineStep step) => step.subtitle,
      ),
      <String?>[
        'Gestern, 12:10',
        'Heute, 13:05',
        activity.statusDescription,
        null,
      ],
    );
    expect(timeline.currentStepIndex, 2);
    expect(timeline.collapsedStepLimit, 2);
    expect(timeline.initiallyExpanded, isFalse);
    expect(timeline.timelineSteps.length, greaterThan(3));
  });

  test('short timelines keep the same two-step collapse limit', () {
    final ActivityCardData activity = _activity(
      sectionType: ActivitySectionType.created,
      chip: ActivityChip.serviceOffered,
      status: ActivityStatus.inProgress,
    );

    final AppleLiquidSheetContent sheet = activity.toSheetContent(
      userProfile: _currentUser,
      onAction: (_, _) {},
    );
    final AppleLiquidSheetRow timeline = sheet.sections
        .expand((AppleLiquidSheetSection section) => section.rows)
        .firstWhere(
          (AppleLiquidSheetRow row) =>
              row.type == AppleLiquidSheetRowType.timeline,
        );

    expect(timeline.timelineSteps.length, lessThanOrEqualTo(2));
    expect(timeline.collapsedStepLimit, 2);
  });

  test('sheet button forwards the selected activity action', () {
    final ActivityCardData activity = _activity(
      sectionType: ActivitySectionType.created,
      chip: ActivityChip.jobCreated,
      status: ActivityStatus.helperNeeded,
    );
    ActivityCardData? selectedActivity;
    ActivitySheetAction? selectedAction;
    final AppleLiquidSheetContent sheet = activity.toSheetContent(
      userProfile: _currentUser,
      onAction: (ActivityCardData value, ActivitySheetAction action) {
        selectedActivity = value;
        selectedAction = action;
      },
    );
    final AppleLiquidSheetRow primaryAction = sheet.sections
        .expand((AppleLiquidSheetSection section) => section.rows)
        .firstWhere(
          (AppleLiquidSheetRow row) =>
              row.type == AppleLiquidSheetRowType.button,
        );

    primaryAction.onButtonPressed!();

    expect(primaryAction.title, 'Anfragen ansehen');
    expect(primaryAction.systemImage, 'person.2.fill');
    expect(primaryAction.buttonStyle?.rowTopInset, 8);
    expect(selectedActivity, same(activity));
    expect(selectedAction, ActivitySheetAction.viewRequests);
  });

  test('destructive button keeps its top corners clear of form clipping', () {
    final ActivityCardData activity = _activity(
      sectionType: ActivitySectionType.running,
      chip: ActivityChip.jobAccepted,
      status: ActivityStatus.agreementPending,
    );
    final AppleLiquidSheetContent sheet = activity.toSheetContent(
      userProfile: _currentUser,
      onAction: (_, _) {},
    );
    final AppleLiquidSheetRow destructiveAction = sheet.sections
        .expand((AppleLiquidSheetSection section) => section.rows)
        .singleWhere(
          (AppleLiquidSheetRow row) =>
              row.title == ActivitySheetAction.withdrawRequest.label,
        );

    expect(destructiveAction.buttonStyle?.rowTopInset, 4);
    expect(destructiveAction.buttonStyle?.rowBottomInset, 4);
  });

  test('identity header exposes the user and related person', () {
    final ActivityCardData activity = _activity(
      sectionType: ActivitySectionType.running,
      chip: ActivityChip.serviceBookedWithYou,
      status: ActivityStatus.inProgress,
    );

    final AppleLiquidSheetContent sheet = activity.toSheetContent(
      userProfile: _currentUser,
      onAction: (_, _) {},
    );
    final AppleLiquidSheetRow identity = sheet.sections.first.rows.single;

    expect(identity.type, AppleLiquidSheetRowType.identity);
    expect(identity.title, 'Du');
    expect(identity.role, 'Anbieter');
    expect(identity.activityType, 'Service bei dir gebucht');
    expect(identity.systemImage, 'g.circle.fill');
    expect(identity.identityVariant, AppleLiquidSheetIdentityVariant.composed);
    expect(identity.relatedPeople, hasLength(1));
    expect(identity.relatedPeople.single.title, 'Mara König');
    expect(identity.relatedPeople.single.subtitle, 'Kontakt');
    expect(
      identity.relatedPeople.single.badges.map(
        (AppleLiquidSheetIdentityBadge badge) => badge.label,
      ),
      <String>['Verifiziert', '4,9'],
    );
    final int statusSectionIndex = sheet.sections.indexWhere(
      (AppleLiquidSheetSection section) =>
          section.rows.first.type == AppleLiquidSheetRowType.timeline,
    );
    expect(
      sheet.sections.any(
        (AppleLiquidSheetSection section) =>
            section.title == 'Beteiligte Person',
      ),
      isFalse,
    );
    expect(statusSectionIndex, 1);
  });

  test('pending accepted job shows request state until it is confirmed', () {
    final ActivityCardData pendingActivity = _activity(
      sectionType: ActivitySectionType.running,
      chip: ActivityChip.jobAccepted,
      status: ActivityStatus.agreementPending,
    );
    final ActivityCardData confirmedActivity = _activity(
      sectionType: ActivitySectionType.running,
      chip: ActivityChip.jobAccepted,
      status: ActivityStatus.confirmed,
      statusHistory: const <ActivityStatusHistoryEntry>[
        ActivityStatusHistoryEntry(
          status: ActivityStatus.agreementPending,
          timestampText: 'Heute, 09:00',
        ),
      ],
    );

    final AppleLiquidSheetRow pendingIdentity = pendingActivity
        .toSheetContent(userProfile: _currentUser, onAction: (_, _) {})
        .sections
        .first
        .rows
        .single;
    final AppleLiquidSheetRow confirmedIdentity = confirmedActivity
        .toSheetContent(userProfile: _currentUser, onAction: (_, _) {})
        .sections
        .first
        .rows
        .single;

    expect(pendingIdentity.role, 'Helfer');
    expect(pendingIdentity.activityType, 'Anfrage gesendet');
    expect(confirmedIdentity.role, 'Helfer');
    expect(confirmedIdentity.activityType, 'Job angenommen');
  });
}

ActivityCardData _activity({
  required ActivitySectionType sectionType,
  required ActivityChip chip,
  required ActivityStatus status,
  String description = 'Testbeschreibung',
  List<ActivityStatusHistoryEntry> statusHistory =
      const <ActivityStatusHistoryEntry>[],
}) {
  return ActivityCardData(
    id: 'test-${sectionType.name}-${status.name}',
    sectionType: sectionType,
    title: 'Testaktivität',
    chip: chip,
    scheduleText: 'Heute, 14:00',
    compensationText: '20 €',
    locationText: '1 km entfernt',
    description: description,
    status: status,
    iconPath: 'briefcase.fill',
    statusHistory: statusHistory,
    contact: ActivityContactData(
      name: 'Mara König',
      nickname: 'MaraK',
      role: 'Kontakt',
      summary: 'Verifiziert · ★ 4,9',
    ),
  );
}
