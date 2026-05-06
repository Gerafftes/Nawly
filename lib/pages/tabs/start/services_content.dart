import 'package:flutter/material.dart';
import '../../../services/ui_scale.dart';
import '../../../widgets/job_card.dart';

bool get _showServiceCards => false;
bool get _showCreateActionArrow => true;

class ServicesContent extends StatelessWidget {
  final Color cardColor;
  final Color secondaryText;
  final Color borderColor;
  final Color textColor;
  final Color jobCardColor;
  final Color jobButtonColor;
  final Color timeTextColor;
  final Color buttonTextColor;

  const ServicesContent({
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
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(ui.s(15), ui.s(15), ui.s(15), ui.s(15)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ui.s(15)),
            border: Border.all(color: borderColor, width: ui.s(2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hilfe direkt buchen',
                textHeightBehavior: const TextHeightBehavior(
                  applyHeightToFirstAscent: false,
                  applyHeightToLastDescent: false,
                ),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: ui.s(20),
                  height: 1,
                ),
              ),
              SizedBox(height: ui.s(8)),
              Text(
                'Finde passende Hilfe in deiner Nähe und kontaktiere Anbieter direkt.',
                textHeightBehavior: const TextHeightBehavior(
                  applyHeightToFirstAscent: false,
                  applyHeightToLastDescent: false,
                ),
                style: TextStyle(
                  color: secondaryText,
                  fontSize: ui.s(15),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: ui.s(28)),
        Text(
          'In deiner Nähe',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: ui.s(20),
          ),
        ),
        SizedBox(height: ui.s(12)),
        if (_showServiceCards) ...[
          JobCard(
            title: 'Haushaltshilfe',
            time: 'Heute zwischen 15-18 Uhr',
            price: '15 €/Std',
            color: jobCardColor,
            textColor: textColor,
            buttonColor: jobButtonColor,
            timeTextColor: timeTextColor,
            buttonTextColor: buttonTextColor,
            buttonLabel: 'Buchen',
          ),
          SizedBox(height: ui.s(12)),
          JobCard(
            title: 'Gartenpflege',
            time: 'Morgen zwischen 15-18 Uhr',
            price: '25 €/Std',
            color: jobCardColor,
            textColor: textColor,
            buttonColor: jobButtonColor,
            timeTextColor: timeTextColor,
            buttonTextColor: buttonTextColor,
            buttonLabel: 'Buchen',
          ),
          SizedBox(height: ui.s(12)),
          JobCard(
            title: 'Nachhilfe',
            time: 'Mo/Di/Fr 13-14 Uhr',
            price: '20 €/Std',
            color: jobCardColor,
            textColor: textColor,
            buttonColor: jobButtonColor,
            timeTextColor: timeTextColor,
            buttonTextColor: buttonTextColor,
            buttonLabel: 'Buchen',
          ),
        ] else
          _ServicesEmptyState(
            textColor: textColor,
            secondaryText: secondaryText,
          ),
      ],
    );
  }
}

class _ServicesEmptyState extends StatelessWidget {
  const _ServicesEmptyState({
    required this.textColor,
    required this.secondaryText,
  });

  final Color textColor;
  final Color secondaryText;
  static const Color _titleColor = Color(0xFFF2F2F2);
  static const Color _bodyColor = Color(0xFFB3B3B3);
  static const Color _arrowColor = Color(0xFF767676);

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);
    final double screenHeight = MediaQuery.of(context).size.height;
    final double stateHeight = (screenHeight * 0.41).clamp(
      ui.s(300),
      ui.s(380),
    );

    return SizedBox(
      width: double.infinity,
      height: stateHeight,
      child: Stack(
        children: [
          Positioned(
            top: ui.s(24),
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Noch keine Einträge',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _titleColor,
                    fontSize: ui.s(21),
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: ui.s(8)),
                Text(
                  'Erstelle einen einmaligen Job oder\nbiete einen Service an.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _bodyColor,
                    fontSize: ui.s(17),
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (_showCreateActionArrow)
            Positioned.fill(
              top: ui.s(76),
              child: CustomPaint(
                painter: const _CreateActionArrowPainter(color: _arrowColor),
              ),
            ),
        ],
      ),
    );
  }
}

class _CreateActionArrowPainter extends CustomPainter {
  const _CreateActionArrowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Offset start = Offset(size.width * 0.42, size.height * 0.08);
    final Offset end = Offset(size.width * 0.903, size.height * 0.99);
    final Path path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.36,
        size.width * 0.34,
        size.height * 0.58,
        size.width * 0.56,
        size.height * 0.58,
      )
      ..cubicTo(
        size.width * 0.84,
        size.height * 0.58,
        size.width * 0.96,
        size.height * 0.72,
        end.dx,
        end.dy,
      );

    canvas.drawPath(path, paint);

    final Path arrowHead = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - size.width * 0.025, end.dy - size.height * 0.04)
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx + size.width * 0.032, end.dy - size.height * 0.028);

    canvas.drawPath(arrowHead, paint);
  }

  @override
  bool shouldRepaint(covariant _CreateActionArrowPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
