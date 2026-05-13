import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../services/sf_symbol_helper.dart';
import '../services/ui_scale.dart';

class JobCard extends StatelessWidget {
  final String title;
  final String time;
  final String price;
  final String? distance;
  final Color color;
  final Color textColor;
  final Color buttonColor;
  final Color timeTextColor;
  final Color buttonTextColor;
  final BorderSide? buttonBorderSide;
  final String buttonLabel;
  final bool showVerified;
  final bool showPrivacyIcon;
  final bool showFooter;

  const JobCard({
    super.key,
    required this.title,
    required this.time,
    required this.price,
    this.distance,
    required this.color,
    required this.textColor,
    required this.buttonColor,
    required this.timeTextColor,
    required this.buttonTextColor,
    this.buttonBorderSide,
    this.buttonLabel = 'Annehmen',
    this.showVerified = false,
    this.showPrivacyIcon = false,
    this.showFooter = true,
  });

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);
    final TextDirection textDirection = Directionality.of(context);
    final TextStyle titleStyle = TextStyle(
      color: textColor,
      fontWeight: FontWeight.bold,
      fontSize: ui.s(17),
    );
    final TextStyle secondaryLineStyle = TextStyle(
      color: timeTextColor,
      fontWeight: FontWeight.bold,
      fontSize: ui.s(13.5),
      height: 1.4,
    );
    final TextStyle priceStyle = TextStyle(
      color: textColor,
      fontWeight: FontWeight.bold,
      fontSize: ui.s(16),
      height: 1.4,
    );

    double measureSingleLineHeight(TextStyle style) {
      final TextPainter painter = TextPainter(
        text: TextSpan(text: 'Hg', style: style),
        textDirection: textDirection,
        maxLines: 1,
      )..layout();
      return painter.height;
    }

    final double secondaryLineHeight = measureSingleLineHeight(
      secondaryLineStyle,
    );
    final double footerHeight = measureSingleLineHeight(priceStyle);
    final double wrappedSecondaryLineHeight = secondaryLineHeight * 2;
    final double reservedSecondaryLineHeight =
        showFooter ? secondaryLineHeight : wrappedSecondaryLineHeight;
    final double reservedFooterHeight = showFooter
        ? footerHeight
        : math.max(
            0,
            secondaryLineHeight + footerHeight - wrappedSecondaryLineHeight,
          );
    final double contentHeight = measureSingleLineHeight(titleStyle) +
        ui.s(10.5) +
        reservedSecondaryLineHeight +
        reservedFooterHeight;
    final double cardHeight = ui.s(15) + math.max(contentHeight, 44) + ui.s(10);
    final String secondaryLineText =
        distance != null ? '${distance!} · $time' : time;
    final double secondaryLineTopOffset =
        measureSingleLineHeight(titleStyle) + ui.s(10.5);

    return Container(
      width: double.infinity,
      height: cardHeight,
      padding: EdgeInsets.fromLTRB(
        ui.s(18),
        ui.s(15),
        ui.s(18),
        ui.s(10),
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(ui.s(15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: showFooter
                            ? SizedBox(
                                height: reservedSecondaryLineHeight,
                                child: Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Text(
                                    secondaryLineText,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    strutStyle: StrutStyle(
                                      fontSize: ui.s(13.5),
                                      height: 1.4,
                                      forceStrutHeight: true,
                                    ),
                                    style: secondaryLineStyle,
                                  ),
                                ),
                              )
                            : SizedBox.shrink(),
                      ),
                      if (!showFooter)
                        Positioned(
                          top: secondaryLineTopOffset,
                          left: 0,
                          right: 0,
                          child: SizedBox(
                            height: reservedSecondaryLineHeight,
                            child: Text(
                              secondaryLineText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              strutStyle: StrutStyle(
                                fontSize: ui.s(13.5),
                                height: 1.4,
                                forceStrutHeight: true,
                              ),
                              style: secondaryLineStyle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (showFooter)
                  Row(
                    children: [
                      if (showVerified) ...[
                        SFSymbolHelper.getIcon(
                          iconPath: 'assets/icons/verified.svg',
                          width: ui.s(17),
                          height: ui.s(17),
                          color: const Color(0xFF007AFF),
                        ),
                        SizedBox(width: ui.s(6)),
                      ],
                      if (showPrivacyIcon) ...[
                        SFSymbolHelper.getIcon(
                          iconPath: 'assets/icons/eye.circle.fill.svg',
                          width: ui.s(17),
                          height: ui.s(17),
                          color: const Color(0xFF007AFF),
                        ),
                        SizedBox(width: ui.s(6)),
                      ],
                      Text(
                        price,
                        style: priceStyle,
                      ),
                    ],
                  )
                else
                  SizedBox(height: reservedFooterHeight),
              ],
            ),
          ),
          SizedBox(width: ui.s(12)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              side: buttonBorderSide,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ui.s(10)),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: ui.s(18),
                vertical: ui.s(12),
              ),
              minimumSize: const Size(44, 44),
              textStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: ui.s(14),
              ),
              elevation: 0,
            ),
            onPressed: () {},
            child: Text(
              buttonLabel,
              style: TextStyle(color: buttonTextColor),
            ),
          ),
        ],
      ),
    );
  }
}
