import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/ui_scale.dart';

class AdaptiveBottomSheet extends StatelessWidget {
  const AdaptiveBottomSheet({
    super.key,
    required this.isDark,
    required this.child,
    this.preferredHeight,
    this.topGap = 24,
  });

  final bool isDark;
  final Widget child;
  final double? preferredHeight;
  final double topGap;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final ui = UiScale.of(context, designWidth: 402);
    double s(double value) => ui.s(value);
    final double keyboardInset = mediaQuery.viewInsets.bottom;
    final double availableHeight = math.max(
      0,
      mediaQuery.size.height - mediaQuery.viewPadding.top - s(topGap),
    );
    final double resolvedHeight = preferredHeight == null
        ? availableHeight
        : math.min(preferredHeight!, availableHeight);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(s(24)),
        ),
        child: Container(
          height: resolvedHeight,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFE6E6E6),
          ),
          child: child,
        ),
      ),
    );
  }
}
