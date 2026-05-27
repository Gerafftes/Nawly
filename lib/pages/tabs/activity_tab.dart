import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/sf_symbol_helper.dart';
import '../../services/ui_scale.dart';

class ActivityTabContent extends StatefulWidget {
  const ActivityTabContent({super.key, required this.jobCardColor});

  final Color jobCardColor;

  @override
  State<ActivityTabContent> createState() => _ActivityTabContentState();
}

class _ActivityTabContentState extends State<ActivityTabContent> {
  bool _isLaufendSelected = true;

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

      return Container(
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Laufend',
                style: TextStyle(
                  color: const Color(0xFFF2F2F2),
                  fontSize: s(17),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: s(20)),
              SFSymbolHelper.getChevronRight(
                color: const Color(0xFFF2F2F2),
                size: s(26),
              ),
            ],
          ),
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
            iconPath: 'assets/icons/list.bullet.rectangle.portrait.fill.svg',
            title: 'Nachhilfe',
            statusText: 'Service von dir gebucht',
            metaText: 'Heute, 15:00 – 17:00 · 40€',
            progressIconPath: 'hourglass',
            progressText: 'Warte auf Abschluss',
          ),
          SizedBox(height: s(23)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Von dir erstellt',
                style: TextStyle(
                  color: const Color(0xFFF2F2F2),
                  fontSize: s(17),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: s(20)),
              SFSymbolHelper.getChevronRight(
                color: const Color(0xFFF2F2F2),
                size: s(26),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
