import 'package:flutter/material.dart';
import '../../widgets/job_card.dart';

class HilfeSuchenContent extends StatefulWidget {
  final Color cardColor;
  final Color secondaryText;
  final Color borderColor;
  final Color textColor;
  final Color jobCardColor;
  final Color jobButtonColor;
  final Color timeTextColor;
  final Color buttonTextColor;

  const HilfeSuchenContent({
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
  State<HilfeSuchenContent> createState() => _HilfeSuchenContentState();
}

class _HilfeSuchenContentState extends State<HilfeSuchenContent> {
  bool isLaufendSelected = true; // Default to "Laufend" selected

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;

    double h(double percent) => screenHeight * percent; // height-based spacing
    final double blockPadding = screenWidth * 0.053; // ~20 @ 375px width
    final double cornerRadius = screenWidth * 0.04; // ~15 @ 375px width

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(blockPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cornerRadius),
            border: Border.all(color: widget.borderColor, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Was möchtest du erstellen?',
                style: TextStyle(
                  color: widget.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Erstelle einen einmaligen Auftrag oder biete eine dauerhafte Dienstleistung an.',
                style: TextStyle(
                  color: widget.secondaryText,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: h(0.037)),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(cornerRadius),
              ),
              minimumSize: Size.fromHeight(h(0.07)),
              elevation: 0,
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('+ Job erstellen'),
          ),
        ),
        SizedBox(height: h(0.01)),
        Text(
          'Erscheint in ‚Ich helfe gern‘',
          style: TextStyle(color: widget.secondaryText, fontSize: 14),
        ),
        SizedBox(height: h(0.02)),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(cornerRadius),
              ),
              minimumSize: Size.fromHeight(h(0.07)),
              elevation: 0,
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('+ Dienstleistung anbieten'),
          ),
        ),
        SizedBox(height: h(0.01)),
        Text(
          'Erscheint in ‚Feste Angebote‘',
          style: TextStyle(color: widget.secondaryText, fontSize: 14),
        ),
        SizedBox(height: h(0.02)),
        Text(
          'Deine Aufträge',
          style: TextStyle(
            color: widget.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        SizedBox(height: h(0.02)),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLaufendSelected = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isLaufendSelected
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFF0D0D0D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(cornerRadius),
                  ),
                  minimumSize: Size.fromHeight(h(0.05)),
                  elevation: 0,
                  splashFactory: NoSplash.splashFactory,
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Laufend'),
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLaufendSelected = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isLaufendSelected
                          ? const Color(0xFF0D0D0D)
                          : const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(cornerRadius),
                  ),
                  minimumSize: Size.fromHeight(h(0.05)),
                  elevation: 0,
                  splashFactory: NoSplash.splashFactory,
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Abgeschlossen'),
              ),
            ),
          ],
        ),
        SizedBox(height: h(0.02)),
        if (isLaufendSelected) ...[
          JobCard(
            title: 'Gassi gehen',
            time: 'Heute, 14:00',
            price: '10 €',
            distance: '1,2km',
            color: widget.jobCardColor,
            textColor: widget.textColor,
            buttonColor: widget.jobButtonColor,
            timeTextColor: widget.timeTextColor,
            buttonTextColor: widget.buttonTextColor,
            buttonLabel: 'Cancel',
          ),
          SizedBox(height: h(0.015)),
          JobCard(
            title: 'Einkaufshilfe',
            time: 'Heute, 15:00',
            price: '12 €',
            distance: '0,8km',
            color: widget.jobCardColor,
            textColor: widget.textColor,
            buttonColor: widget.jobButtonColor,
            timeTextColor: widget.timeTextColor,
            buttonTextColor: widget.buttonTextColor,
            buttonLabel: 'Cancel',
          ),
          SizedBox(height: h(0.015)),
          JobCard(
            title: 'Paket abholen',
            time: 'Heute, 16:30',
            price: '8 €',
            distance: '2,1km',
            color: widget.jobCardColor,
            textColor: widget.textColor,
            buttonColor: widget.jobButtonColor,
            timeTextColor: widget.timeTextColor,
            buttonTextColor: widget.buttonTextColor,
            buttonLabel: 'Cancel',
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(blockPadding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cornerRadius),
              color: widget.cardColor,
            ),
            child: Column(
              children: [
                Icon(Icons.history, size: 48, color: widget.secondaryText),
                SizedBox(height: h(0.02)),
                Text(
                  'Keine abgeschlossenen Aufträge',
                  style: TextStyle(
                    color: widget.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: h(0.01)),
                Text(
                  'Hier werden deine abgeschlossenen Aufträge angezeigt',
                  style: TextStyle(color: widget.secondaryText, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
