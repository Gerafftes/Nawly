import 'package:flutter/material.dart';
import '../../widgets/job_card.dart';

class IchBieteAnContent extends StatelessWidget {
  final Color cardColor;
  final Color secondaryText;
  final Color borderColor;
  final Color textColor;
  final Color jobCardColor;
  final Color jobButtonColor;
  final Color timeTextColor;
  final Color buttonTextColor;

  const IchBieteAnContent({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Beispielinhalt für "Ich biete an"
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dienste direkt buchen.',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Finde dauerhafte Dienstleistungen in deiner Nähe und kontaktiere die Anbieter:innen direkt – ohne selbst einen Auftrag einstellen zu müssen.',
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'In deiner Nähe',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 12),
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
        const SizedBox(height: 12),
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
      ],
    );
  }
}
