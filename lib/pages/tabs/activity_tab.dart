import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/sf_symbol_helper.dart';
import '../../services/ui_scale.dart';
import '../../widgets/job_card.dart';

class ActivityTabContent extends StatefulWidget {
  const ActivityTabContent({
    super.key,
    required this.cardColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.jobCardColor,
    required this.jobButtonColor,
    required this.timeTextColor,
    required this.buttonTextColor,
  });

  final Color cardColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color jobCardColor;
  final Color jobButtonColor;
  final Color timeTextColor;
  final Color buttonTextColor;

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

    final double blockPadding = s(20);
    final double cornerRadius = screenWidth * 0.04;
    const double minTapTarget = 44;
    final double toggleButtonHeight = math.max(minTapTarget, h(0.05));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aktivität',
          style: TextStyle(
            color: widget.textColor,
            fontSize: s(24),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: s(8)),
        Text(
          'Laufende und vergangene Jobs und Services erscheinen hier.',
          style: TextStyle(
            color: widget.secondaryTextColor,
            fontSize: s(15),
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        SizedBox(height: s(28)),
        Text(
          'Deine Aufträge',
          style: TextStyle(
            color: widget.textColor,
            fontWeight: FontWeight.bold,
            fontSize: s(20),
          ),
        ),
        SizedBox(height: h(0.02)),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLaufendSelected = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLaufendSelected
                      ? const Color(0xFF1A1A1A)
                      : const Color(0xFF0D0D0D),
                  foregroundColor: const Color(0xFFF2F2F2),
                  overlayColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(cornerRadius),
                  ),
                  minimumSize: Size.fromHeight(toggleButtonHeight),
                  elevation: 0,
                  splashFactory: NoSplash.splashFactory,
                  textStyle: TextStyle(
                    fontSize: s(15),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Laufend'),
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLaufendSelected = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLaufendSelected
                      ? const Color(0xFF0D0D0D)
                      : const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  overlayColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(cornerRadius),
                  ),
                  minimumSize: Size.fromHeight(toggleButtonHeight),
                  elevation: 0,
                  splashFactory: NoSplash.splashFactory,
                  textStyle: TextStyle(
                    fontSize: s(15),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Abgeschlossen'),
              ),
            ),
          ],
        ),
        SizedBox(height: h(0.02)),
        if (_isLaufendSelected) ...[
          JobCard(
            title: 'Gassi gehen',
            time: 'Heute, 14:00',
            price: '10 €',
            distance: '1,2km',
            color: widget.jobCardColor,
            textColor: widget.textColor,
            buttonColor: widget.jobButtonColor,
            timeTextColor: widget.timeTextColor,
            buttonTextColor: widget.buttonTextColor,
            buttonLabel: 'Cancel',
          ),
          SizedBox(height: h(0.015)),
          JobCard(
            title: 'Einkaufshilfe',
            time: 'Heute, 15:00',
            price: '12 €',
            distance: '0,8km',
            color: widget.jobCardColor,
            textColor: widget.textColor,
            buttonColor: widget.jobButtonColor,
            timeTextColor: widget.timeTextColor,
            buttonTextColor: widget.buttonTextColor,
            buttonLabel: 'Cancel',
          ),
          SizedBox(height: h(0.015)),
          JobCard(
            title: 'Paket abholen',
            time: 'Heute, 16:30',
            price: '8 €',
            distance: '2,1km',
            color: widget.jobCardColor,
            textColor: widget.textColor,
            buttonColor: widget.jobButtonColor,
            timeTextColor: widget.timeTextColor,
            buttonTextColor: widget.buttonTextColor,
            buttonLabel: 'Cancel',
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(blockPadding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cornerRadius),
              color: widget.cardColor,
            ),
            child: Column(
              children: [
                SFSymbolHelper.getIcon(
                  iconPath:
                      'assets/icons/clock.arrow.trianglehead.counterclockwise.rotate.90.svg',
                  width: s(40),
                  height: s(40),
                  color: widget.secondaryTextColor,
                ),
                SizedBox(height: h(0.02)),
                Text(
                  'Keine abgeschlossenen Aufträge',
                  style: TextStyle(
                    color: widget.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: s(16),
                  ),
                ),
                SizedBox(height: h(0.01)),
                Text(
                  'Hier werden deine abgeschlossenen Aufträge angezeigt',
                  style: TextStyle(
                    color: widget.secondaryTextColor,
                    fontSize: s(14),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
