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
          SizedBox(height: s(40)),
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
          Container(
            width: double.infinity,
            height: s(97),
            decoration: BoxDecoration(
              color: widget.jobCardColor,
              borderRadius: BorderRadius.circular(s(15)),
            ),
          ),
        ],
      ],
    );
  }
}
