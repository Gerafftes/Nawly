import 'package:flutter/material.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';

import '../../services/ui_scale.dart';

class GlassSwitch extends StatelessWidget {
  const GlassSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);
    final Color activeColor = const Color(0xFF007AFF);

    return AppleLiquidSwitch(
      width: ui.s(72),
      height: ui.s(60),
      value: value,
      tintColor: activeColor,
      onChanged: onChanged,
    );
  }
}
