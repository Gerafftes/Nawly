import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';
import '../../services/sf_symbol_helper.dart';
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
  final double scrollBottomPadding;

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
    required this.scrollBottomPadding,
  });

  @override
  State<CreateTabContent> createState() => _CreateTabContentState();
}

class _CreateTabContentState extends State<CreateTabContent> {
  bool _isCreateButtonPressed = false;

  void _setCreateButtonPressed(bool value) {
    if (_isCreateButtonPressed == value) {
      return;
    }
    setState(() {
      _isCreateButtonPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);
    double s(double value) => ui.s(value);

    Widget createCard({
      required String title,
      required String description,
      required String buttonText,
      required List<_CreateExampleChipData> examples,
    }) {
      return SizedBox(
        height: s(210),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D0D),
                  borderRadius: BorderRadius.circular(s(24)),
                ),
              ),
            ),
            Positioned(
              left: s(18),
              top: s(11),
              child: Container(
                width: s(52),
                height: s(52),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(s(9)),
                ),
              ),
            ),
            Positioned(
              left: s(18),
              right: s(18),
              top: s(15),
              bottom: s(60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: s(67)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: const Color(0xFFF2F2F2),
                            fontSize: s(21),
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: s(10)),
                        Text(
                          description,
                          style: TextStyle(
                            color: const Color(0xFFB3B3B3),
                            fontSize: s(13),
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: s(12)),
                  Container(height: 1, color: const Color(0xFF1B1B1B)),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: s(7)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Beispiele',
                            style: TextStyle(
                              color: const Color(0xFFB3B3B3),
                              fontSize: s(12),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: s(8)),
                          _CreateExampleChipRow(examples: examples),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SizedBox(
                height: s(60),
                child: Listener(
                  onPointerDown: (_) => _setCreateButtonPressed(true),
                  onPointerUp: (_) => _setCreateButtonPressed(false),
                  onPointerCancel: (_) => _setCreateButtonPressed(false),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      foregroundColor: const Color(0xFFF2F2F2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(s(24)),
                      ),
                      padding: EdgeInsets.zero,
                      minimumSize: Size(double.infinity, s(60)),
                      elevation: 0,
                    ),
                    onPressed: HapticFeedback.selectionClick,
                    child: SizedBox.expand(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            buttonText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFFF2F2F2),
                              fontSize: s(17),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Positioned(
                            right: s(30),
                            child: Icon(
                              Icons.chevron_right,
                              color: const Color(0xFFF2F2F2),
                              size: s(24),
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
      );
    }

    return StretchingOverscrollIndicator(
      axisDirection: AxisDirection.down,
      child: SingleChildScrollView(
        primary: false,
        physics: _isCreateButtonPressed
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
        padding: EdgeInsets.only(bottom: widget.scrollBottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: s(26)),
            createCard(
              title: 'Einmaliger Job',
              description:
                  'Erstelle einen konkreten Auftrag damit ihn andere für dich erledigen.',
              buttonText: 'Einmaligen Job erstellen',
              examples: const <_CreateExampleChipData>[
                _CreateExampleChipData(
                  label: 'Einkaufen',
                  iconPath: 'cart.badge.clock.fill',
                  iconSize: 15,
                ),
                _CreateExampleChipData(
                  label: 'Gassi gehen',
                  iconPath: 'pawprint.fill',
                  iconSize: 13,
                ),
                _CreateExampleChipData(
                  label: 'Umzug',
                  iconPath: 'shippingbox.fill',
                  iconSize: 13,
                ),
              ],
            ),
            SizedBox(height: s(29)),
            Container(
              margin: EdgeInsets.symmetric(horizontal: s(16)),
              height: 1,
              color: const Color(0xFF1B1B1B),
            ),
            SizedBox(height: s(29)),
            createCard(
              title: 'Dauerhafter Service',
              description: 'Biete einen Service an den andere buchen können.',
              buttonText: 'Service anbieten',
              examples: const <_CreateExampleChipData>[
                _CreateExampleChipData(
                  label: 'Nachhilfe',
                  iconPath: 'book.fill',
                  iconSize: 13,
                ),
                _CreateExampleChipData(
                  label: 'Gartenarbeit',
                  iconPath: 'tree.fill',
                  iconSize: 13,
                ),
                _CreateExampleChipData(
                  label: 'Technik',
                  iconPath: 'macbook.and.iphone',
                  iconSize: 19,
                  iconWeight: AppleLiquidSymbolWeight.bold,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateExampleChipRow extends StatelessWidget {
  const _CreateExampleChipRow({required this.examples});

  final List<_CreateExampleChipData> examples;

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(examples.length, (index) {
        final _CreateExampleChipData example = examples[index];

        return Padding(
          padding: EdgeInsets.only(
            right: index == examples.length - 1 ? 0 : ui.s(8),
          ),
          child: _CreateExampleChip(
            label: example.label,
            iconPath: example.iconPath,
            iconSize: example.iconSize,
            iconWeight: example.iconWeight,
          ),
        );
      }),
    );
  }
}

class _CreateExampleChipData {
  const _CreateExampleChipData({
    required this.label,
    required this.iconPath,
    required this.iconSize,
    this.iconWeight = AppleLiquidSymbolWeight.medium,
  });

  final String label;
  final String iconPath;
  final double iconSize;
  final AppleLiquidSymbolWeight iconWeight;
}

class _CreateExampleChip extends StatelessWidget {
  const _CreateExampleChip({
    required this.label,
    required this.iconPath,
    required this.iconSize,
    required this.iconWeight,
  });

  final String label;
  final String iconPath;
  final double iconSize;
  final AppleLiquidSymbolWeight iconWeight;

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);
    final double scaledIconSize = ui.s(iconSize);
    final double iconSlotSize = ui.s(12);
    final double chipHeight = ui.s(22);

    return Container(
      height: chipHeight,
      padding: EdgeInsets.symmetric(horizontal: ui.s(10)),
      decoration: BoxDecoration(
        color: HSLColor.fromAHSL(0.30, 211, 1.0, 0.50).toColor(),
        borderRadius: BorderRadius.circular(ui.s(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: iconSlotSize,
            height: chipHeight,
            child: Center(
              child: OverflowBox(
                minWidth: scaledIconSize,
                maxWidth: scaledIconSize,
                minHeight: scaledIconSize,
                maxHeight: scaledIconSize,
                child: SFSymbolHelper.getIcon(
                  iconPath: iconPath,
                  width: scaledIconSize,
                  height: scaledIconSize,
                  color: const Color(0xB3F2F2F2),
                  weight: iconWeight,
                ),
              ),
            ),
          ),
          SizedBox(width: ui.s(5)),
          Text(
            label,
            strutStyle: StrutStyle(
              fontSize: ui.s(12),
              height: 1,
              forceStrutHeight: true,
            ),
            style: TextStyle(
              color: const Color(0xFF4DAAFC),
              fontSize: ui.s(12),
              fontWeight: FontWeight.w400,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
