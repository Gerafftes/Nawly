import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../services/ui_scale.dart';

const List<String> jobsFilterCategoryOptions = <String>[
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

/// Flutter fallback; this state owns the dropdown overlay and its fade timer.
class JobsFilterSheet extends StatefulWidget {
  const JobsFilterSheet({
    super.key,
    required this.isDark,
    required this.selectedCategories,
    required this.onCategoriesChanged,
    required this.viewButtonTitle,
    required this.onToggleView,
  });
  final bool isDark;
  final Set<String> selectedCategories;
  final ValueChanged<Set<String>> onCategoriesChanged;
  final String viewButtonTitle;
  final VoidCallback onToggleView;
  @override
  State<JobsFilterSheet> createState() => _JobsFilterSheetState();
}

class _JobsFilterSheetState extends State<JobsFilterSheet> {
  double distance = 5;
  bool isCategoryMenuOpen = false;
  final List<String> categories = jobsFilterCategoryOptions;
  final GlobalKey filterSheetKey = GlobalKey();
  final GlobalKey categoryDropdownKey = GlobalKey();
  OverlayEntry? categoryDropdownOverlay;
  double categoryDropdownOpacity = 0;
  bool isCategoryDropdownHiding = false;
  static const Duration dropdownFadeDuration = Duration(milliseconds: 180);
  Timer? _dropdownFadeTimer;
  late Set<String> _selectedCategories;

  @override
  void initState() {
    super.initState();
    _selectedCategories = Set<String>.of(widget.selectedCategories);
  }

  String get _categorySelectionLabel {
    if (_selectedCategories.contains('Alle') || _selectedCategories.isEmpty) {
      return 'Alle';
    }
    if (_selectedCategories.length == 1) return _selectedCategories.first;
    return '${_selectedCategories.length} ausgewählt';
  }

  void _updateSelectedCategories(Set<String> selection) {
    _selectedCategories = selection;
    categoryDropdownOverlay?.markNeedsBuild();
    widget.onCategoriesChanged(Set<String>.of(selection));
  }

  void _removeDropdown() {
    _dropdownFadeTimer?.cancel();
    _dropdownFadeTimer = null;
    categoryDropdownOverlay?.remove();
    categoryDropdownOverlay?.dispose();
    categoryDropdownOverlay = null;
    isCategoryDropdownHiding = false;
  }

  void hideCategoryDropdownOverlay() {
    if (categoryDropdownOverlay == null || isCategoryDropdownHiding) return;
    isCategoryDropdownHiding = true;
    categoryDropdownOpacity = 0;
    categoryDropdownOverlay?.markNeedsBuild();
    _dropdownFadeTimer = Timer(dropdownFadeDuration, _removeDropdown);
  }

  @override
  void dispose() {
    _removeDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDark;
    final UiScale ui = UiScale.of(context, designWidth: 402);
    double s(double value) => ui.s(value);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final EdgeInsets safePadding = MediaQuery.of(context).padding;
    final double safeBottom = safePadding.bottom;
    final double horizontalPadding = screenWidth * 0.06;
    final double overlayTopPadding = math.max(0.0, horizontalPadding - s(20));
    final double safeLeft = safePadding.left;
    final double safeRight = safePadding.right;

    double menuWidthWithinSafeArea() {
      final width =
          screenWidth - safeLeft - safeRight - (horizontalPadding * 2);
      // Prevent negative / tiny widths in extreme layouts.
      return width < 200 ? 200 : width;
    }

    Widget categoryItem(
      String category, {
      required bool isSelected,
      required bool isLast,
    }) {
      final dividerColor = isDark ? Colors.white12 : Colors.black12;
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
              : Border(bottom: BorderSide(color: dividerColor, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                category,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF000000),
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
                color: isSelected ? selectedFill : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? selectedFill
                      : (isDark ? Colors.white38 : const Color(0xFFB3B3B3)),
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
      if (!mounted || categoryDropdownOverlay != null) return;
      final renderObject = categoryDropdownKey.currentContext
          ?.findRenderObject();
      if (renderObject is! RenderBox) return;
      final sheetRenderObject = filterSheetKey.currentContext
          ?.findRenderObject();
      if (sheetRenderObject is! RenderBox) return;

      final fieldTopLeft = renderObject.localToGlobal(Offset.zero);
      final fieldBottom = fieldTopLeft.dy + renderObject.size.height;
      final sheetTopLeft = sheetRenderObject.localToGlobal(Offset.zero);
      final sheetSize = sheetRenderObject.size;
      final menuHeight = (screenHeight - fieldBottom).clamp(0.0, screenHeight);
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
                    setState(() {
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
                        bottom: Radius.circular(fieldRadius),
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
                                        : const Color(0xFF000000),
                                    fontSize: screenWidth * 0.04,
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: categories.length,
                                    itemBuilder: (context, index) {
                                      final category = categories[index];
                                      final isSelected = _selectedCategories
                                          .contains(category);
                                      final isLast =
                                          index == categories.length - 1;

                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            final selection = Set<String>.from(
                                              _selectedCategories,
                                            );
                                            if (category == 'Alle') {
                                              selection
                                                ..clear()
                                                ..add('Alle');
                                            } else {
                                              selection.remove('Alle');
                                              if (!selection.add(category)) {
                                                selection.remove(category);
                                              }
                                              if (selection.isEmpty) {
                                                selection.add('Alle');
                                              }
                                            }
                                            _updateSelectedCategories(
                                              selection,
                                            );
                                          });
                                        },
                                        child: categoryItem(
                                          category,
                                          isSelected: isSelected,
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
                    child: Container(color: Colors.transparent),
                  ),
                ),
            ],
          );
        },
      );

      final overlay = Overlay.of(context, rootOverlay: true);
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF007AFF),
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(44, 44),
                            tapTargetSize: MaterialTapTargetSize.padded,
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
                          padding: EdgeInsets.only(right: screenWidth * 0.03),
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF007AFF),
                              inactiveTrackColor: isDark
                                  ? Colors.white24
                                  : const Color(0xFFB3B3B3),
                              trackHeight: screenHeight * 0.005,
                              thumbColor: const Color(0xFF007AFF),
                              overlayColor: const Color(0x33007AFF),
                              valueIndicatorColor: const Color(0xFF007AFF),
                              showValueIndicator: ShowValueIndicator.onDrag,
                              tickMarkShape: RoundSliderTickMarkShape(
                                tickMarkRadius: screenHeight * 0.004,
                              ),
                              activeTickMarkColor: isDark
                                  ? Colors.white
                                  : const Color(0xFF000000),
                              inactiveTickMarkColor: isDark
                                  ? Colors.white38
                                  : const Color(0xFF666666),
                            ),
                            child: Slider(
                              min: 1,
                              max: 15,
                              label: '${distance.round()} km',
                              value: distance,
                              onChanged: (value) {
                                setState(() {
                                  distance = value;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Padding(
                        padding: EdgeInsets.only(right: horizontalPadding),
                        child: SizedBox(
                          width: screenWidth * 0.125,
                          child: Text(
                            '${distance.round()} km',
                            textAlign: TextAlign.right,
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
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.015),

                  // Kategorie Section
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Kategorie',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF000000),
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Builder(
                          builder: (context) {
                            final double fieldRadius = screenWidth * 0.0375;
                            final BorderRadius fieldBorderRadius =
                                isCategoryMenuOpen
                                ? BorderRadius.vertical(
                                    top: Radius.circular(fieldRadius),
                                  )
                                : BorderRadius.circular(fieldRadius);
                            final Color fieldBackground = isDark
                                ? const Color(0xFF1A1A1A)
                                : const Color(0xFFF2F2F2);
                            final TextStyle fieldTextStyle = TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF000000),
                              fontSize: screenWidth * 0.04,
                            );

                            return GestureDetector(
                              onTap: () {
                                if (isCategoryMenuOpen) {
                                  setState(() {
                                    isCategoryMenuOpen = false;
                                  });
                                  hideCategoryDropdownOverlay();
                                  return;
                                }

                                setState(() {
                                  isCategoryMenuOpen = true;
                                });

                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  showCategoryDropdownOverlay();
                                });
                              },
                              child: Container(
                                key: categoryDropdownKey,
                                constraints: const BoxConstraints(
                                  minHeight: 44,
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04,
                                  vertical: screenHeight * 0.015,
                                ),
                                decoration: BoxDecoration(
                                  color: fieldBackground,
                                  borderRadius: fieldBorderRadius,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _categorySelectionLabel,
                                        style: fieldTextStyle,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    AnimatedRotation(
                                      turns: isCategoryMenuOpen ? -0.5 : 0.0,
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      curve: Curves.easeOut,
                                      child: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF000000),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Sortieren von',
                            style: TextStyle(
                              color: isDark
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
                                  color: isDark
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
                                    color: isDark
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
                                  color: isDark
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
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF000000),
                                    fontSize: screenWidth * 0.04,
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
                  label: widget.viewButtonTitle,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      widget.onToggleView();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(s(15)),
                        border: Border.all(
                          color: const Color(0xFF007AFF),
                          width: s(1),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            widget.viewButtonTitle,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF000000),
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth * 0.04,
                            ),
                          ),
                        ],
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
  }
}
