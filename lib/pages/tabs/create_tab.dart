import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                  SizedBox(height: s(10)),
                  Text(
                    'Beispiele',
                    style: TextStyle(
                      color: const Color(0xFFB3B3B3),
                      fontSize: s(12),
                      fontWeight: FontWeight.w500,
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
                            child: SFSymbolHelper.getChevronRight(
                              color: const Color(0xFFF2F2F2),
                              size: s(28),
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
            ),
          ],
        ),
      ),
    );
  }
}
