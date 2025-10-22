import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../widgets/job_card.dart';

class IchHelfeGerneContent extends StatelessWidget {
  final Color cardColor;
  final Color secondaryText;
  final Color borderColor;
  final Color textColor;
  final Color jobCardColor;
  final Color jobButtonColor;
  final Color timeTextColor;
  final Color filterIconColor;
  final String themeMode;
  final Color buttonTextColor;

  const IchHelfeGerneContent({
    super.key,
    required this.cardColor,
    required this.secondaryText,
    required this.borderColor,
    required this.textColor,
    required this.jobCardColor,
    required this.jobButtonColor,
    required this.timeTextColor,
    required this.filterIconColor,
    required this.themeMode,
    required this.buttonTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info-Card
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
                'Finde Jobs in deiner Nähe.',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Übernimm Aufträge und verdiene flexibel Geld – vom Einkaufen bis zur Gartenarbeit.',
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'In deiner Nähe',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            IconButton(
              onPressed: () {
                final bool isDark =
                    themeMode == 'auto'
                        ? MediaQuery.of(context).platformBrightness ==
                            Brightness.dark
                        : themeMode == 'dark';
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor:
                      isDark
                          ? const Color(0xFF0D0D0D)
                          : const Color(0xFFE6E6E6),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (context) {
                    double distance = 5;
                    bool isCategoryOpen = false;
                    String selectedCategory = 'Alle';
                    final List<String> categories = [
                      'Haushalt & Reinigung',
                      'Gartenarbeit & Pflanzenpflege',
                      'Umzug & Möbel tragen',
                      'Reparaturen & Heimwerken',
                      'Kinderbetreuung',
                      'Seniorenhilfe',
                      'Einkäufe & Besorgungen',
                      'Nachhilfe & Technikhilfe',
                      'Haustierbetreuung',
                      'Sonstiges / Allgemeine Hilfe',
                    ];
                    return StatefulBuilder(
                      builder: (context, setModalState) {
                        final screenHeight = MediaQuery.of(context).size.height;
                        final screenWidth = MediaQuery.of(context).size.width;
                        return Container(
                          height: MediaQuery.of(context).size.height * 0.55,
                          padding: EdgeInsets.all(screenWidth * 0.06),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Filter',
                                    style: TextStyle(
                                      color:
                                          isDark
                                              ? Colors.white
                                              : const Color(0xFF000000),
                                      fontSize: screenWidth * 0.05,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF007AFF),
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 0),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Speichern',
                                      style: TextStyle(
                                        color: const Color(0xFF007AFF),
                                        fontSize: screenWidth * 0.04,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.03),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Distanz',
                                  style: TextStyle(
                                    color:
                                        isDark
                                            ? Colors.white
                                            : const Color(0xFF000000),
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 9,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: screenWidth * 0.03,
                                      ),
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          activeTrackColor: const Color(
                                            0xFF007AFF,
                                          ),
                                          inactiveTrackColor:
                                              isDark
                                                  ? Colors.white24
                                                  : const Color(0xFFB3B3B3),
                                          trackHeight: screenHeight * 0.005,
                                          thumbColor: const Color(0xFF007AFF),
                                          overlayColor: const Color(0x33007AFF),
                                          valueIndicatorColor: const Color(
                                            0xFF007AFF,
                                          ),
                                          showValueIndicator:
                                              ShowValueIndicator.always,
                                          tickMarkShape:
                                              RoundSliderTickMarkShape(
                                                tickMarkRadius:
                                                    screenHeight * 0.004,
                                              ),
                                          activeTickMarkColor:
                                              isDark
                                                  ? Colors.white
                                                  : const Color(0xFF000000),
                                          inactiveTickMarkColor:
                                              isDark
                                                  ? Colors.white38
                                                  : const Color(0xFF666666),
                                        ),
                                        child: Slider(
                                          min: 1,
                                          max: 15,
                                          label: '${distance.round()} km',
                                          value: distance,
                                          onChanged: (value) {
                                            setModalState(() {
                                              distance = value;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  SizedBox(
                                    width: screenWidth * 0.125,
                                    child: Text(
                                      '${distance.round()} km',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        color:
                                            isDark
                                                ? Colors.white
                                                : const Color(0xFF000000),
                                        fontWeight: FontWeight.bold,
                                        fontSize: screenWidth * 0.04,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Kategorie',
                                  style: TextStyle(
                                    color:
                                        isDark
                                            ? Colors.white
                                            : const Color(0xFF000000),
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              GestureDetector(
                                onTap: () {
                                  setModalState(
                                    () => isCategoryOpen = !isCategoryOpen,
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.04,
                                    vertical: screenHeight * 0.015,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isDark
                                            ? const Color(0xFF1A1A1A)
                                            : const Color(0xFFF2F2F2),
                                    borderRadius: BorderRadius.circular(
                                      screenWidth * 0.0375,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        selectedCategory,
                                        style: TextStyle(
                                          color:
                                              isDark
                                                  ? Colors.white
                                                  : const Color(0xFF000000),
                                          fontSize: screenWidth * 0.04,
                                        ),
                                      ),
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(
                                          begin: 0,
                                          end: isCategoryOpen ? 0.5 : 0.0,
                                        ),
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        builder:
                                            (context, turns, child) =>
                                                Transform.rotate(
                                                  angle: turns * 2 * math.pi,
                                                  child: child,
                                                ),
                                        child: Icon(
                                          Icons.keyboard_arrow_down,
                                          color:
                                              isDark
                                                  ? Colors.white
                                                  : const Color(0xFF000000),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isCategoryOpen) ...[
                                SizedBox(height: screenHeight * 0.01),
                                Container(
                                  decoration: BoxDecoration(
                                    color:
                                        isDark
                                            ? const Color(0xFF1A1A1A)
                                            : const Color(0xFFF2F2F2),
                                    borderRadius: BorderRadius.circular(
                                      screenWidth * 0.0375,
                                    ),
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: categories.length,
                                    separatorBuilder:
                                        (context, idx) => Divider(
                                          color:
                                              isDark
                                                  ? Colors.white12
                                                  : const Color(0xFFCCCCCC),
                                          height: 1,
                                        ),
                                    itemBuilder: (context, idx) {
                                      final cat = categories[idx];
                                      return ListTile(
                                        onTap: () {
                                          setModalState(() {
                                            selectedCategory = cat;
                                            isCategoryOpen = false;
                                          });
                                        },
                                        title: Text(
                                          cat,
                                          style: TextStyle(
                                            color:
                                                isDark
                                                    ? Colors.white
                                                    : const Color(0xFF000000),
                                            fontSize: screenWidth * 0.04,
                                          ),
                                        ),
                                        trailing: GestureDetector(
                                          onTap: () {
                                            setModalState(() {
                                              selectedCategory = cat;
                                              isCategoryOpen = false;
                                            });
                                          },
                                          child: Container(
                                            width: screenWidth * 0.06,
                                            height: screenWidth * 0.06,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color:
                                                    selectedCategory == cat
                                                        ? const Color(
                                                          0xFF007AFF,
                                                        )
                                                        : isDark
                                                        ? Colors.white38
                                                        : const Color(
                                                          0xFFCCCCCC,
                                                        ),
                                                width: 2,
                                              ),
                                              color:
                                                  selectedCategory == cat
                                                      ? const Color(0xFF007AFF)
                                                      : Colors.transparent,
                                            ),
                                            child:
                                                selectedCategory == cat
                                                    ? Icon(
                                                      Icons.check,
                                                      color:
                                                          isDark
                                                              ? Colors.white
                                                              : const Color(
                                                                0xFF000000,
                                                              ),
                                                      size: screenWidth * 0.04,
                                                    )
                                                    : null,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                              SizedBox(height: screenHeight * 0.02),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Sortieren von',
                                  style: TextStyle(
                                    color:
                                        isDark
                                            ? Colors.white
                                            : const Color(0xFF000000),
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: screenHeight * 0.015,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isDark
                                                ? const Color(0xFF1A1A1A)
                                                : const Color(0xFFF2F2F2),
                                        borderRadius: BorderRadius.circular(
                                          screenWidth * 0.0375,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Neu zu Alt',
                                        style: TextStyle(
                                          color:
                                              isDark
                                                  ? Colors.white
                                                  : const Color(0xFF000000),
                                          fontSize: screenWidth * 0.04,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: screenHeight * 0.015,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isDark
                                                ? const Color(0xFF1A1A1A)
                                                : const Color(0xFFF2F2F2),
                                        borderRadius: BorderRadius.circular(
                                          screenWidth * 0.0375,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Alt zu Neu',
                                        style: TextStyle(
                                          color:
                                              isDark
                                                  ? Colors.white
                                                  : const Color(0xFF000000),
                                          fontSize: screenWidth * 0.04,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor:
                                        isDark
                                            ? const Color(0xFF1A1A1A)
                                            : const Color(0xFFF2F2F2),
                                    foregroundColor: const Color(0xFF007AFF),
                                    side: const BorderSide(
                                      color: Color(0xFF007AFF),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        screenWidth * 0.0375,
                                      ),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: screenHeight * 0.0175,
                                    ),
                                  ),
                                  child: Text(
                                    'Kartenansicht',
                                    style: TextStyle(
                                      color:
                                          isDark
                                              ? Colors.white
                                              : const Color(0xFF000000),
                                      fontWeight: FontWeight.bold,
                                      fontSize: screenWidth * 0.04,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
              icon: Icon(Icons.tune, color: filterIconColor, size: 28),
              style: IconButton.styleFrom(
                backgroundColor: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        JobCard(
          title: 'Gassi gehen',
          time: 'Heute, 14:00',
          price: '10 €',
          distance: '1,2km',
          color: jobCardColor,
          textColor: textColor,
          buttonColor: jobButtonColor,
          timeTextColor: timeTextColor,
          buttonTextColor: buttonTextColor,
          showVerified: true,
        ),
        const SizedBox(height: 12),
        JobCard(
          title: 'Einkaufshilfe',
          time: 'Heute, 15:00',
          price: '12 €',
          distance: '0,8km',
          color: jobCardColor,
          textColor: textColor,
          buttonColor: jobButtonColor,
          timeTextColor: timeTextColor,
          buttonTextColor: buttonTextColor,
          showVerified: true,
        ),
        const SizedBox(height: 12),
        JobCard(
          title: 'Paket abholen',
          time: 'Heute, 16:30',
          price: '8 €',
          distance: '2,1km',
          color: jobCardColor,
          textColor: textColor,
          buttonColor: jobButtonColor,
          timeTextColor: timeTextColor,
          buttonTextColor: buttonTextColor,
          showVerified: true,
        ),
      ],
    );
  }
}
