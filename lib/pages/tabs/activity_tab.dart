import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';

import '../../services/sf_symbol_helper.dart';
import '../../services/ui_scale.dart';

class ActivityTabContent extends StatefulWidget {
  const ActivityTabContent({super.key, required this.jobCardColor});

  final Color jobCardColor;

  @override
  State<ActivityTabContent> createState() => _ActivityTabContentState();
}

class _ActivityTabContentState extends State<ActivityTabContent> {
  final AppleLiquidSheetController _activitySheetController =
      AppleLiquidSheetController();

  bool _isLaufendSelected = true;
  bool _isLaufendSectionExpanded = true;
  bool _isCreatedSectionExpanded = true;

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

    Widget emptyActivityCard({
      required String iconPath,
      required String title,
      required String statusText,
      required String metaText,
      required String progressIconPath,
      required String progressText,
    }) {
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
                    iconPath: iconPath,
                    width: s(30),
                    height: s(30),
                    color: const Color(0xFFF2F2F2),
                  ),
                ),
              ),
            ),
            Positioned(
              left: s(75),
              right: s(58),
              top: s(8),
              child: Align(
                alignment: Alignment.topLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
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
                        statusText,
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
                      metaText,
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
                          iconPath: progressIconPath,
                          width: s(10),
                          height: s(10),
                          color: const Color(0xFF64D2FF),
                        ),
                        SizedBox(width: s(8)),
                        Text(
                          progressText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF64D2FF),
                            fontSize: progressFontSize,
                            fontWeight: FontWeight.normal,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
        key: ValueKey<String>('activity-card-$title'),
        height: cardHeight,
        onTap: () {
          _showActivitySheet(
            AppleLiquidSheetContent(
              title: title,
              doneSemanticLabel: 'Schließen',
              sections: <AppleLiquidSheetSection>[
                AppleLiquidSheetSection(
                  title: 'Status',
                  rows: <AppleLiquidSheetRow>[
                    AppleLiquidSheetRow.value(title: 'Aktivität', value: title),
                    AppleLiquidSheetRow.value(
                      title: 'Status',
                      value: statusText,
                    ),
                    AppleLiquidSheetRow.value(
                      title: 'Fortschritt',
                      value: progressText,
                      systemImage: progressIconPath,
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
            ),
          );
        },
        child: card,
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
        if (_isLaufendSelected) ...[
          SizedBox(height: s(26)),
          sectionHeader(
            title: 'Laufend',
            isExpanded: _isLaufendSectionExpanded,
            onTap: () {
              setState(() {
                _isLaufendSectionExpanded = !_isLaufendSectionExpanded;
              });
            },
          ),
          ClipRect(
            child: AnimatedSize(
              duration: sectionToggleDuration,
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: double.infinity,
                child: AnimatedOpacity(
                  duration: sectionToggleDuration,
                  curve: Curves.easeInOut,
                  opacity: _isLaufendSectionExpanded ? 1 : 0,
                  child: _isLaufendSectionExpanded
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: s(17)),
                            emptyActivityCard(
                              iconPath: 'assets/icons/briefcase.fill.svg',
                              title: 'Gassi gehen',
                              statusText: 'Job von dir angenommen',
                              metaText: 'Heute, 14:00 · 15€',
                              progressIconPath: 'alarm.fill',
                              progressText: 'In Arbeit',
                            ),
                            SizedBox(height: s(12)),
                            emptyActivityCard(
                              iconPath:
                                  'assets/icons/list.bullet.rectangle.portrait.fill.svg',
                              title: 'Nachhilfe',
                              statusText: 'Service von dir gebucht',
                              metaText: 'Heute, 15:00 – 17:00 · 40€',
                              progressIconPath: 'hourglass',
                              progressText: 'Warte auf Abschluss',
                            ),
                          ],
                        )
                      : const SizedBox(width: double.infinity, height: 0),
                ),
              ),
            ),
          ),
          SizedBox(height: s(23)),
          sectionHeader(
            title: 'Von dir erstellt',
            isExpanded: _isCreatedSectionExpanded,
            onTap: () {
              setState(() {
                _isCreatedSectionExpanded = !_isCreatedSectionExpanded;
              });
            },
          ),
          ClipRect(
            child: AnimatedSize(
              duration: sectionToggleDuration,
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _isCreatedSectionExpanded
                  ? const SizedBox.shrink()
                  : const SizedBox.shrink(),
            ),
          ),
        ],
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
  static const Duration _snapDuration = Duration(milliseconds: 180);

  double _dragExtent = 0;
  bool _isDragging = false;
  bool _didTriggerFullSwipeHaptic = false;

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
        _didTriggerFullSwipeHaptic = false;
      }
    });

    if (nextDragExtent == revealWidth) {
      _triggerFullSwipeHaptic();
    }
  }

  void _finishDrag(double revealWidth, double velocity) {
    final bool shouldOpen =
        velocity < -350 ||
        (velocity.abs() <= 350 && _dragExtent > revealWidth * 0.35);

    setState(() {
      _isDragging = false;
      _dragExtent = shouldOpen ? revealWidth : 0;

      if (!shouldOpen) {
        _didTriggerFullSwipeHaptic = false;
      }
    });

    if (shouldOpen) {
      _triggerFullSwipeHaptic();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);
    final double actionGap = ui.s(8);
    final double actionWidth = ui.s(118);
    final double revealWidth = actionGap + actionWidth;
    final double actionHeight = math.max(ui.s(64), widget.height - ui.s(16));

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
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    width: cardWidth + revealWidth,
                    height: widget.height,
                    child: AnimatedContainer(
                      duration: _isDragging ? Duration.zero : _snapDuration,
                      curve: Curves.easeOutCubic,
                      transform: Matrix4.translationValues(-_dragExtent, 0, 0),
                      child: Row(
                        children: [
                          SizedBox(width: cardWidth, child: widget.child),
                          SizedBox(width: actionGap),
                          SizedBox(
                            width: actionWidth,
                            height: widget.height,
                            child: Center(
                              child: Container(
                                width: actionWidth,
                                height: actionHeight,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(ui.s(30)),
                                ),
                                child: Text(
                                  'Bearbeiten',
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
                        ],
                      ),
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
