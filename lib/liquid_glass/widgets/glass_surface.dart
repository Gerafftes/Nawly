import 'package:flutter/material.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';

import '../liquid_glass_style.dart';

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.config,
    required this.isDark,
    required this.borderRadius,
    required this.child,
  });

  final LiquidGlassConfig config;
  final bool isDark;
  final double borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double constrainedHeight = constraints.maxHeight;
        final bool hasUsableBoundedHeight =
            constraints.hasBoundedHeight && constrainedHeight.isFinite;
        final double height = hasUsableBoundedHeight
            ? constrainedHeight
            : config.height ?? 160;

        return AppleLiquidSurface(
          height: height,
          borderRadius: borderRadius,
          padding: EdgeInsets.zero,
          tintColor: config.tintColor,
          clear: config.clear,
          interactive: config.interactive,
          deformable: config.deformable,
          stretchGestureMode: AppleLiquidStretchGestureMode.gestureDetector,
          child: child,
        );
      },
    );
  }
}
