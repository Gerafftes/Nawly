import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';

import '../../data/activity_demo_repository.dart';
import '../../data/activity_repository.dart';
import '../../models/activity_models.dart';
import '../../services/sf_symbol_helper.dart';
import '../../services/ui_scale.dart';

class ActivityTabContent extends StatefulWidget {
  const ActivityTabContent({
    super.key,
    required this.jobCardColor,
    this.activityRepository = const ActivityDemoRepository(),
  });

  final Color jobCardColor;
  final ActivityRepository activityRepository;

  @override
  State<ActivityTabContent> createState() => _ActivityTabContentState();
}

const String _runningSectionId = 'running';
const String _createdSectionId = 'created';
const String _completedForOthersSectionId = 'completedForOthers';
const String _completedForYouSectionId = 'completedForYou';

extension _ActivityCardSheetContent on ActivityCardData {
  AppleLiquidSheetContent toSheetContent() {
    return AppleLiquidSheetContent(
      title: title,
      doneSemanticLabel: 'Schließen',
      leadingAction: const AppleLiquidSheetToolbarAction(
        systemImage: 'xmark',
        semanticLabel: 'Schließen',
        foregroundColor: Color(0xFFF2F2F2),
      ),
      trailingAction: const AppleLiquidSheetToolbarAction(
        systemImage: 'checkmark',
        semanticLabel: 'Schließen',
        foregroundColor: Color(0xFFFFFFFF),
        backgroundColor: Color(0xFF007AFF),
      ),
      sections: <AppleLiquidSheetSection>[
        AppleLiquidSheetSection(
          title: 'Status',
          rows: <AppleLiquidSheetRow>[
            AppleLiquidSheetRow.value(title: 'Aktivität', value: title),
            AppleLiquidSheetRow.value(title: 'Status', value: chip.label),
            AppleLiquidSheetRow.value(
              title: 'Fortschritt',
              value: status.label,
              systemImage: status.iconPath,
            ),
          ],
        ),
        AppleLiquidSheetSection(
          title: 'Details',
          rows: <AppleLiquidSheetRow>[
            AppleLiquidSheetRow.value(
              title: 'Termin',
              value: metaText,
              systemImage: 'calendar',
            ),
            const AppleLiquidSheetRow.text(
              title: 'Platzhalter',
              subtitle: 'Hier bauen wir gleich den Detailinhalt auf.',
            ),
          ],
        ),
      ],
    );
  }
}

class _ActivityTabContentState extends State<ActivityTabContent> {
  final AppleLiquidSheetController _activitySheetController =
      AppleLiquidSheetController();

  late final Future<List<ActivitySectionData>> _sectionsFuture;

  bool _isLaufendSelected = true;
  bool _isLaufendSectionExpanded = true;
  bool _isCreatedSectionExpanded = true;
  bool _isCompletedForOthersExpanded = true;
  bool _isCompletedForYouExpanded = true;

  @override
  void initState() {
    super.initState();
    _sectionsFuture = widget.activityRepository.loadSections();
  }

  @override
  void dispose() {
    _activitySheetController.dispose();
    super.dispose();
  }

  Future<void> _showActivitySheet(AppleLiquidSheetContent content) async {
    await _activitySheetController.showSheet(content: content);
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;

    double h(double percent) => screenHeight * percent;
    double s(double value) => ui.s(value);

    final double cornerRadius = screenWidth * 0.04;
    const double minTapTarget = 44;
    const Duration sectionToggleDuration = Duration(milliseconds: 180);
    final double toggleButtonHeight = math.max(minTapTarget, h(0.05));

    Widget activitySegmentButton({
      required String label,
      required bool isSelected,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: toggleButtonHeight,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1A1A1A)
                  : const Color(0xFF0D0D0D),
              borderRadius: BorderRadius.circular(cornerRadius),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color.fromRGBO(255, 255, 255, 0.04),
                        blurRadius: s(8),
                        offset: Offset(0, s(2)),
                      ),
                    ]
                  : [],
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFF2F2F2),
                fontSize: s(15),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    Widget sectionHeader({
      required String title,
      required bool isExpanded,
      required VoidCallback onTap,
    }) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: const Color(0xFFF2F2F2),
                fontSize: s(17),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: s(20)),
            AnimatedRotation(
              turns: isExpanded ? 0.25 : 0,
              duration: sectionToggleDuration,
              curve: Curves.easeInOut,
              child: SFSymbolHelper.getChevronRight(
                color: const Color(0xFFF2F2F2),
                size: s(26),
              ),
            ),
          ],
        ),
      );
    }

    Widget activityCard(ActivityCardData data) {
      final double titleFontSize = s(17);
      final double chipFontSize = s(12);
      final double metaFontSize = s(13.5);
      final double progressFontSize = s(13.5);
      final double chipVerticalPadding = s(5);
      final double cardHeight =
          s(8) +
          titleFontSize +
          s(5) +
          chipFontSize +
          (chipVerticalPadding * 2) +
          s(8) +
          metaFontSize +
          s(1) +
          progressFontSize +
          s(11);

      final Widget card = Container(
        width: double.infinity,
        height: cardHeight,
        decoration: BoxDecoration(
          color: widget.jobCardColor,
          borderRadius: BorderRadius.circular(s(15)),
        ),
        child: Stack(
          children: [
            Positioned(
              top: s(8),
              left: s(8),
              child: Container(
                width: s(52),
                height: s(52),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(s(7)),
                ),
                child: Center(
                  child: SFSymbolHelper.getIcon(
                    iconPath: data.iconPath,
                    width: s(30),
                    height: s(30),
                    color: const Color(0xFFF2F2F2),
                  ),
                ),
              ),
            ),
            Positioned(
              left: s(75),
              right: data.showsVisibilityBadge ? s(155) : s(58),
              top: s(8),
              child: Align(
                alignment: Alignment.topLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textHeightBehavior: const TextHeightBehavior(
                        applyHeightToFirstAscent: false,
                        applyHeightToLastDescent: false,
                      ),
                      style: TextStyle(
                        color: const Color(0xFFF2F2F2),
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: s(5)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: s(10),
                        vertical: chipVerticalPadding,
                      ),
                      decoration: BoxDecoration(
                        color: HSLColor.fromAHSL(0.3, 211, 1.0, 0.50).toColor(),
                        borderRadius: BorderRadius.circular(s(100)),
                      ),
                      child: Text(
                        data.chip.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        strutStyle: StrutStyle(
                          fontSize: chipFontSize,
                          height: 1,
                          forceStrutHeight: true,
                        ),
                        style: TextStyle(
                          color: const Color(0xFF4DAAFC),
                          fontSize: chipFontSize,
                          fontWeight: FontWeight.w400,
                          height: 1,
                        ),
                      ),
                    ),
                    SizedBox(height: s(8)),
                    Text(
                      data.metaText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFFB3B3B3),
                        fontSize: metaFontSize,
                        fontWeight: FontWeight.normal,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: s(1)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SFSymbolHelper.getIcon(
                          iconPath: data.status.iconPath,
                          width: s(10),
                          height: s(10),
                          color: const Color(0xFF64D2FF),
                        ),
                        SizedBox(width: s(8)),
                        Flexible(
                          child: Text(
                            data.status.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF64D2FF),
                              fontSize: progressFontSize,
                              fontWeight: FontWeight.normal,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (data.showsVisibilityBadge)
              Positioned(
                top: s(12),
                right: s(25),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SFSymbolHelper.getIcon(
                      iconPath: 'antenna.radiowaves.left.and.right',
                      width: s(13.5),
                      height: s(13.5),
                      color: const Color(0xFF04C40A),
                      weight: AppleLiquidSymbolWeight.semibold,
                    ),
                    SizedBox(width: s(10)),
                    Text(
                      'Sichtbar',
                      style: TextStyle(
                        color: const Color(0xFF04C40A),
                        fontSize: s(13.5),
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            Positioned(
              right: s(24),
              top: 0,
              bottom: 0,
              child: Center(
                child: SFSymbolHelper.getChevronRight(
                  color: const Color(0xFFF2F2F2),
                  size: s(26),
                ),
              ),
            ),
          ],
        ),
      );

      return _SwipeRevealCard(
        key: ValueKey<String>(
          'activity-card-${data.title}-${data.chip.label}-${data.status.label}',
        ),
        height: cardHeight,
        onTap: () {
          _showActivitySheet(data.toSheetContent());
        },
        child: card,
      );
    }

    Widget sectionCards({
      required ActivitySectionData section,
      required bool isExpanded,
    }) {
      assert(
        section.cards.every(
          (ActivityCardData card) =>
              section.availableStates.contains(card.status),
        ),
      );

      final List<Widget> children = <Widget>[SizedBox(height: s(17))];
      for (int index = 0; index < section.cards.length; index += 1) {
        children.add(activityCard(section.cards[index]));
        if (index < section.cards.length - 1) {
          children.add(SizedBox(height: s(12)));
        }
      }

      return ClipRect(
        child: AnimatedSize(
          duration: sectionToggleDuration,
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: double.infinity,
            child: AnimatedOpacity(
              duration: sectionToggleDuration,
              curve: Curves.easeInOut,
              opacity: isExpanded ? 1 : 0,
              child: isExpanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ),
        ),
      );
    }

    Widget loadError() {
      return Padding(
        padding: EdgeInsets.only(top: s(26)),
        child: Text(
          'Aktivitäten konnten nicht geladen werden.',
          style: TextStyle(
            color: const Color(0xFFB3B3B3),
            fontSize: s(15),
            fontWeight: FontWeight.w400,
          ),
        ),
      );
    }

    Widget sectionContent(List<ActivitySectionData> sections) {
      final Map<String, ActivitySectionData> sectionById =
          <String, ActivitySectionData>{
            for (final ActivitySectionData section in sections)
              section.id: section,
          };

      final ActivitySectionData? runningSection =
          sectionById[_runningSectionId];
      final ActivitySectionData? createdSection =
          sectionById[_createdSectionId];
      final ActivitySectionData? completedForOthersSection =
          sectionById[_completedForOthersSectionId];
      final ActivitySectionData? completedForYouSection =
          sectionById[_completedForYouSectionId];

      if (runningSection == null ||
          createdSection == null ||
          completedForOthersSection == null ||
          completedForYouSection == null) {
        return loadError();
      }

      if (_isLaufendSelected) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: s(26)),
            sectionHeader(
              title: runningSection.title,
              isExpanded: _isLaufendSectionExpanded,
              onTap: () {
                setState(() {
                  _isLaufendSectionExpanded = !_isLaufendSectionExpanded;
                });
              },
            ),
            sectionCards(
              section: runningSection,
              isExpanded: _isLaufendSectionExpanded,
            ),
            SizedBox(height: s(23)),
            sectionHeader(
              title: createdSection.title,
              isExpanded: _isCreatedSectionExpanded,
              onTap: () {
                setState(() {
                  _isCreatedSectionExpanded = !_isCreatedSectionExpanded;
                });
              },
            ),
            sectionCards(
              section: createdSection,
              isExpanded: _isCreatedSectionExpanded,
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: s(26)),
          sectionHeader(
            title: completedForOthersSection.title,
            isExpanded: _isCompletedForOthersExpanded,
            onTap: () {
              setState(() {
                _isCompletedForOthersExpanded = !_isCompletedForOthersExpanded;
              });
            },
          ),
          sectionCards(
            section: completedForOthersSection,
            isExpanded: _isCompletedForOthersExpanded,
          ),
          SizedBox(height: s(23)),
          sectionHeader(
            title: completedForYouSection.title,
            isExpanded: _isCompletedForYouExpanded,
            onTap: () {
              setState(() {
                _isCompletedForYouExpanded = !_isCompletedForYouExpanded;
              });
            },
          ),
          sectionCards(
            section: completedForYouSection,
            isExpanded: _isCompletedForYouExpanded,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: s(26)),
        Row(
          children: [
            activitySegmentButton(
              label: 'Aktiv',
              isSelected: _isLaufendSelected,
              onTap: () {
                setState(() {
                  _isLaufendSelected = true;
                });
              },
            ),
            SizedBox(width: screenWidth * 0.02),
            activitySegmentButton(
              label: 'Abgeschlossen',
              isSelected: !_isLaufendSelected,
              onTap: () {
                setState(() {
                  _isLaufendSelected = false;
                });
              },
            ),
          ],
        ),
        FutureBuilder<List<ActivitySectionData>>(
          future: _sectionsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return loadError();
            }

            final List<ActivitySectionData>? sections = snapshot.data;
            if (sections == null) {
              return SizedBox(height: s(26));
            }

            return sectionContent(sections);
          },
        ),
      ],
    );
  }
}

class _SwipeRevealCard extends StatefulWidget {
  const _SwipeRevealCard({
    super.key,
    required this.height,
    required this.onTap,
    required this.child,
  });

  final double height;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_SwipeRevealCard> createState() => _SwipeRevealCardState();
}

class _SwipeRevealCardState extends State<_SwipeRevealCard> {
  static const Duration _snapDuration = Duration(milliseconds: 280);
  static const Curve _snapCurve = Curves.easeOutCubic;

  double _dragExtent = 0;
  bool _isDragging = false;
  bool _didTriggerFullSwipeHaptic = false;
  bool _didTriggerSwipeAction = false;

  void _resetSwipeFeedback() {
    _didTriggerFullSwipeHaptic = false;
    _didTriggerSwipeAction = false;
  }

  void _triggerFullSwipeHaptic() {
    if (_didTriggerFullSwipeHaptic) {
      return;
    }

    _didTriggerFullSwipeHaptic = true;
    HapticFeedback.mediumImpact();
  }

  void _setDragExtent(double value, double revealWidth) {
    final double nextDragExtent = value.clamp(0.0, revealWidth).toDouble();

    if (nextDragExtent == _dragExtent) {
      return;
    }

    setState(() {
      _dragExtent = nextDragExtent;

      if (_dragExtent == 0) {
        _resetSwipeFeedback();
      }
    });

    if (nextDragExtent == revealWidth) {
      _triggerFullSwipeHaptic();
    }
  }

  void _triggerSwipeAction() {
    if (_didTriggerSwipeAction) {
      return;
    }

    _didTriggerSwipeAction = true;
    _triggerFullSwipeHaptic();

    Future<void>.delayed(const Duration(milliseconds: 90), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _dragExtent = 0;
        _resetSwipeFeedback();
      });

      widget.onTap();
    });
  }

  void _finishDrag(double revealWidth, double velocity) {
    final bool isIntentionalFling =
        velocity < -800 && _dragExtent > revealWidth * 0.35;
    final bool shouldTriggerAction =
        isIntentionalFling || _dragExtent > revealWidth * 0.72;

    setState(() {
      _isDragging = false;
      _dragExtent = shouldTriggerAction ? revealWidth : 0;

      if (!shouldTriggerAction) {
        _resetSwipeFeedback();
      }
    });

    if (shouldTriggerAction) {
      _triggerSwipeAction();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);
    final double actionGap = ui.s(8);
    final double actionWidth = ui.s(118);
    final double revealWidth = actionGap + actionWidth;
    final double maxActionHeight = math.max(ui.s(64), widget.height - ui.s(16));
    final double actionBubbleWidth = (_dragExtent - actionGap)
        .clamp(0.0, actionWidth)
        .toDouble();
    final double actionProgress = actionBubbleWidth / actionWidth;
    final double easedActionProgress = Curves.easeOutCubic.transform(
      actionProgress,
    );
    final double actionBubbleHeight =
        ui.s(34) + ((maxActionHeight - ui.s(34)) * easedActionProgress);
    final double actionTextOpacity = ((actionProgress - 0.72) / 0.28)
        .clamp(0.0, 1.0)
        .toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = constraints.maxWidth;

        return SizedBox(
          width: double.infinity,
          height: widget.height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            onHorizontalDragStart: (_) {
              setState(() {
                _isDragging = true;
              });
            },
            onHorizontalDragUpdate: (details) {
              _setDragExtent(_dragExtent - details.delta.dx, revealWidth);
            },
            onHorizontalDragEnd: (details) {
              _finishDrag(revealWidth, details.primaryVelocity ?? 0);
            },
            onHorizontalDragCancel: () {
              _finishDrag(revealWidth, 0);
            },
            child: ClipRect(
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    width: revealWidth,
                    height: widget.height,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: AnimatedContainer(
                        duration: _isDragging ? Duration.zero : _snapDuration,
                        curve: _snapCurve,
                        width: actionBubbleWidth,
                        height: actionBubbleHeight,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(ui.s(30)),
                        ),
                        child: actionTextOpacity == 0
                            ? const SizedBox.shrink()
                            : ClipRect(
                                child: Opacity(
                                  opacity: actionTextOpacity,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: ui.s(10),
                                      ),
                                      child: Text(
                                        'Bearbeiten',
                                        maxLines: 1,
                                        softWrap: false,
                                        style: TextStyle(
                                          color: const Color(0xFFF2F2F2),
                                          fontSize: ui.s(16),
                                          fontWeight: FontWeight.w600,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    width: cardWidth,
                    height: widget.height,
                    child: AnimatedContainer(
                      duration: _isDragging ? Duration.zero : _snapDuration,
                      curve: _snapCurve,
                      transform: Matrix4.translationValues(-_dragExtent, 0, 0),
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
