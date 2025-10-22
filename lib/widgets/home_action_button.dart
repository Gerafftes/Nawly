import 'package:flutter/material.dart';
import '../services/sf_symbol_helper.dart';

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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: _getMargin(context),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: const Color.fromRGBO(255, 255, 255, 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SFSymbolHelper.getIcon(
                iconPath: iconPath,
                width: 24,
                height: 24,
                color: iconColor,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.010),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  EdgeInsets _getMargin(BuildContext context) {
    // Hole die Position des Buttons im Row-Widget
    final parent = context.findAncestorWidgetOfExactType<Row>();
    if (parent != null && parent.children.length == 3) {
      final idx = parent.children.indexOf(this);
      if (idx == 0) {
        // Erster Button: kein linker Margin
        return const EdgeInsets.only(right: 6);
      } else if (idx == 2) {
        // Letzter Button: kein rechter Margin
        return const EdgeInsets.only(left: 6);
      }
    }
    // Mittlerer oder Fallback
    return const EdgeInsets.symmetric(horizontal: 6);
  }
}
