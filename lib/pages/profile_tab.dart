import 'package:flutter/material.dart';
import '../services/sf_symbol_helper.dart';

class ProfileTabContent extends StatelessWidget {
  final Color textColor;

  const ProfileTabContent({
    super.key,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewPadding = MediaQuery.of(context).padding;

    return Padding(
      padding: EdgeInsets.only(
        top: viewPadding.top + 16,
        bottom: 32,
        left: 16,
        right: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 65,
                child: SFSymbolHelper.getIcon(
                  iconPath: 'assets/icons/person.circle.svg',
                  width: 65,
                  height: 65,
                  color: const Color(0xFFF2F2F2),
                ),
              ),
              const SizedBox(width: 19),
              Expanded(
                child: SizedBox(
                  height: 65,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gerafftes',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF04C40A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        bottom: 4,
                        child: Text(
                          'johann.eugen@icloud.com',
                          style: const TextStyle(
                            color: Color(0xFFB3B3B3),
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                            height: 1.0,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFFB3B3B3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 65,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ArrowIcon(color: const Color(0xFFB3B3B3), size: const Size(14, 8), strokeWidth: 3.2),
                    const SizedBox(height: 13),
                    _ArrowIcon(
                      color: const Color(0xFFB3B3B3),
                      up: false,
                      size: const Size(14, 8),
                      strokeWidth: 3.2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 38),
          Container(
            width: double.infinity,
            height: 1,
            color: const Color(0xFF2E2E2E),
          ),
          const SizedBox(height: 64),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SFSymbolHelper.getIcon(
                iconPath: 'assets/icons/checkmark.seal.fill.svg',
                width: 20,
                height: 20,
                color: const Color(0xFFF2F2F2),
              ),
              const SizedBox(width: 28),
              const Text(
                'Verifizierung',
                style: TextStyle(
                  color: Color(0xFFF2F2F2),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArrowIcon extends StatelessWidget {
  final Color color;
  final bool up;
  final Size size;
  final double strokeWidth;

  const _ArrowIcon({
    required this.color,
    this.up = true,
    this.size = const Size(18, 10),
    this.strokeWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: _ChevronPainter(color: color, up: up, strokeWidth: strokeWidth),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  final Color color;
  final bool up;
  final double strokeWidth;

  _ChevronPainter({required this.color, required this.up, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path path = Path();
    if (up) {
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
