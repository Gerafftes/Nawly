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
      ),
      child: Row(
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
        ],
      ),
    );
  }
}
