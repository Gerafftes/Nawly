import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';

class GlassPressable extends StatelessWidget {
  const GlassPressable({
    super.key,
    required this.child,
    this.onTap,
    required this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final Widget stretchedChild = AppleLiquidStretch(
      hitTestBehavior: HitTestBehavior.translucent,
      stretch: 0.22,
      interactionScale: 1.03,
      pressedScale: 0.985,
      resistance: 0.08,
      child: child,
    );

    if (onTap == null) {
      return stretchedChild;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap!.call();
      },
      child: stretchedChild,
    );
  }
}
