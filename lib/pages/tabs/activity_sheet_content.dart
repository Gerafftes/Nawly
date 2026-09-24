import 'package:flutter/material.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';

import '../../models/activity_models.dart';
import '../../models/user_profile_models.dart';

const double _completedDetailsDetentHeight = 390;
const double _activitySheetDetentHeight = 560;
const double _descriptionDetailsDetentHeight = 300;
const int _descriptionPreviewLineLength = 40;

enum ActivitySheetAction {
  message,
  withdrawRequest,
  openRoute,
  reportCompletion,
  viewRequests,
  editJob,
  editService,
  pauseService,
  confirmCompletion,
  ratePerson,
  bookAgain,
  createSimilarJob,
}

extension ActivitySheetActionContent on ActivitySheetAction {
  String get label {
    switch (this) {
      case ActivitySheetAction.message:
        return 'Nachricht schreiben';
      case ActivitySheetAction.withdrawRequest:
        return 'Anfrage zurückziehen';
      case ActivitySheetAction.openRoute:
        return 'Route anzeigen';
      case ActivitySheetAction.reportCompletion:
        return 'Als fertig melden';
      case ActivitySheetAction.viewRequests:
        return 'Anfragen ansehen';
      case ActivitySheetAction.editJob:
        return 'Auftrag bearbeiten';
      case ActivitySheetAction.editService:
        return 'Service bearbeiten';
      case ActivitySheetAction.pauseService:
        return 'Service pausieren';
      case ActivitySheetAction.confirmCompletion:
        return 'Abschluss bestätigen';
      case ActivitySheetAction.ratePerson:
        return 'Person bewerten';
      case ActivitySheetAction.bookAgain:
        return 'Erneut buchen';
      case ActivitySheetAction.createSimilarJob:
        return 'Ähnlichen Auftrag erstellen';
    }
  }

  String labelFor(ActivityCardData activity) {
    if (this != ActivitySheetAction.message) {
      return label;
    }

    final String? contactName = activity.contact?.name.trim();
    if (contactName == null || contactName.isEmpty) {
      return label;
    }

    return '${contactName.split(RegExp(r'\s+')).first} schreiben';
  }

  bool get isDestructive => this == ActivitySheetAction.withdrawRequest;

  String get systemImage {
    switch (this) {
      case ActivitySheetAction.message:
        return 'message.fill';
      case ActivitySheetAction.withdrawRequest:
        return 'xmark.circle';
      case ActivitySheetAction.openRoute:
        return 'map.fill';
      case ActivitySheetAction.reportCompletion:
        return 'checkmark.circle.fill';
      case ActivitySheetAction.viewRequests:
        return 'person.2.fill';
      case ActivitySheetAction.editJob:
      case ActivitySheetAction.editService:
        return 'pencil';
      case ActivitySheetAction.pauseService:
        return 'pause.circle.fill';
      case ActivitySheetAction.confirmCompletion:
        return 'checkmark.seal.fill';
      case ActivitySheetAction.ratePerson:
        return 'star.fill';
      case ActivitySheetAction.bookAgain:
        return 'arrow.clockwise';
      case ActivitySheetAction.createSimilarJob:
        return 'plus.square.fill';
    }
  }
}

typedef ActivitySheetActionCallback =
    void Function(ActivityCardData activity, ActivitySheetAction action);

extension ActivityCardSheetContent on ActivityCardData {
  AppleLiquidSheetContent toSheetContent({
    required UserProfileSummaryData userProfile,
    required ActivitySheetActionCallback onAction,
  }) {
    final ActivityContactData? activityContact = contact;
    final List<ActivitySheetAction> actions = sheetActions;
    final ActivitySheetAction? primaryAction = actions.isEmpty
        ? null
        : actions.first;
    final List<ActivitySheetAction> secondaryActions = actions.length < 2
        ? const <ActivitySheetAction>[]
        : actions.sublist(1);
    final bool showsDetailsOnSeparatePage = status == ActivityStatus.completed;
    final AppleLiquidSheetSection detailsSection = _buildDetailsSection(
      showsTitle:
          !showsDetailsOnSeparatePage && detailsSectionTitle == 'Dein Angebot',
      showsDescriptionPreview: !showsDetailsOnSeparatePage,
    );
    final AppleLiquidSheetSection? participantSection = activityContact == null
        ? null
        : _buildParticipantSection(activityContact);

    return AppleLiquidSheetContent(
      title: title,
      detents: const AppleLiquidSheetDetents(
        initialHeight: _activitySheetDetentHeight,
        allowsAutomaticExpansion: false,
      ),
      doneSemanticLabel: 'Schließen',
      showsSectionBackgrounds: false,
      sectionSpacing: 6,
      trailingAction: const AppleLiquidSheetToolbarAction(
        systemImage: 'xmark',
        semanticLabel: 'Schließen',
        foregroundColor: Color(0xFFD6543D),
      ),
      sections: <AppleLiquidSheetSection>[
        AppleLiquidSheetSection(
          showsBackground: false,
          rows: <AppleLiquidSheetRow>[
            AppleLiquidSheetRow.identity(
              title: 'Du',
              role: userRole.label,
              activityType: identityActivityTypeLabel,
              systemImage: userProfile.avatarSystemImage,
              tintColor: const Color(0xFF007AFF),
              variant: AppleLiquidSheetIdentityVariant.composed,
              relatedPeople: activityContact == null
                  ? const <AppleLiquidSheetIdentityPerson>[]
                  : <AppleLiquidSheetIdentityPerson>[
                      _buildIdentityPerson(activityContact),
                    ],
            ),
          ],
        ),
        _activitySheetSection(
          rows: <AppleLiquidSheetRow>[
            AppleLiquidSheetRow.timeline(
              title: 'Aktueller Status',
              steps: timelineSteps,
              currentStepIndex: currentStatusIndex,
              collapsedStepLimit: 2,
              initiallyExpanded: false,
              expandLabel: 'Gesamten Ablauf anzeigen',
              collapseLabel: 'Weniger anzeigen',
              tintColor: const Color(0xFF007AFF),
            ),
            if (primaryAction != null)
              _buildActionRow(
                action: primaryAction,
                label: primaryAction.labelFor(this),
                isPrimary: true,
                isLast: true,
                onPressed: () => onAction(this, primaryAction),
              ),
          ],
        ),
        if (showsDetailsOnSeparatePage)
          _activitySheetSection(
            rows: <AppleLiquidSheetRow>[
              AppleLiquidSheetRow.navigation(
                title: 'Auftragsdetails',
                systemImage: 'doc.text.fill',
                chevronColor: const Color(0xFF007AFF),
                content: AppleLiquidSheetContent(
                  title: detailsSectionTitle,
                  detents: const AppleLiquidSheetDetents(
                    initialHeight: _completedDetailsDetentHeight,
                    allowsAutomaticExpansion: false,
                  ),
                  showsSectionBackgrounds: false,
                  sectionSpacing: 6,
                  sections: <AppleLiquidSheetSection>[
                    detailsSection,
                    ?participantSection,
                  ],
                ),
              ),
            ],
          )
        else
          detailsSection,
        if (secondaryActions.isNotEmpty)
          AppleLiquidSheetSection(
            showsBackground: false,
            rows: <AppleLiquidSheetRow>[
              for (int index = 0; index < secondaryActions.length; index += 1)
                _buildActionRow(
                  action: secondaryActions[index],
                  label: secondaryActions[index].labelFor(this),
                  isPrimary: false,
                  isLast: index == secondaryActions.length - 1,
                  onPressed: () => onAction(this, secondaryActions[index]),
                ),
            ],
          ),
      ],
    );
  }

  int get currentStatusIndex => chip.statusPath.indexOf(status);

  List<AppleLiquidSheetTimelineStep> get timelineSteps {
    final Map<ActivityStatus, String> timestamps = <ActivityStatus, String>{
      for (final ActivityStatusHistoryEntry entry in statusHistory)
        entry.status: entry.timestampText,
    };

    return chip.statusPath
        .map(
          (ActivityStatus step) => AppleLiquidSheetTimelineStep(
            title: step.labelFor(chip),
            subtitle: step == status ? statusDescription : timestamps[step],
            systemImage: step.iconPath,
          ),
        )
        .toList(growable: false);
  }

  String get statusDescription {
    switch (status) {
      case ActivityStatus.agreementPending:
        switch (chip) {
          case ActivityChip.jobAccepted:
            return 'Deine Anfrage liegt beim Auftraggeber.';
          case ActivityChip.serviceBooked:
            return 'Deine Buchungsanfrage liegt beim Anbieter.';
          case ActivityChip.serviceBookedWithYou:
            return 'Du hast eine neue Buchungsanfrage erhalten.';
          case ActivityChip.jobCreated:
          case ActivityChip.serviceOffered:
          case ActivityChip.jobCompletedByYou:
            return 'Warten auf Antwort.';
        }
      case ActivityStatus.confirmed:
        switch (chip) {
          case ActivityChip.jobAccepted:
            return 'Der Auftrag ist bestätigt.';
          case ActivityChip.serviceBooked:
            return 'Die Buchung ist bestätigt.';
          case ActivityChip.serviceBookedWithYou:
            return 'Die Buchung ist bestätigt.';
          case ActivityChip.jobCreated:
          case ActivityChip.serviceOffered:
          case ActivityChip.jobCompletedByYou:
            return 'Der Auftrag ist verbindlich bestätigt.';
        }
      case ActivityStatus.inProgress:
        switch (chip) {
          case ActivityChip.jobAccepted:
            return 'Der Auftrag läuft.';
          case ActivityChip.serviceBooked:
            return 'Der Service läuft.';
          case ActivityChip.serviceBookedWithYou:
            return 'Der Service läuft.';
          case ActivityChip.jobCreated:
            return 'Der ausgewählte Helfer bearbeitet deinen Auftrag.';
          case ActivityChip.serviceOffered:
            return 'Dein Service ist sichtbar und kann gebucht werden.';
          case ActivityChip.jobCompletedByYou:
            return 'Der Auftrag läuft.';
        }
      case ActivityStatus.completionReported:
        if (chip == ActivityChip.serviceBooked) {
          return 'Der Anbieter hat den Abschluss gemeldet.';
        }
        return 'Du hast den Abschluss gemeldet.';
      case ActivityStatus.helperNeeded:
        return 'Dein Auftrag ist sichtbar und kann angefragt werden.';
      case ActivityStatus.completionConfirmation:
        return 'Der Helfer hat den Abschluss gemeldet.';
      case ActivityStatus.completed:
        return 'Die Aktivität wurde erfolgreich abgeschlossen.';
    }
  }

  String get detailsSectionTitle {
    return chip == ActivityChip.serviceOffered ? 'Dein Angebot' : 'Auftrag';
  }

  AppleLiquidSheetSection _buildDetailsSection({
    required bool showsTitle,
    required bool showsDescriptionPreview,
  }) {
    return _activitySheetSection(
      title: showsTitle ? detailsSectionTitle : null,
      rows: <AppleLiquidSheetRow>[
        AppleLiquidSheetRow.factsGrid(
          title: 'Auf einen Blick',
          columns: 3,
          tintColor: const Color(0xFF007AFF),
          facts: <AppleLiquidSheetFact>[
            AppleLiquidSheetFact(
              label: scheduleLabel,
              value: scheduleText,
              systemImage: 'calendar',
            ),
            AppleLiquidSheetFact(
              label: locationLabel,
              value: locationValue,
              systemImage: 'mappin.and.ellipse',
            ),
            AppleLiquidSheetFact(
              label: compensationLabel,
              value: compensationText,
              systemImage: 'eurosign.circle',
            ),
          ],
        ),
        if (showsDescriptionPreview)
          _buildDescriptionPreviewRow()
        else
          AppleLiquidSheetRow.text(
            title: 'Beschreibung',
            subtitle: description,
            systemImage: 'text.alignleft',
          ),
      ],
    );
  }

  AppleLiquidSheetRow _buildDescriptionPreviewRow() {
    return AppleLiquidSheetRow.navigation(
      title: 'Beschreibung',
      subtitle: _descriptionPreview,
      systemImage: 'text.alignleft',
      chevronColor: const Color(0xFF007AFF),
      content: AppleLiquidSheetContent(
        title: 'Beschreibung',
        detents: const AppleLiquidSheetDetents(
          initialHeight: _descriptionDetailsDetentHeight,
          allowsAutomaticExpansion: false,
        ),
        showsSectionBackgrounds: false,
        sectionSpacing: 6,
        sections: <AppleLiquidSheetSection>[
          _activitySheetSection(
            rows: <AppleLiquidSheetRow>[
              AppleLiquidSheetRow.text(
                title: 'Beschreibung',
                subtitle: description,
                systemImage: 'text.alignleft',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _descriptionPreview {
    final String normalized = description
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.length <= _descriptionPreviewLineLength) {
      return normalized;
    }

    final List<String> lines = <String>[];
    String remaining = normalized;
    while (lines.length < 2 && remaining.isNotEmpty) {
      if (remaining.length <= _descriptionPreviewLineLength) {
        lines.add(remaining);
        remaining = '';
        break;
      }

      int breakAt = remaining.lastIndexOf(' ', _descriptionPreviewLineLength);
      if (breakAt <= 0) {
        breakAt = _descriptionPreviewLineLength;
      }
      lines.add(remaining.substring(0, breakAt).trimRight());
      remaining = remaining.substring(breakAt).trimLeft();
    }

    if (remaining.isNotEmpty && lines.isNotEmpty) {
      final String lastLine = lines.last;
      final int maxLastLineLength = _descriptionPreviewLineLength - 1;
      final String shortenedLastLine = lastLine.length > maxLastLineLength
          ? lastLine.substring(0, maxLastLineLength).trimRight()
          : lastLine;
      lines[lines.length - 1] = '$shortenedLastLine…';
    }

    return lines.join('\n');
  }

  AppleLiquidSheetSection _buildParticipantSection(
    ActivityContactData activityContact,
  ) {
    return _activitySheetSection(
      title: 'Beteiligte Person',
      rows: <AppleLiquidSheetRow>[
        AppleLiquidSheetRow.text(
          title: activityContact.name,
          subtitle: '${activityContact.role} · ${activityContact.summary}',
          systemImage: activityContact.avatarSystemImage,
        ),
      ],
    );
  }

  String get scheduleLabel {
    return chip == ActivityChip.serviceOffered ? 'Verfügbarkeit' : 'Termin';
  }

  String get locationLabel {
    if (chip == ActivityChip.serviceOffered) {
      return 'Gebiet';
    }
    return RegExp(r'\bkm\b').hasMatch(locationText) ? 'Entfernung' : 'Ort';
  }

  String get locationValue {
    if (locationLabel != 'Entfernung') {
      return locationText;
    }
    return locationText.replaceFirst(RegExp(r'\s+entfernt$'), '');
  }

  String get compensationLabel {
    if (chip == ActivityChip.serviceOffered ||
        userRole == ActivityUserRole.customer ||
        userRole == ActivityUserRole.client) {
      return 'Preis';
    }
    return 'Verdienst';
  }

  List<ActivitySheetAction> get sheetActions {
    switch (status) {
      case ActivityStatus.agreementPending:
        return const <ActivitySheetAction>[
          ActivitySheetAction.message,
          ActivitySheetAction.withdrawRequest,
        ];
      case ActivityStatus.confirmed:
        return const <ActivitySheetAction>[
          ActivitySheetAction.message,
          ActivitySheetAction.openRoute,
        ];
      case ActivityStatus.inProgress:
        switch (chip) {
          case ActivityChip.jobAccepted:
          case ActivityChip.serviceBookedWithYou:
          case ActivityChip.jobCompletedByYou:
            return const <ActivitySheetAction>[
              ActivitySheetAction.reportCompletion,
              ActivitySheetAction.message,
            ];
          case ActivityChip.jobCreated:
          case ActivityChip.serviceBooked:
            return const <ActivitySheetAction>[
              ActivitySheetAction.message,
              ActivitySheetAction.openRoute,
            ];
          case ActivityChip.serviceOffered:
            return const <ActivitySheetAction>[
              ActivitySheetAction.editService,
              ActivitySheetAction.pauseService,
            ];
        }
      case ActivityStatus.completionReported:
        if (chip == ActivityChip.serviceBooked) {
          return const <ActivitySheetAction>[
            ActivitySheetAction.confirmCompletion,
            ActivitySheetAction.message,
          ];
        }
        return const <ActivitySheetAction>[ActivitySheetAction.message];
      case ActivityStatus.helperNeeded:
        return const <ActivitySheetAction>[
          ActivitySheetAction.viewRequests,
          ActivitySheetAction.editJob,
        ];
      case ActivityStatus.completionConfirmation:
        return const <ActivitySheetAction>[
          ActivitySheetAction.confirmCompletion,
          ActivitySheetAction.message,
        ];
      case ActivityStatus.completed:
        switch (chip) {
          case ActivityChip.serviceBooked:
            return const <ActivitySheetAction>[
              ActivitySheetAction.ratePerson,
              ActivitySheetAction.bookAgain,
            ];
          case ActivityChip.jobCreated:
            return const <ActivitySheetAction>[
              ActivitySheetAction.ratePerson,
              ActivitySheetAction.createSimilarJob,
            ];
          case ActivityChip.jobCompletedByYou:
          case ActivityChip.serviceBookedWithYou:
            return const <ActivitySheetAction>[ActivitySheetAction.ratePerson];
          case ActivityChip.jobAccepted:
          case ActivityChip.serviceOffered:
            return const <ActivitySheetAction>[];
        }
    }
  }
}

AppleLiquidSheetIdentityPerson _buildIdentityPerson(
  ActivityContactData contact,
) {
  return AppleLiquidSheetIdentityPerson(
    title: contact.name,
    subtitle: contact.role,
    systemImage: contact.avatarSystemImage,
    badges: _buildIdentityBadges(contact.summary),
  );
}

List<AppleLiquidSheetIdentityBadge> _buildIdentityBadges(String summary) {
  final List<String> metadata = summary
      .split(' · ')
      .map((String value) => value.trim())
      .where((String value) => value.isNotEmpty)
      .toList(growable: false);

  return metadata
      .map((String value) {
        if (value == 'Verifiziert') {
          return const AppleLiquidSheetIdentityBadge(
            label: 'Verifiziert',
            systemImage: 'checkmark.seal.fill',
            foregroundColor: Color(0xFF34C759),
          );
        }

        if (value.startsWith('★ ')) {
          return AppleLiquidSheetIdentityBadge(
            label: value.substring(2),
            systemImage: 'star.fill',
            foregroundColor: const Color(0xFFFFCC00),
          );
        }

        return AppleLiquidSheetIdentityBadge(label: value);
      })
      .toList(growable: false);
}

AppleLiquidSheetSection _activitySheetSection({
  String? title,
  required List<AppleLiquidSheetRow> rows,
}) {
  return AppleLiquidSheetSection(
    title: title,
    titleColor: const Color(0xFFE6E6E6),
    titleHorizontalInset: 16,
    titleSpacing: 2,
    showsBackground: false,
    rows: rows,
  );
}

AppleLiquidSheetRow _buildActionRow({
  required ActivitySheetAction action,
  required String label,
  required bool isPrimary,
  required bool isLast,
  required VoidCallback onPressed,
}) {
  final bool isDestructive = action.isDestructive;
  final double rowTopInset = isPrimary ? 8 : (isDestructive ? 4 : 0);
  final Color tintColor = isDestructive
      ? const Color(0xFFD6543D)
      : isPrimary
      ? const Color(0xFF007AFF)
      : const Color(0xFF8E8E93);

  return AppleLiquidSheetRow.button(
    title: label,
    systemImage: action.systemImage,
    tintColor: tintColor,
    semanticLabel: label,
    style: AppleLiquidSheetButtonStyle(
      backgroundColor: isDestructive
          ? const Color(0x26D6543D)
          : isPrimary
          ? const Color(0xFF007AFF)
          : const Color(0xFF0D0D0D),
      foregroundColor: isDestructive
          ? const Color(0xFFD6543D)
          : const Color(0xFFF2F2F2),
      borderColor: isDestructive
          ? const Color(0xFFD6543D)
          : isPrimary
          ? const Color(0xFF007AFF)
          : const Color(0xFF2C2C2E),
      buttonHeight: 54,
      rowHorizontalInset: 16,
      rowTopInset: rowTopInset,
      rowBottomInset: isLast ? 4 : 0,
    ),
    onPressed: onPressed,
  );
}
