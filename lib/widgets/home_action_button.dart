import 'package:flutter/material.dart';
import '../services/sf_symbol_helper.dart';
import '../services/ui_scale.dart';

class HomeActionButton extends StatelessWidget {
  final String iconPath;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isSelected;
  final Color textColor;
  final Color iconColor;

  const HomeActionButton({
    super.key,
    required this.iconPath,
    required this.label,
    required this.color,
    required this.onTap,
    required this.isSelected,
    required this.textColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);
    final EdgeInsets buttonMargin = _getMargin(ui);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: ui.s(85),
          margin: buttonMargin,
          padding: EdgeInsets.symmetric(vertical: ui.s(8), horizontal: ui.s(8)),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(ui.s(20)),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color.fromRGBO(255, 255, 255, 0.04),
                      blurRadius: ui.s(8),
                      offset: Offset(0, ui.s(2)),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SFSymbolHelper.getIcon(
                    iconPath: iconPath,
                    width: ui.s(32),
                    height: ui.s(32),
                    color: iconColor,
                  ),
                  SizedBox(height: ui.s(1)),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: ui.s(14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  EdgeInsets _getMargin(UiScale ui) {
    return EdgeInsets.zero;
  }
}
