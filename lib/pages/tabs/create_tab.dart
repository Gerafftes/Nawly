import 'package:flutter/material.dart';
import '../../services/ui_scale.dart';

class CreateTabContent extends StatefulWidget {
  final Color cardColor;
  final Color secondaryText;
  final Color borderColor;
  final Color textColor;
  final Color jobCardColor;
  final Color jobButtonColor;
  final Color timeTextColor;
  final Color buttonTextColor;

  const CreateTabContent({
    super.key,
    required this.cardColor,
    required this.secondaryText,
    required this.borderColor,
    required this.textColor,
    required this.jobCardColor,
    required this.jobButtonColor,
    required this.timeTextColor,
    required this.buttonTextColor,
  });

  @override
  State<CreateTabContent> createState() => _CreateTabContentState();
}

class _CreateTabContentState extends State<CreateTabContent> {
  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);
    double s(double value) => ui.s(value);
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;

    final double cornerRadius = screenWidth * 0.04;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(s(15), s(15), s(15), s(15)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cornerRadius),
            border: Border.all(color: widget.borderColor, width: s(2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Job oder Service?',
                textHeightBehavior: const TextHeightBehavior(
                  applyHeightToFirstAscent: false,
                  applyHeightToLastDescent: false,
                ),
                style: TextStyle(
                  color: widget.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: s(20),
                  height: 1,
                ),
              ),
              SizedBox(height: s(8)),
              Text(
                'Ein Job ist einmalig. Ein Service ist dauerhaft buchbar.',
                textHeightBehavior: const TextHeightBehavior(
                  applyHeightToFirstAscent: false,
                  applyHeightToLastDescent: false,
                ),
                style: TextStyle(
                  color: widget.secondaryText,
                  fontSize: s(15),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
