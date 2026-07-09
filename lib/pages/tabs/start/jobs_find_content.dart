import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';
import '../../../services/ui_scale.dart';
import '../../../widgets/job_card.dart';

const List<String> _jobsFilterCategoryOptions = <String>[
  'Alle',
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

const String _jobsFilterConfirmLabel = 'Bestätigen';

const AppleLiquidSheetContent _jobsFilterSheetContent = AppleLiquidSheetContent(
  title: 'Filter',
  doneSemanticLabel: _jobsFilterConfirmLabel,
  leadingAction: AppleLiquidSheetToolbarAction(
    systemImage: 'xmark',
    semanticLabel: 'Schließen',
    foregroundColor: Color(0xFFF2F2F2),
  ),
  trailingAction: AppleLiquidSheetToolbarAction(
    systemImage: 'checkmark',
    semanticLabel: _jobsFilterConfirmLabel,
    foregroundColor: Color(0xFFFFFFFF),
    backgroundColor: Color(0xFF007AFF),
  ),
  sections: <AppleLiquidSheetSection>[
    AppleLiquidSheetSection(
      title: 'Distanz',
      rows: <AppleLiquidSheetRow>[
        AppleLiquidSheetRow.slider(
          title: 'Umkreis (km)',
          value: 5,
          min: 1,
          max: 15,
          step: 1,
          tintColor: Color(0xFF007AFF),
          valuePlacement: AppleLiquidSheetSliderValuePlacement.besideTrack,
          systemImage: 'location',
        ),
      ],
    ),
    AppleLiquidSheetSection(
      title: 'Kategorie',
      rows: <AppleLiquidSheetRow>[
        AppleLiquidSheetRow.picker(
          title: 'Kategorie',
          options: _jobsFilterCategoryOptions,
          selectedOption: 'Alle',
          systemImage: 'square.grid.2x2',
        ),
      ],
    ),
    AppleLiquidSheetSection(
      title: 'Sortierung',
      rows: <AppleLiquidSheetRow>[
        AppleLiquidSheetRow.segmented(
          title: 'Sortieren von',
          firstOption: 'Neu zu Alt',
          secondOption: 'Alt zu Neu',
          selectedOption: 'Neu zu Alt',
          systemImage: 'arrow.up.arrow.down',
          style: AppleLiquidSheetSegmentedStyle(
            selectedBackgroundColor: Color(0xFF1A1A1A),
            unselectedBackgroundColor: Color(0xFF0D0D0D),
            borderWidth: 0,
          ),
        ),
      ],
    ),
    AppleLiquidSheetSection(
      title: 'Ansicht',
      rows: <AppleLiquidSheetRow>[
        AppleLiquidSheetRow.value(
          title: 'Darstellung',
          value: 'Kartenansicht',
          systemImage: 'map',
        ),
      ],
    ),
  ],
);

class JobsFindContent extends StatelessWidget {
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
  final AppleLiquidSheetController sheetController;

  const JobsFindContent({
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
    required this.sheetController,
  });

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);
    double s(double value) => ui.s(value);
    final double infoCardHeight = s(106);
    final double sectionHeaderHeight = s(44);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info-Card
        SizedBox(
          height: infoCardHeight,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(s(15), s(15), s(15), s(15)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(s(15)),
              border: Border.all(color: borderColor, width: s(2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finde Mini-Jobs in deiner Nähe',
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: s(20),
                    height: 1,
                  ),
                ),
                SizedBox(height: s(8)),
                Text(
                  'Wähle einen Job, der zu Zeit, Ort und Bezahlung passt.',
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: s(15),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: s(28)),
        SizedBox(
          height: sectionHeaderHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'In deiner Nähe',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: s(20),
                ),
              ),
              IconButton(
                onPressed: () async {
                  final bool didShowNativeSheet = await sheetController
                      .showSheet(
                        content: _jobsFilterSheetContent,
                        scrollContext: context,
                      );
                  if (didShowNativeSheet) {
                    return;
                  }
                  if (!context.mounted) {
                    return;
                  }

                  final bool isDark = themeMode == 'auto'
                      ? MediaQuery.of(context).platformBrightness ==
                            Brightness.dark
                      : themeMode == 'dark';
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: isDark
                        ? const Color(0xFF0D0D0D)
                        : const Color(0xFFE6E6E6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(s(24)),
                      ),
                    ),
                    builder: (context) {
                      double distance = 5;
                      String? selectedCategory;
                      const String defaultCategoryLabel = 'Alle';
                      bool isCategoryMenuOpen = false;
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
                      final GlobalKey filterSheetKey = GlobalKey();
                      final GlobalKey categoryDropdownKey = GlobalKey();
                      OverlayEntry? categoryDropdownOverlay;
                      double categoryDropdownOpacity = 0.0;
                      bool isCategoryDropdownHiding = false;
                      const Duration dropdownFadeDuration = Duration(
                        milliseconds: 180,
                      );

                      void hideCategoryDropdownOverlay() {
                        if (categoryDropdownOverlay == null) return;
                        if (isCategoryDropdownHiding) return;

                        isCategoryDropdownHiding = true;
                        categoryDropdownOpacity = 0.0;
                        categoryDropdownOverlay?.markNeedsBuild();

                        Future.delayed(dropdownFadeDuration, () {
                          if (categoryDropdownOverlay == null) return;
                          categoryDropdownOverlay?.remove();
                          categoryDropdownOverlay = null;
                          isCategoryDropdownHiding = false;
                        });
                      }

                      return StatefulBuilder(
                        builder: (context, setModalState) {
                          final screenHeight = MediaQuery.of(
                            context,
                          ).size.height;
                          final screenWidth = MediaQuery.of(context).size.width;
                          final EdgeInsets safePadding = MediaQuery.of(
                            context,
                          ).padding;
                          final double safeBottom = safePadding.bottom;
                          final double horizontalPadding = screenWidth * 0.06;
                          final double overlayTopPadding = math.max(
                            0.0,
                            horizontalPadding - s(20),
                          );
                          final double safeLeft = safePadding.left;
                          final double safeRight = safePadding.right;

                          double menuWidthWithinSafeArea() {
                            final width =
                                screenWidth -
                                safeLeft -
                                safeRight -
                                (horizontalPadding * 2);
                            // Prevent negative / tiny widths in extreme layouts.
                            return width < 200 ? 200 : width;
                          }

                          Widget categoryItem(
                            String category, {
                            required bool isSelected,
                            required bool isLast,
                          }) {
                            final dividerColor = isDark
                                ? Colors.white12
                                : Colors.black12;
                            final selectedFill = const Color(0xFF007AFF);
                            final itemBackground = isDark
                                ? const Color(0xFF1A1A1A)
                                : const Color(0xFFF2F2F2);
                            final double itemHorizontalPadding = s(16);
                            final double itemVerticalPadding = s(12);
                            final double itemLabelGap = s(12);

                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: itemHorizontalPadding,
                                vertical: itemVerticalPadding,
                              ),
                              decoration: BoxDecoration(
                                color: itemBackground,
                                border: isLast
                                    ? null
                                    : Border(
                                        bottom: BorderSide(
                                          color: dividerColor,
                                          width: 1,
                                        ),
                                      ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF000000),
                                        fontSize: screenWidth * 0.04,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: itemLabelGap),
                                  Container(
                                    width: screenWidth * 0.055,
                                    height: screenWidth * 0.055,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? selectedFill
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? selectedFill
                                            : (isDark
                                                  ? Colors.white38
                                                  : const Color(0xFFB3B3B3)),
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Icon(
                                            Icons.check,
                                            size: screenWidth * 0.035,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            );
                          }

                          void showCategoryDropdownOverlay() {
                            if (categoryDropdownOverlay != null) return;
                            final renderObject = categoryDropdownKey
                                .currentContext
                                ?.findRenderObject();
                            if (renderObject is! RenderBox) return;
                            final sheetRenderObject = filterSheetKey
                                .currentContext
                                ?.findRenderObject();
                            if (sheetRenderObject is! RenderBox) return;

                            final fieldTopLeft = renderObject.localToGlobal(
                              Offset.zero,
                            );
                            final fieldBottom =
                                fieldTopLeft.dy + renderObject.size.height;
                            final sheetTopLeft = sheetRenderObject
                                .localToGlobal(Offset.zero);
                            final sheetSize = sheetRenderObject.size;
                            final menuHeight = (screenHeight - fieldBottom)
                                .clamp(0.0, screenHeight);
                            if (menuHeight <= 0) return;

                            final menuWidth = menuWidthWithinSafeArea();
                            final menuLeft = safeLeft + horizontalPadding;
                            final fieldRadius = screenWidth * 0.0375;
                            final double safeBlockHeight = math.max(
                              0.0,
                              safeBottom - screenHeight * 0.01,
                            );

                            categoryDropdownOpacity = 0.0;
                            categoryDropdownOverlay = OverlayEntry(
                              builder: (ctx) {
                                final double opacity = categoryDropdownOpacity;
                                return Stack(
                                  children: [
                                    Positioned(
                                      left: sheetTopLeft.dx,
                                      top: sheetTopLeft.dy,
                                      width: sheetSize.width,
                                      height: sheetSize.height,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTap: () {
                                          setModalState(() {
                                            isCategoryMenuOpen = false;
                                          });
                                          hideCategoryDropdownOverlay();
                                        },
                                        child: const SizedBox.expand(),
                                      ),
                                    ),
                                    Positioned(
                                      left: menuLeft,
                                      top: fieldBottom,
                                      width: menuWidth,
                                      height: menuHeight,
                                      child: IgnorePointer(
                                        ignoring: opacity == 0.0,
                                        child: AnimatedOpacity(
                                          opacity: opacity,
                                          duration: dropdownFadeDuration,
                                          curve: Curves.easeOut,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.vertical(
                                              bottom: Radius.circular(
                                                fieldRadius,
                                              ),
                                            ),
                                            child: Container(
                                              color: isDark
                                                  ? const Color(0xFF1A1A1A)
                                                  : const Color(0xFFF2F2F2),
                                              child: Column(
                                                children: [
                                                  Expanded(
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      child: DefaultTextStyle(
                                                        style: TextStyle(
                                                          color: isDark
                                                              ? Colors.white
                                                              : const Color(
                                                                  0xFF000000,
                                                                ),
                                                          fontSize:
                                                              screenWidth *
                                                              0.04,
                                                        ),
                                                        child: ListView.builder(
                                                          padding:
                                                              EdgeInsets.zero,
                                                          itemCount:
                                                              categories.length,
                                                          itemBuilder: (context, index) {
                                                            final category =
                                                                categories[index];
                                                            final isSelected =
                                                                category ==
                                                                selectedCategory;
                                                            final isLast =
                                                                index ==
                                                                categories
                                                                        .length -
                                                                    1;

                                                            return InkWell(
                                                              onTap: () {
                                                                setModalState(() {
                                                                  selectedCategory =
                                                                      category;
                                                                  isCategoryMenuOpen =
                                                                      false;
                                                                });
                                                                hideCategoryDropdownOverlay();
                                                              },
                                                              child: categoryItem(
                                                                category,
                                                                isSelected:
                                                                    isSelected,
                                                                isLast: isLast,
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (safeBlockHeight > 0)
                                      Positioned(
                                        left: menuLeft,
                                        bottom: 0,
                                        width: menuWidth,
                                        height: safeBlockHeight,
                                        child: AbsorbPointer(
                                          absorbing: true,
                                          child: Container(
                                            color: Colors.transparent,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            );

                            final overlay = Overlay.of(
                              context,
                              rootOverlay: true,
                            );
                            overlay.insert(categoryDropdownOverlay!);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (categoryDropdownOverlay == null) return;
                              categoryDropdownOpacity = 1.0;
                              categoryDropdownOverlay?.markNeedsBuild();
                            });
                          }

                          return PopScope(
                            canPop: true,
                            onPopInvokedWithResult: (didPop, result) {
                              hideCategoryDropdownOverlay();
                            },
                            child: Container(
                              key: filterSheetKey,
                              height: MediaQuery.of(context).size.height * 0.55,
                              padding: EdgeInsets.only(
                                top: overlayTopPadding,
                                left: safeLeft,
                                right: safeRight,
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Header
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: horizontalPadding,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Filter',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF000000),
                                                  fontSize: screenWidth * 0.05,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context).pop(),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: const Color(
                                                    0xFF007AFF,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                  minimumSize: const Size(
                                                    44,
                                                    44,
                                                  ),
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .padded,
                                                ),
                                                child: Text(
                                                  'Speichern',
                                                  style: TextStyle(
                                                    color: const Color(
                                                      0xFF007AFF,
                                                    ),
                                                    fontSize:
                                                        screenWidth * 0.04,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.03),

                                        // Distanz Section
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: horizontalPadding,
                                          ),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              'Distanz',
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF000000),
                                                fontSize: screenWidth * 0.04,
                                                fontWeight: FontWeight.w600,
                                              ),
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
                                                  data: SliderTheme.of(context)
                                                      .copyWith(
                                                        activeTrackColor:
                                                            const Color(
                                                              0xFF007AFF,
                                                            ),
                                                        inactiveTrackColor:
                                                            isDark
                                                            ? Colors.white24
                                                            : const Color(
                                                                0xFFB3B3B3,
                                                              ),
                                                        trackHeight:
                                                            screenHeight *
                                                            0.005,
                                                        thumbColor: const Color(
                                                          0xFF007AFF,
                                                        ),
                                                        overlayColor:
                                                            const Color(
                                                              0x33007AFF,
                                                            ),
                                                        valueIndicatorColor:
                                                            const Color(
                                                              0xFF007AFF,
                                                            ),
                                                        showValueIndicator:
                                                            ShowValueIndicator
                                                                .onDrag,
                                                        tickMarkShape:
                                                            RoundSliderTickMarkShape(
                                                              tickMarkRadius:
                                                                  screenHeight *
                                                                  0.004,
                                                            ),
                                                        activeTickMarkColor:
                                                            isDark
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFF000000,
                                                              ),
                                                        inactiveTickMarkColor:
                                                            isDark
                                                            ? Colors.white38
                                                            : const Color(
                                                                0xFF666666,
                                                              ),
                                                      ),
                                                  child: Slider(
                                                    min: 1,
                                                    max: 15,
                                                    label:
                                                        '${distance.round()} km',
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
                                            Padding(
                                              padding: EdgeInsets.only(
                                                right: horizontalPadding,
                                              ),
                                              child: SizedBox(
                                                width: screenWidth * 0.125,
                                                child: Text(
                                                  '${distance.round()} km',
                                                  textAlign: TextAlign.right,
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF000000,
                                                          ),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize:
                                                        screenWidth * 0.04,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: screenHeight * 0.015),

                                        // Kategorie Section
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: horizontalPadding,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  'Kategorie',
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF000000,
                                                          ),
                                                    fontSize:
                                                        screenWidth * 0.04,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height: screenHeight * 0.01,
                                              ),
                                              Builder(
                                                builder: (context) {
                                                  final double fieldRadius =
                                                      screenWidth * 0.0375;
                                                  final BorderRadius
                                                  fieldBorderRadius =
                                                      isCategoryMenuOpen
                                                      ? BorderRadius.vertical(
                                                          top: Radius.circular(
                                                            fieldRadius,
                                                          ),
                                                        )
                                                      : BorderRadius.circular(
                                                          fieldRadius,
                                                        );
                                                  final Color fieldBackground =
                                                      isDark
                                                      ? const Color(0xFF1A1A1A)
                                                      : const Color(0xFFF2F2F2);
                                                  final TextStyle
                                                  fieldTextStyle = TextStyle(
                                                    color: isDark
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF000000,
                                                          ),
                                                    fontSize:
                                                        screenWidth * 0.04,
                                                  );

                                                  return GestureDetector(
                                                    onTap: () {
                                                      if (isCategoryMenuOpen) {
                                                        setModalState(() {
                                                          isCategoryMenuOpen =
                                                              false;
                                                        });
                                                        hideCategoryDropdownOverlay();
                                                        return;
                                                      }

                                                      setModalState(() {
                                                        isCategoryMenuOpen =
                                                            true;
                                                      });

                                                      WidgetsBinding.instance
                                                          .addPostFrameCallback((
                                                            _,
                                                          ) {
                                                            showCategoryDropdownOverlay();
                                                          });
                                                    },
                                                    child: Container(
                                                      key: categoryDropdownKey,
                                                      constraints:
                                                          const BoxConstraints(
                                                            minHeight: 44,
                                                          ),
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal:
                                                                screenWidth *
                                                                0.04,
                                                            vertical:
                                                                screenHeight *
                                                                0.015,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: fieldBackground,
                                                        borderRadius:
                                                            fieldBorderRadius,
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              selectedCategory ??
                                                                  defaultCategoryLabel,
                                                              style:
                                                                  fieldTextStyle,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                          AnimatedRotation(
                                                            turns:
                                                                isCategoryMenuOpen
                                                                ? -0.5
                                                                : 0.0,
                                                            duration:
                                                                const Duration(
                                                                  milliseconds:
                                                                      200,
                                                                ),
                                                            curve:
                                                                Curves.easeOut,
                                                            child: Icon(
                                                              Icons
                                                                  .keyboard_arrow_down,
                                                              color: isDark
                                                                  ? Colors.white
                                                                  : const Color(
                                                                      0xFF000000,
                                                                    ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.02),

                                        // Sortieren Section
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: horizontalPadding,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  'Sortieren von',
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF000000,
                                                          ),
                                                    fontSize:
                                                        screenWidth * 0.04,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height: screenHeight * 0.01,
                                              ),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            vertical:
                                                                screenHeight *
                                                                0.015,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: isDark
                                                            ? const Color(
                                                                0xFF1A1A1A,
                                                              )
                                                            : const Color(
                                                                0xFFF2F2F2,
                                                              ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              screenWidth *
                                                                  0.0375,
                                                            ),
                                                      ),
                                                      alignment:
                                                          Alignment.center,
                                                      child: Text(
                                                        'Neu zu Alt',
                                                        style: TextStyle(
                                                          color: isDark
                                                              ? Colors.white
                                                              : const Color(
                                                                  0xFF000000,
                                                                ),
                                                          fontSize:
                                                              screenWidth *
                                                              0.04,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: screenWidth * 0.02,
                                                  ),
                                                  Expanded(
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            vertical:
                                                                screenHeight *
                                                                0.015,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: isDark
                                                            ? const Color(
                                                                0xFF1A1A1A,
                                                              )
                                                            : const Color(
                                                                0xFFF2F2F2,
                                                              ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              screenWidth *
                                                                  0.0375,
                                                            ),
                                                      ),
                                                      alignment:
                                                          Alignment.center,
                                                      child: Text(
                                                        'Alt zu Neu',
                                                        style: TextStyle(
                                                          color: isDark
                                                              ? Colors.white
                                                              : const Color(
                                                                  0xFF000000,
                                                                ),
                                                          fontSize:
                                                              screenWidth *
                                                              0.04,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: s(16)),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: horizontalPadding,
                                      right: horizontalPadding,
                                      bottom: safeBottom,
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: s(60),
                                      child: Semantics(
                                        button: true,
                                        label: 'Kartenansicht',
                                        child: GestureDetector(
                                          onTap: () {},
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF1A1A1A)
                                                  : const Color(0xFFF2F2F2),
                                              borderRadius:
                                                  BorderRadius.circular(s(15)),
                                              border: Border.all(
                                                color: const Color(0xFF007AFF),
                                                width: s(1),
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Kartenansicht',
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF000000),
                                                fontWeight: FontWeight.bold,
                                                fontSize: screenWidth * 0.04,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                icon: Icon(Icons.tune, color: filterIconColor, size: s(28)),
                style: IconButton.styleFrom(
                  backgroundColor: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(s(8)),
                  ),
                  padding: EdgeInsets.all(s(8)),
                  fixedSize: Size(sectionHeaderHeight, sectionHeaderHeight),
                  minimumSize: Size(sectionHeaderHeight, sectionHeaderHeight),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: s(12)),
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
        SizedBox(height: s(12)),
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
        SizedBox(height: s(12)),
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
