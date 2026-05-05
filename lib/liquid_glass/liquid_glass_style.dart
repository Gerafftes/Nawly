import 'package:flutter/material.dart';

class LiquidGlassConfig {
  const LiquidGlassConfig({
    required this.cornerRadius,
    this.height,
    this.tintColor,
    this.clear = true,
    this.interactive = true,
    this.deformable = false,
  });

  final double cornerRadius;
  final double? height;
  final Color? tintColor;
  final bool clear;
  final bool interactive;
  final bool deformable;
}

class LiquidGlassStyle {
  const LiquidGlassStyle._();

  static LiquidGlassConfig infoBox({
    required bool isDark,
    required double Function(double) s,
  }) {
    return LiquidGlassConfig(
      cornerRadius: s(15),
      height: s(124),
      clear: true,
      interactive: true,
    );
  }

  static LiquidGlassConfig navBar({
    required bool isDark,
    required double Function(double) s,
  }) {
    return LiquidGlassConfig(
      cornerRadius: s(100),
      clear: true,
      interactive: true,
    );
  }
}
