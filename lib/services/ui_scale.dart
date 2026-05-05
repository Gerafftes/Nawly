import 'package:flutter/widgets.dart';

class UiScale {
  final double scale;

  const UiScale(this.scale);

  // Width-based scaling for local spacing, font and control sizes.
  // Do not use this as the only input for full-screen or full-sheet heights.
  factory UiScale.of(BuildContext context, {double designWidth = 402}) {
    final double width = MediaQuery.sizeOf(context).width;
    return UiScale(width / designWidth);
  }

  double s(double value) => value * scale;
}
