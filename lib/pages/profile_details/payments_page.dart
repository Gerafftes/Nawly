import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import '../../services/sf_symbol_helper.dart'; // Pfad ggf. anpassen
import '../../services/ui_scale.dart';
import '../../widgets/adaptive_bottom_sheet.dart';
import 'payout_processing_page.dart';
import 'payout_history_page.dart';
import 'profile_detail_page_utils.dart';

DateTime _firstDayOfNextMonth(DateTime baseDate) {
  return DateTime(baseDate.year, baseDate.month + 1, 1);
}

String _formatShortMonth(DateTime date, BuildContext context) {
  final String locale = Localizations.localeOf(context).toString();
  return intl.DateFormat('MMM', locale).format(date);
}

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({
    super.key,
    this.isDarkOverride,
    this.prewarm = false,
    this.prewarmPhase = 2,
  });

  final bool? isDarkOverride;
  final bool prewarm;
  final int prewarmPhase;

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage>
    with TickerProviderStateMixin, ProfileDetailPerformanceMixin<PaymentsPage> {
  static const Set<String> _paymentsOverlayWarmupIconPaths = <String>{
    'assets/icons/PayPal.svg',
    'assets/icons/apple.logo.svg',
    'assets/icons/paypal_groß.svg',
    'assets/icons/visa_groß.svg',
    'assets/icons/checkmark.circle.fill.svg',
    'assets/icons/plus.circle.fill.svg',
    'assets/icons/checkmark.seal.fill.svg',
  };

  int _selectedPayoutIndex = 0;
  int _selectedPayoutSchedule = 0;
  int? _standardPayoutIndex;
  int? _selectedPaymentMethodIndex;
  Timer? _paymentMethodPressTimer;

  static const List<_PaymentMethodData> _paymentMethods = [
    _PaymentMethodData(
      iconPath: 'assets/icons/PayPal.svg',
      semanticsLabel: 'PayPal',
    ),
    _PaymentMethodData(
      iconPath: 'assets/icons/apple.logo.svg',
      iconColor: Color(0xFF000000),
      semanticsLabel: 'Apple Pay',
    ),
  ];

  // Slider State Variables
  double _payoutSwipeOffset = 0;
  bool _showSwipeEndCap = false;
  bool _pendingHapticOnSnap = false;
  bool _openPayoutPageAfterSnap = false;
  bool _isPayoutProcessing = false;
  double? _snapHapticTriggerOffset;
  bool _didTriggerSnapHaptic = false;

  late final AnimationController _swipeSnapController;
  late final AnimationController _swipeChevronScaleController;
  late final Animation<double> _firstSwipeChevronScale;
  late final Animation<double> _secondSwipeChevronScale;
  Animation<double>? _swipeSnapAnimation;
  bool _scheduledOverlayWarmup = false;

  @override
  String get profileDetailPerformanceLabel {
    if (widget.prewarm && widget.prewarmPhase < 2) {
      return 'PaymentsPage:phase_${widget.prewarmPhase + 1}';
    }
    return 'PaymentsPage';
  }

  @override
  bool get deferHeavyContent => true;

  @override
  bool get isProfileDetailWarmup => widget.prewarm;

  @override
  String get profileDetailWarmupKey {
    if (widget.prewarm && widget.prewarmPhase < 2) {
      return 'PaymentsPage.phase_${widget.prewarmPhase + 1}';
    }
    return 'PaymentsPage';
  }

  static const List<_PayoutCardContent> _payoutCards = [
    _PayoutCardContent(
      title: 'Johann Eugen Mün...',
      amount: '300,00 €',
      statusText: 'Bereit zur Auszahlung',
      feeLabel: 'Gebühr 0%',
      minLabel: 'Mindestbetrag',
      nextLabel: 'Nächste Auszahlung',
      minAmount: '25,00 €',
    ),
    _PayoutCardContent(
      title: 'Visa •••• 4242',
      amount: '300,00 €',
      statusText: 'Bereit zur Auszahlung',
      feeLabel: 'Gebühr 1,5%',
      minLabel: 'Mindestbetrag',
      nextLabel: 'Nächste Auszahlung',
      minAmount: '25,00 €',
    ),
    _PayoutCardContent(
      title: 'Gutschein',
      amount: '300,00 €',
      statusText: 'Bereit zur Auszahlung',
      feeLabel: 'Gebühr 0%',
      minLabel: 'Mindestbetrag',
      nextLabel: '',
      minAmount: '5,00 €',
    ),
  ];

  Widget _buildBottomRightContent(
    UiScale ui, {
    required double rowHeight,
    required bool isGiftCard,
    required double giftCardOffsetY,
  }) {
    switch (_selectedPayoutIndex) {
      case 0:
        return SizedBox(
          height: rowHeight,
          child: Align(
            alignment: Alignment.centerRight,
            child: SFSymbolHelper.getIcon(
              iconPath: 'assets/icons/paypal_groß.svg',
              width: ui.s(129),
              height: rowHeight,
            ),
          ),
        );
      case 1:
        return SizedBox(
          height: rowHeight,
          child: Align(
            alignment: Alignment.centerRight,
            child: SFSymbolHelper.getIcon(
              iconPath: 'assets/icons/visa_groß.svg',
              width: ui.s(104),
              height: rowHeight,
            ),
          ),
        );
      default:
        final double fontSize = ui.s(18);
        final double lineHeight = isGiftCard ? 1.1 : 1.0;
        final double singleLineHeight = fontSize * lineHeight;
        final double bottomOffset = (rowHeight - singleLineHeight) / 2;

        final textStyle = TextStyle(
          color: const Color(0xFFF2F2F2),
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          height: lineHeight,
        );
        const textContent = 'Amazon.de\nGutschein';

        return SizedBox(
          height: rowHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomRight,
            children: [
              Opacity(
                opacity: 0,
                child: Text(
                  textContent,
                  textAlign: TextAlign.right,
                  style: textStyle,
                ),
              ),
              Positioned(
                right: 0,
                bottom: bottomOffset,
                child: Text(
                  textContent,
                  textAlign: TextAlign.right,
                  style: textStyle,
                ),
              ),
            ],
          ),
        );
    }
  }

  void resetSlider() {
    if (_payoutSwipeOffset > 0) {
      _animateSwipeTo(0, curve: Curves.easeOutCubic);
    }
  }

  @override
  void initState() {
    super.initState();
    _swipeChevronScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _firstSwipeChevronScale = _buildSwipeChevronScaleAnimation(
      const Interval(0.0, 0.28, curve: Curves.easeInOut),
    );
    _secondSwipeChevronScale = _buildSwipeChevronScaleAnimation(
      const Interval(0.14, 0.42, curve: Curves.easeInOut),
    );
    _swipeSnapController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 300),
          )
          ..addListener(() {
            if (_swipeSnapAnimation != null && mounted) {
              final double nextOffset = _swipeSnapAnimation!.value;
              final bool shouldTriggerSnapHaptic =
                  _pendingHapticOnSnap &&
                  !_didTriggerSnapHaptic &&
                  _snapHapticTriggerOffset != null &&
                  nextOffset >= _snapHapticTriggerOffset!;
              if (shouldTriggerSnapHaptic) {
                HapticFeedback.heavyImpact();
                _didTriggerSnapHaptic = true;
              }
              setState(() {
                _payoutSwipeOffset = nextOffset;
                _showSwipeEndCap = nextOffset > 0;
              });
            }
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              final bool shouldOpenPayoutPage = _openPayoutPageAfterSnap;
              if (mounted) {
                setState(() {
                  _swipeSnapAnimation = null;
                  _pendingHapticOnSnap = false;
                  _openPayoutPageAfterSnap = false;
                  _snapHapticTriggerOffset = null;
                  _didTriggerSnapHaptic = false;
                });
              }
              if (shouldOpenPayoutPage) {
                unawaited(_runPayoutCompletionFlow());
              }
            }
          });
  }

  @override
  void dispose() {
    _paymentMethodPressTimer?.cancel();
    _swipeChevronScaleController.dispose();
    _swipeSnapController.dispose();
    super.dispose();
  }

  Animation<double> _buildSwipeChevronScaleAnimation(Interval interval) {
    return TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 1.2),
        weight: 50,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(parent: _swipeChevronScaleController, curve: interval),
    );
  }

  Future<void> _runPayoutCompletionFlow() async {
    if (!mounted || _isPayoutProcessing) {
      return;
    }

    setState(() {
      _isPayoutProcessing = true;
    });

    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) {
      return;
    }

    setState(() {
      _isPayoutProcessing = false;
      _payoutSwipeOffset = 0;
      _showSwipeEndCap = false;
    });

    _pushWithFade(
      PayoutProcessingPage(isDarkOverride: _resolveIsDark(context)),
    );
  }

  void _animateSwipeTo(
    double target, {
    bool triggerHaptic = false,
    bool openPayoutPageAfterSnap = false,
    Curve? curve,
  }) {
    if (!mounted || _isPayoutProcessing) {
      return;
    }
    _swipeSnapController.stop();
    setState(() {
      _swipeSnapAnimation =
          Tween<double>(begin: _payoutSwipeOffset, end: target).animate(
            CurvedAnimation(
              parent: _swipeSnapController,
              curve: curve ?? Curves.easeOutCubic,
            ),
          );
      _pendingHapticOnSnap = triggerHaptic;
      _openPayoutPageAfterSnap = openPayoutPageAfterSnap;
      _snapHapticTriggerOffset = triggerHaptic
          ? math.max(0.0, target - 12)
          : null;
      _didTriggerSnapHaptic = false;
    });
    _swipeSnapController.forward(from: 0);
  }

  void _startPaymentMethodPress(int index) {
    _paymentMethodPressTimer?.cancel();
    _paymentMethodPressTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      if (_selectedPaymentMethodIndex != index) {
        HapticFeedback.selectionClick();
      }
      setState(() {
        _selectedPaymentMethodIndex = index;
      });
      _paymentMethodPressTimer = null;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduledOverlayWarmup) {
      return;
    }

    _scheduledOverlayWarmup = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        SFSymbolHelper.precacheIcons(context, _paymentsOverlayWarmupIconPaths),
      );
    });
  }

  void _cancelPaymentMethodPress() {
    _paymentMethodPressTimer?.cancel();
    _paymentMethodPressTimer = null;
  }

  void _pushWithFade(Widget page) {
    Navigator.of(context).push(buildProfileDetailFadeRoute<void>(page: page));
  }

  bool _resolveIsDark(BuildContext context) {
    return widget.isDarkOverride ??
        MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  void _showFilterOverlay() {
    final ui = UiScale.of(context, designWidth: 402);
    double s(double value) => ui.s(value);
    final bool isDark = _resolveIsDark(context);
    int draftSelectedPayoutSchedule = _selectedPayoutSchedule;
    int? draftStandardPayoutIndex = _standardPayoutIndex;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 250),
        reverseDuration: Duration(milliseconds: 200),
      ),
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final double overlayLeftInset =
                MediaQuery.of(context).padding.left + s(16);
            final double overlayRightInset =
                MediaQuery.of(context).padding.right + s(16);
            final double overlaySafeBottom = MediaQuery.of(
              context,
            ).viewPadding.bottom;
            final double overlayButtonHeight = math.max(44, s(41));
            final double preferredOverlayHeight = math.max(
              0.0,
              MediaQuery.of(context).size.height * 0.6 - s(39),
            );
            final String payoutName = _selectedPayoutIndex == 0
                ? 'PayPal'
                : _selectedPayoutIndex == 1
                ? 'Visa'
                : 'Gutschein';
            final bool isAutoSelected = draftSelectedPayoutSchedule == 0;
            final bool isStandardSelected =
                draftStandardPayoutIndex == _selectedPayoutIndex;
            final String standardBlockTitleText = isAutoSelected
                ? '$payoutName automatisch auszahlen'
                : '$payoutName als Standart verwenden';
            final String standardBlockSubtitleText = isAutoSelected
                ? 'Wird jeden Monat automatisch ausgezahlt'
                : 'Diese Methode bevorzugen';
            final Color autoColor = isAutoSelected
                ? const Color(0xFF1A1A1A)
                : const Color(0xFF121212);
            final Color manualColor = isAutoSelected
                ? const Color(0xFF121212)
                : const Color(0xFF1A1A1A);
            return AdaptiveBottomSheet(
              isDark: isDark,
              preferredHeight: preferredOverlayHeight,
              child: Padding(
                padding: EdgeInsets.only(top: s(23)),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Auszahlung bearbeiten',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFF2F2F2),
                                fontSize: s(30),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: s(5)),
                            Text(
                              payoutName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFB3B3B3),
                                fontSize: s(20),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: s(18)),
                            Padding(
                              padding: EdgeInsets.only(left: overlayLeftInset),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Auszahlungsart',
                                  style: TextStyle(
                                    color: const Color(0xFFF2F2F2),
                                    fontSize: s(20),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: s(14)),
                            Padding(
                              padding: EdgeInsets.only(
                                left: overlayLeftInset,
                                right: overlayRightInset,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Semantics(
                                      button: true,
                                      selected: isAutoSelected,
                                      label: 'Automatisch',
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          if (!isAutoSelected &&
                                              draftStandardPayoutIndex !=
                                                  null) {
                                            draftStandardPayoutIndex = null;
                                          }
                                          draftSelectedPayoutSchedule = 0;
                                          setModalState(() {});
                                        },
                                        child: SizedBox(
                                          height: overlayButtonHeight,
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 320,
                                            ),
                                            switchInCurve: Curves.easeIn,
                                            switchOutCurve: Curves.easeOut,
                                            transitionBuilder:
                                                (child, animation) =>
                                                    FadeTransition(
                                                      opacity: animation,
                                                      child: child,
                                                    ),
                                            child: DecoratedBox(
                                              key: ValueKey<Color>(autoColor),
                                              decoration: BoxDecoration(
                                                color: autoColor,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      s(15),
                                                    ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'Automatisch',
                                                  style: TextStyle(
                                                    color: const Color(
                                                      0xFFF2F2F2,
                                                    ),
                                                    fontSize: s(15),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: s(12)),
                                  Expanded(
                                    child: Semantics(
                                      button: true,
                                      selected: !isAutoSelected,
                                      label: 'Manuell',
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          if (isAutoSelected &&
                                              draftStandardPayoutIndex !=
                                                  null) {
                                            draftStandardPayoutIndex = null;
                                          }
                                          draftSelectedPayoutSchedule = 1;
                                          setModalState(() {});
                                        },
                                        child: SizedBox(
                                          height: overlayButtonHeight,
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 340,
                                            ),
                                            switchInCurve: Curves.easeInOut,
                                            switchOutCurve: Curves.easeInOut,
                                            transitionBuilder:
                                                (child, animation) =>
                                                    FadeTransition(
                                                      opacity: animation,
                                                      child: child,
                                                    ),
                                            child: DecoratedBox(
                                              key: ValueKey<Color>(manualColor),
                                              decoration: BoxDecoration(
                                                color: manualColor,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      s(15),
                                                    ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'Manuell',
                                                  style: TextStyle(
                                                    color: const Color(
                                                      0xFFF2F2F2,
                                                    ),
                                                    fontSize: s(15),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
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
                            SizedBox(height: s(9)),
                            Padding(
                              padding: EdgeInsets.only(
                                left: overlayLeftInset,
                                right: overlayRightInset,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  isAutoSelected
                                      ? 'Die Auszahlung erfolgt einmal pro Monat automatisch.'
                                      : 'Die Auszahlung wird von dir getätigt.',
                                  style: TextStyle(
                                    color: const Color(0xFFB3B3B3),
                                    fontSize: s(13),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: s(29)),
                            Padding(
                              padding: EdgeInsets.only(
                                left: overlayLeftInset,
                                right: overlayRightInset,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  isAutoSelected
                                      ? 'Automatische-Auszahlung'
                                      : 'Standart-Auszahlung',
                                  style: TextStyle(
                                    color: const Color(0xFFF2F2F2),
                                    fontSize: s(20),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: s(12)),
                            Padding(
                              padding: EdgeInsets.only(
                                left: overlayLeftInset,
                                right: overlayRightInset,
                              ),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  draftStandardPayoutIndex = isStandardSelected
                                      ? null
                                      : _selectedPayoutIndex;
                                  setModalState(() {});
                                },
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  switchInCurve: Curves.easeInOut,
                                  switchOutCurve: Curves.easeInOut,
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                  child: Container(
                                    key: ValueKey<String>(
                                      '${isAutoSelected ? 'auto' : 'manual'}-$payoutName',
                                    ),
                                    height: s(60),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1A1A),
                                      borderRadius: BorderRadius.circular(
                                        s(15),
                                      ),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: s(12),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        if (isStandardSelected)
                                          SizedBox(
                                            width: s(15),
                                            height: s(15),
                                            child: Transform.scale(
                                              scale: 17 / 15,
                                              child: SFSymbolHelper.getIcon(
                                                iconPath:
                                                    'assets/icons/checkmark.circle.fill.svg',
                                                width: s(15),
                                                height: s(15),
                                                color: const Color(0xFF007AFF),
                                              ),
                                            ),
                                          )
                                        else
                                          Container(
                                            width: s(15),
                                            height: s(15),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1A1A1A),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                width: s(1),
                                                color: const Color(0xFFB3B3B3),
                                              ),
                                            ),
                                          ),
                                        SizedBox(width: s(10)),
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                standardBlockTitleText,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFFF2F2F2,
                                                  ),
                                                  fontSize: s(15),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                standardBlockSubtitleText,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFFB3B3B3,
                                                  ),
                                                  fontSize: s(12),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: s(21)),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: overlayLeftInset,
                        right: overlayRightInset,
                        bottom: overlaySafeBottom,
                      ),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            _selectedPayoutSchedule =
                                draftSelectedPayoutSchedule;
                            _standardPayoutIndex = draftStandardPayoutIndex;
                          });
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          height: s(60),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(s(15)),
                            border: Border.all(
                              color: const Color(0xFF007AFF),
                              width: s(1),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Speichern',
                            style: TextStyle(
                              color: const Color(0xFFF2F2F2),
                              fontSize: s(18),
                              fontWeight: FontWeight.bold,
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
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);
    double s(double value) => ui.s(value);
    final bool isDark = _resolveIsDark(context);
    final Color bgColor = isDark
        ? const Color(0xFF020202)
        : const Color(0xFFE6E6E6);
    final Color textColor = isDark
        ? const Color(0xFFF2F2F2)
        : const Color(0xFF0D0D0D);

    if (widget.prewarm && widget.prewarmPhase == 0) {
      return _PaymentsWarmupPhaseOnePage(
        s: s,
        bgColor: bgColor,
        textColor: textColor,
        paymentMethods: _paymentMethods,
      );
    }

    if (widget.prewarm && widget.prewarmPhase == 1) {
      return _PaymentsWarmupPhaseTwoPage(
        s: s,
        bgColor: bgColor,
        textColor: textColor,
        payoutCard: _payoutCards.first,
      );
    }

    final _PayoutCardContent currentCard = _payoutCards[_selectedPayoutIndex];
    final bool isGiftCard = _selectedPayoutIndex == 2;
    final double statusRowHeight = s(33);
    final double cardContentBottomPadding = s(8);
    final double giftCardLabelOffsetY = s(-15);
    final double payoutToggleBarHeight = s(39);
    final double payoutToggleButtonHeight = s(27);
    final double payoutToggleTapHeight = math.max(44, payoutToggleBarHeight);
    final bool isManualSelected = _selectedPayoutSchedule == 1;
    const Color standardHighlightColor = Color(0xFF1EACFF);
    final String? standardPayoutName = _standardPayoutIndex == 0
        ? 'PayPal'
        : _standardPayoutIndex == 1
        ? 'Visa'
        : null;
    const String addPaymentLabel = 'Hinzufügen';
    const String paymentMethodHintText =
        'Gedrückt halten, um als Standard festzulegen';
    final DateTime nextPayoutDate = _firstDayOfNextMonth(DateTime.now());
    final String shortMonthLabel = _formatShortMonth(nextPayoutDate, context);
    final String normalizedShortMonthLabel = shortMonthLabel.endsWith('.')
        ? shortMonthLabel.substring(0, shortMonthLabel.length - 1)
        : shortMonthLabel;
    final String nextPayoutLabel =
        '${nextPayoutDate.day}. $normalizedShortMonthLabel.';
    final bool hasStandardPayout = standardPayoutName != null;
    final String nextPayoutText = isManualSelected
        ? (hasStandardPayout ? '$standardPayoutName Manuell' : 'Auswählen')
        : (hasStandardPayout
              ? '$standardPayoutName $nextPayoutLabel'
              : 'Auswählen');
    final TextStyle paymentMethodLabelStyle = TextStyle(
      color: const Color(0xFFE6E6E6),
      fontSize: s(11),
      fontWeight: FontWeight.normal,
    );
    final TextStyle paymentMethodHintStyle = TextStyle(
      color: const Color(0xFFB3B3B3),
      fontSize: s(12),
      fontWeight: FontWeight.normal,
    );
    final TextStyle paymentMethodHintTextStyle = paymentMethodHintStyle
        .copyWith(height: 1);
    final TextDirection textDirection = Directionality.of(context);
    double measureLabelWidth(String text) {
      if (!isInitialContentReady) {
        return 0;
      }
      final painter = TextPainter(
        text: TextSpan(text: text, style: paymentMethodLabelStyle),
        textDirection: textDirection,
      )..layout();
      return painter.width;
    }

    final double paymentMethodTriangleSize = s(12);
    final double paymentMethodIconSize = s(50);
    final double paymentMethodSpacing = s(12);

    final List<double> paymentMethodColumnWidths = isInitialContentReady
        ? _paymentMethods.map((method) {
            final double labelWidth = measureLabelWidth(method.semanticsLabel);
            return labelWidth > paymentMethodIconSize
                ? labelWidth
                : paymentMethodIconSize;
          }).toList()
        : const <double>[];
    final double plusLabelWidth = isInitialContentReady
        ? measureLabelWidth(addPaymentLabel)
        : 0;
    final double plusColumnWidth = plusLabelWidth > paymentMethodIconSize
        ? plusLabelWidth
        : paymentMethodIconSize;
    final int payPalIndex = _paymentMethods.indexWhere(
      (method) => method.semanticsLabel == 'PayPal',
    );
    final int targetIndex = payPalIndex == -1 ? 0 : payPalIndex;
    double offset = plusColumnWidth + paymentMethodSpacing;
    if (isInitialContentReady) {
      for (int i = 0; i < targetIndex; i++) {
        final double labelWidth = measureLabelWidth(
          _paymentMethods[i].semanticsLabel,
        );
        final double columnWidth = labelWidth > paymentMethodIconSize
            ? labelWidth
            : paymentMethodIconSize;
        offset += columnWidth + paymentMethodSpacing;
      }
    }
    final double targetLabelWidth = isInitialContentReady
        ? measureLabelWidth(_paymentMethods[targetIndex].semanticsLabel)
        : paymentMethodIconSize;
    final double targetColumnWidth = targetLabelWidth > paymentMethodIconSize
        ? targetLabelWidth
        : paymentMethodIconSize;
    final double paymentMethodTriangleLeft =
        offset + (targetColumnWidth / 2) - (paymentMethodTriangleSize / 2);

    return Stack(
      children: [
        AbsorbPointer(
          absorbing: _isPayoutProcessing,
          child: Scaffold(
            backgroundColor: bgColor,
            appBar: AppBar(
              backgroundColor: bgColor,
              foregroundColor: textColor,
              elevation: 0,
              scrolledUnderElevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              centerTitle: true,
              titleSpacing: null,
              automaticallyImplyLeading: false,
              leading: ProfileDetailBackButton(
                color: textColor,
                iconSize: s(20),
              ),
              iconTheme: IconThemeData(color: textColor, size: s(20)),
              title: Text(
                'Zahlungen & Auszahlungen',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: s(20),
                ),
              ),
            ),
            body: SafeArea(
              top: false,
              left: true,
              right: true,
              bottom: false,
              child: isInitialContentReady
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        final EdgeInsetsGeometry scrollPadding =
                            EdgeInsets.symmetric(horizontal: s(16));
                        final EdgeInsets resolvedPadding = scrollPadding
                            .resolve(Directionality.of(context));
                        final double availableContentWidth =
                            constraints.maxWidth - resolvedPadding.horizontal;

                        // Padding Definition
                        final double hintHorizontalPadding = s(12);
                        final double hintRightPadding = s(15);

                        final double paymentMethodHintTopSpacing = s(12);
                        final double paymentMethodHintBottomSpacing = s(9);
                        final double paymentMethodHintVerticalPadding = s(6);

                        final TextPainter paymentMethodHintPainter =
                            TextPainter(
                              text: TextSpan(
                                text: paymentMethodHintText,
                                style: paymentMethodHintTextStyle,
                              ),
                              textDirection: textDirection,
                              maxLines: 1,
                            )..layout(
                              maxWidth: math.max(
                                0,
                                availableContentWidth -
                                    (hintHorizontalPadding + hintRightPadding),
                              ),
                            );

                        final double paymentMethodHintTextWidth =
                            paymentMethodHintPainter.width;
                        final double paymentMethodHintTextHeight =
                            paymentMethodHintPainter.height;

                        // KORREKTUR: Symmetrischer Puffer (s(3)) hinzugefügt, damit TextPainter-Breite sicher passt
                        final double paymentMethodHintBoxWidth = math.min(
                          availableContentWidth,
                          hintHorizontalPadding +
                              paymentMethodHintTextWidth.ceilToDouble() +
                              hintRightPadding +
                              s(7),
                        );

                        final double paymentMethodHintContainerHeight = math
                            .max(
                              s(25),
                              paymentMethodHintTextHeight +
                                  (paymentMethodHintVerticalPadding * 2),
                            );
                        final double paymentMethodFooterHeight =
                            paymentMethodHintTopSpacing +
                            paymentMethodHintContainerHeight +
                            paymentMethodHintBottomSpacing;

                        final Widget paymentMethodHintPopover = IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: _selectedPaymentMethodIndex == null
                                ? 1
                                : 0,
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeInOut,
                            child: SizedBox(
                              width: availableContentWidth,
                              height: paymentMethodFooterHeight,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    left: 0,
                                    top: paymentMethodHintTopSpacing,
                                    width: paymentMethodHintBoxWidth,
                                    child: Container(
                                      height: paymentMethodHintContainerHeight,
                                      alignment: Alignment.center,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: hintHorizontalPadding,
                                        vertical:
                                            paymentMethodHintVerticalPadding,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A1A1A),
                                        borderRadius: BorderRadius.circular(
                                          s(9),
                                        ),
                                      ),
                                      child: Text(
                                        paymentMethodHintText,
                                        style: paymentMethodHintTextStyle,
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow: TextOverflow.visible,
                                        textAlign: TextAlign.center,
                                        strutStyle: StrutStyle(
                                          fontSize:
                                              paymentMethodHintTextStyle
                                                  .fontSize ??
                                              s(12),
                                          height: 1,
                                          forceStrutHeight: true,
                                        ),
                                        textHeightBehavior:
                                            const TextHeightBehavior(
                                              applyHeightToFirstAscent: false,
                                              applyHeightToLastDescent: false,
                                            ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: paymentMethodTriangleLeft,
                                    top:
                                        paymentMethodHintTopSpacing -
                                        paymentMethodTriangleSize,
                                    child: CustomPaint(
                                      size: Size(
                                        paymentMethodTriangleSize,
                                        paymentMethodTriangleSize,
                                      ),
                                      painter: const _TrianglePainter(
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );

                        return StretchingOverscrollIndicator(
                          axisDirection: AxisDirection.down,
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            slivers: [
                              SliverPadding(
                                padding: scrollPadding,
                                sliver: SliverToBoxAdapter(
                                  child: RepaintBoundary(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        SizedBox(height: s(26)),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Zahlungen',
                                            style: TextStyle(
                                              color: const Color(0xFFF2F2F2),
                                              fontSize: s(20),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: s(16)),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Semantics(
                                                  button: true,
                                                  child: GestureDetector(
                                                    behavior:
                                                        HitTestBehavior.opaque,
                                                    onTapDown: (_) {},
                                                    onTapUp: (_) {},
                                                    onTapCancel: () {},
                                                    onTap: () {},
                                                    child: SizedBox(
                                                      width: plusColumnWidth,
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          _StatusCircle(
                                                            child: SFSymbolHelper.getIcon(
                                                              iconPath:
                                                                  'assets/icons/plus.svg',
                                                              width: s(28),
                                                              height: s(28),
                                                              color:
                                                                  const Color(
                                                                    0xFF000000,
                                                                  ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            height: s(6),
                                                          ),
                                                          FittedBox(
                                                            fit: BoxFit
                                                                .scaleDown,
                                                            child: Text(
                                                              addPaymentLabel,
                                                              style:
                                                                  paymentMethodLabelStyle,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: paymentMethodSpacing,
                                                ),
                                                for (
                                                  int index = 0;
                                                  index <
                                                      _paymentMethods.length;
                                                  index++
                                                ) ...[
                                                  SizedBox(
                                                    width:
                                                        paymentMethodColumnWidths[index],
                                                    child: Semantics(
                                                      button: true,
                                                      label:
                                                          _paymentMethods[index]
                                                              .semanticsLabel,
                                                      child: GestureDetector(
                                                        behavior:
                                                            HitTestBehavior
                                                                .opaque,
                                                        onTapDown: (_) =>
                                                            _startPaymentMethodPress(
                                                              index,
                                                            ),
                                                        onTapUp: (_) =>
                                                            _cancelPaymentMethodPress(),
                                                        onTapCancel:
                                                            _cancelPaymentMethodPress,
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            _StatusCircle(
                                                              borderColor:
                                                                  const Color(
                                                                    0xFF007AFF,
                                                                  ),
                                                              borderWidth: s(3),
                                                              showBorder:
                                                                  _selectedPaymentMethodIndex ==
                                                                  index,
                                                              showCheckmark:
                                                                  _selectedPaymentMethodIndex ==
                                                                  index, // Zeigt Haken & Einschnitt
                                                              child: SFSymbolHelper.getIcon(
                                                                iconPath:
                                                                    _paymentMethods[index]
                                                                        .iconPath,
                                                                width: s(28),
                                                                height: s(28),
                                                                color: _paymentMethods[index]
                                                                    .iconColor,
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              height: s(6),
                                                            ),
                                                            FittedBox(
                                                              fit: BoxFit
                                                                  .scaleDown,
                                                              child: Text(
                                                                _paymentMethods[index]
                                                                    .semanticsLabel,
                                                                style:
                                                                    paymentMethodLabelStyle,
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              height: s(2),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  if (index !=
                                                      _paymentMethods.length -
                                                          1)
                                                    SizedBox(
                                                      width:
                                                          paymentMethodSpacing,
                                                    ),
                                                ],
                                              ],
                                            ),
                                            paymentMethodHintPopover,
                                          ],
                                        ),
                                        SizedBox(height: s(3)),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Auszahlungen',
                                            style: TextStyle(
                                              color: const Color(0xFFF2F2F2),
                                              fontSize: s(20),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: s(3)),
                                        SizedBox(
                                          height: payoutToggleTapHeight,
                                          width: double.infinity,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Container(
                                                height: payoutToggleBarHeight,
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF0D0D0D,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        s(15),
                                                      ),
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: s(6),
                                                ),
                                                child: LayoutBuilder(
                                                  builder: (context, constraints) {
                                                    final double spacing = s(
                                                      12,
                                                    );
                                                    final double buttonWidth =
                                                        ((constraints.maxWidth -
                                                                    (spacing *
                                                                        2)) /
                                                                3)
                                                            .clamp(
                                                              0.0,
                                                              s(114.0),
                                                            )
                                                            .toDouble();
                                                    return Row(
                                                      children: [
                                                        _PayoutButton(
                                                          isSelected:
                                                              _selectedPayoutIndex ==
                                                              0,
                                                          label: 'PayPal',
                                                          width: buttonWidth,
                                                          tapHeight:
                                                              payoutToggleTapHeight,
                                                          visualHeight:
                                                              payoutToggleButtonHeight,
                                                          textColor:
                                                              isManualSelected &&
                                                                  _standardPayoutIndex ==
                                                                      0
                                                              ? standardHighlightColor
                                                              : const Color(
                                                                  0xFFF2F2F2,
                                                                ),
                                                          onTap: () => setState(
                                                            () =>
                                                                _selectedPayoutIndex =
                                                                    0,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: spacing,
                                                        ),
                                                        _PayoutButton(
                                                          isSelected:
                                                              _selectedPayoutIndex ==
                                                              1,
                                                          label: 'Visa',
                                                          width: buttonWidth,
                                                          tapHeight:
                                                              payoutToggleTapHeight,
                                                          visualHeight:
                                                              payoutToggleButtonHeight,
                                                          textColor:
                                                              isManualSelected &&
                                                                  _standardPayoutIndex ==
                                                                      1
                                                              ? standardHighlightColor
                                                              : const Color(
                                                                  0xFFF2F2F2,
                                                                ),
                                                          onTap: () => setState(
                                                            () =>
                                                                _selectedPayoutIndex =
                                                                    1,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: spacing,
                                                        ),
                                                        _PayoutButton(
                                                          isSelected:
                                                              _selectedPayoutIndex ==
                                                              2,
                                                          label: 'Gutschein',
                                                          width: buttonWidth,
                                                          tapHeight:
                                                              payoutToggleTapHeight,
                                                          visualHeight:
                                                              payoutToggleButtonHeight,
                                                          textColor:
                                                              const Color(
                                                                0xFFF2F2F2,
                                                              ),
                                                          onTap: () => setState(
                                                            () =>
                                                                _selectedPayoutIndex =
                                                                    2,
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: s(17)),
                                        SizedBox(
                                          height: s(204 + 93 - 20),
                                          width: double.infinity,
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Positioned(
                                                top: s(204 - 20),
                                                left: 0,
                                                right: 0,
                                                child: Container(
                                                  height: s(93),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFF1A1A1A,
                                                    ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFF373737,
                                                      ),
                                                      width: s(1),
                                                    ),
                                                    borderRadius: BorderRadius.only(
                                                      topLeft:
                                                          const Radius.circular(
                                                            0,
                                                          ),
                                                      topRight:
                                                          const Radius.circular(
                                                            0,
                                                          ),
                                                      bottomLeft:
                                                          Radius.circular(
                                                            s(20),
                                                          ),
                                                      bottomRight:
                                                          Radius.circular(
                                                            s(20),
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              if (_selectedPayoutIndex == 2)
                                                Positioned(
                                                  top: s(204 + 13),
                                                  left: s(17),
                                                  right: s(17),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            currentCard
                                                                .minLabel,
                                                            style: TextStyle(
                                                              color:
                                                                  HSLColor.fromAHSL(
                                                                    0.88,
                                                                    0,
                                                                    0,
                                                                    0.95,
                                                                  ).toColor(),
                                                              fontSize: s(12.5),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            height: s(3),
                                                          ),
                                                          Text(
                                                            currentCard
                                                                .minAmount,
                                                            style: TextStyle(
                                                              color:
                                                                  const Color.fromRGBO(
                                                                    242,
                                                                    242,
                                                                    242,
                                                                    0.51,
                                                                  ),
                                                              fontSize: s(20),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(width: s(20)),
                                                      Expanded(
                                                        child: Text(
                                                          'Der Gutschein unterliegt den Einlösebedingungen von Amazon.de.\nAmazon ist keine Partei dieser Aktion.',
                                                          style: TextStyle(
                                                            color: const Color(
                                                              0xFFF2F2F2,
                                                            ),
                                                            fontSize: s(11),
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              else
                                                Positioned(
                                                  top: s(204 + 13),
                                                  left: s(17),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            currentCard
                                                                .minLabel,
                                                            style: TextStyle(
                                                              color:
                                                                  HSLColor.fromAHSL(
                                                                    0.88,
                                                                    0,
                                                                    0,
                                                                    0.95,
                                                                  ).toColor(),
                                                              fontSize: s(12.5),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            height: s(3),
                                                          ),
                                                          Text(
                                                            currentCard
                                                                .minAmount,
                                                            style: TextStyle(
                                                              color:
                                                                  const Color.fromRGBO(
                                                                    242,
                                                                    242,
                                                                    242,
                                                                    0.51,
                                                                  ),
                                                              fontSize: s(20),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      if (currentCard
                                                          .nextLabel
                                                          .isNotEmpty) ...[
                                                        SizedBox(width: s(50)),
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              currentCard
                                                                  .nextLabel,
                                                              style: TextStyle(
                                                                color:
                                                                    HSLColor.fromAHSL(
                                                                      0.88,
                                                                      0,
                                                                      0,
                                                                      0.95,
                                                                    ).toColor(),
                                                                fontSize: s(
                                                                  12.5,
                                                                ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              height: s(3),
                                                            ),
                                                            if (_selectedPayoutIndex ==
                                                                    0 ||
                                                                _selectedPayoutIndex ==
                                                                    1)
                                                              Text(
                                                                nextPayoutText,
                                                                style: TextStyle(
                                                                  color:
                                                                      const Color.fromRGBO(
                                                                        242,
                                                                        242,
                                                                        242,
                                                                        0.51,
                                                                      ),
                                                                  fontSize: s(
                                                                    20,
                                                                  ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              if (_selectedPayoutIndex == 0 ||
                                                  _selectedPayoutIndex == 1)
                                                Positioned(
                                                  top: s(220),
                                                  right: s(10),
                                                  child: Semantics(
                                                    button: true,
                                                    child: GestureDetector(
                                                      behavior: HitTestBehavior
                                                          .opaque,
                                                      onTap: _showFilterOverlay,
                                                      child: SizedBox(
                                                        width: 44,
                                                        height: 44,
                                                        child: Center(
                                                          child: SFSymbolHelper.getIcon(
                                                            iconPath:
                                                                'square.and.pencil.circle.fill',
                                                            height: s(36),
                                                            width: s(36),
                                                            color:
                                                                const Color.fromARGB(
                                                                  230,
                                                                  230,
                                                                  230,
                                                                  230,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              Container(
                                                key: ValueKey<int>(
                                                  _selectedPayoutIndex,
                                                ),
                                                height: s(204),
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF1A1A1A,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        s(18),
                                                      ),
                                                  border: Border.all(
                                                    width: s(1),
                                                    color: const Color(
                                                      0xFF007AFF,
                                                    ),
                                                  ),
                                                ),
                                                child: Stack(
                                                  children: [
                                                    Padding(
                                                      padding: EdgeInsets.fromLTRB(
                                                        s(16),
                                                        s(16),
                                                        s(13),
                                                        cardContentBottomPadding,
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            currentCard.title,
                                                            style: TextStyle(
                                                              color:
                                                                  const Color(
                                                                    0xFFF2F2F2,
                                                                  ),
                                                              fontSize: s(23),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Text(
                                                                currentCard
                                                                    .amount,
                                                                style: TextStyle(
                                                                  color: const Color(
                                                                    0xFFF2F2F2,
                                                                  ),
                                                                  fontSize: s(
                                                                    25,
                                                                  ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                height: s(0),
                                                              ),
                                                              SizedBox(
                                                                height:
                                                                    statusRowHeight,
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        SFSymbolHelper.getIcon(
                                                                          iconPath:
                                                                              'assets/icons/checkmark.seal.fill.svg',
                                                                          width: s(
                                                                            18,
                                                                          ),
                                                                          height: s(
                                                                            18,
                                                                          ),
                                                                          color: const Color(
                                                                            0xFF04C40A,
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              s(
                                                                                6,
                                                                              ),
                                                                        ),
                                                                        Text(
                                                                          currentCard
                                                                              .statusText,
                                                                          style: TextStyle(
                                                                            color: const Color(
                                                                              0xFFB3B3B3,
                                                                            ),
                                                                            fontSize: s(
                                                                              16,
                                                                            ),
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    _buildBottomRightContent(
                                                                      ui,
                                                                      rowHeight:
                                                                          statusRowHeight,
                                                                      isGiftCard:
                                                                          isGiftCard,
                                                                      giftCardOffsetY:
                                                                          giftCardLabelOffsetY,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: s(9),
                                                      right: s(9),
                                                      child: Container(
                                                        constraints:
                                                            BoxConstraints(
                                                              minWidth: s(98),
                                                            ),
                                                        height: s(23),
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: s(6),
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors
                                                              .transparent,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                s(9),
                                                              ),
                                                          border: Border.all(
                                                            color: const Color(
                                                              0xFF007AFF,
                                                            ),
                                                            width: s(1),
                                                          ),
                                                        ),
                                                        alignment:
                                                            Alignment.center,
                                                        child: Text(
                                                          currentCard.feeLabel,
                                                          style: TextStyle(
                                                            color: const Color(
                                                              0xFF007AFF,
                                                            ),
                                                            fontSize: s(15),
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isManualSelected &&
                                            _standardPayoutIndex != null) ...[
                                          SizedBox(height: s(26)),
                                          ProfileDetailSwipeBackGestureBlocker(
                                            child: SizedBox(
                                              height: s(60),
                                              width: double.infinity,
                                              child: LayoutBuilder(
                                                builder: (context, constraints) {
                                                  final double handleWidth = s(
                                                    60,
                                                  );
                                                  final double handleRadius =
                                                      -s(15);
                                                  final double
                                                  handleCornerRadius = s(15);
                                                  final double
                                                  rightCornerTransition = s(24);
                                                  final double maxOffset =
                                                      (constraints.maxWidth -
                                                              handleWidth)
                                                          .clamp(
                                                            0.0,
                                                            double.infinity,
                                                          );
                                                  final double snapThreshold =
                                                      (maxOffset - handleWidth)
                                                          .clamp(
                                                            0.0,
                                                            maxOffset,
                                                          );
                                                  final double clampedOffset =
                                                      _payoutSwipeOffset.clamp(
                                                        0.0,
                                                        maxOffset,
                                                      );
                                                  final double
                                                  rightCornerProgress =
                                                      (clampedOffset /
                                                              rightCornerTransition)
                                                          .clamp(0.0, 1.0);
                                                  final double
                                                  rightCornerRadius =
                                                      handleCornerRadius *
                                                      rightCornerProgress;
                                                  final double maxTrailWidth =
                                                      (maxOffset - handleRadius)
                                                          .clamp(
                                                            0.0,
                                                            constraints
                                                                .maxWidth,
                                                          );
                                                  final double trailWidth =
                                                      (clampedOffset -
                                                              handleRadius)
                                                          .clamp(
                                                            0.0,
                                                            maxTrailWidth,
                                                          );
                                                  return Semantics(
                                                    button: true,
                                                    label:
                                                        'Wischen zum Auszahlen',
                                                    child: Listener(
                                                      onPointerDown: (_) {
                                                        if (!_showSwipeEndCap) {
                                                          setState(() {
                                                            _showSwipeEndCap =
                                                                true;
                                                          });
                                                        }
                                                      },
                                                      onPointerUp: (_) {
                                                        if (_payoutSwipeOffset <=
                                                                0 &&
                                                            _showSwipeEndCap &&
                                                            !_isPayoutProcessing) {
                                                          setState(() {
                                                            _showSwipeEndCap =
                                                                false;
                                                          });
                                                        }
                                                      },
                                                      onPointerCancel: (_) {
                                                        if (_payoutSwipeOffset <=
                                                                0 &&
                                                            _showSwipeEndCap &&
                                                            !_isPayoutProcessing) {
                                                          setState(() {
                                                            _showSwipeEndCap =
                                                                false;
                                                          });
                                                        }
                                                      },
                                                      child: GestureDetector(
                                                        behavior:
                                                            HitTestBehavior
                                                                .opaque,
                                                        onHorizontalDragStart: (_) {
                                                          _swipeSnapController
                                                              .stop();
                                                          setState(() {
                                                            _swipeSnapAnimation =
                                                                null;
                                                            _pendingHapticOnSnap =
                                                                false;
                                                            _snapHapticTriggerOffset =
                                                                null;
                                                            _didTriggerSnapHaptic =
                                                                false;
                                                            _showSwipeEndCap =
                                                                true;
                                                          });
                                                        },
                                                        onHorizontalDragUpdate: (details) {
                                                          final double
                                                          nextOffset =
                                                              (_payoutSwipeOffset +
                                                                      details
                                                                          .delta
                                                                          .dx)
                                                                  .clamp(
                                                                    0.0,
                                                                    maxOffset,
                                                                  );
                                                          setState(() {
                                                            _payoutSwipeOffset =
                                                                nextOffset;
                                                            _showSwipeEndCap =
                                                                nextOffset > 0;
                                                          });
                                                        },
                                                        onHorizontalDragEnd: (details) {
                                                          final double
                                                          velocity =
                                                              details
                                                                  .primaryVelocity ??
                                                              0;
                                                          final double
                                                          projectedPosition =
                                                              _payoutSwipeOffset +
                                                              (velocity * 0.2);
                                                          bool shouldSnapToEnd =
                                                              projectedPosition >=
                                                              snapThreshold;
                                                          if (_payoutSwipeOffset >=
                                                                  snapThreshold &&
                                                              velocity > -500) {
                                                            shouldSnapToEnd =
                                                                true;
                                                          }

                                                          if (shouldSnapToEnd) {
                                                            _animateSwipeTo(
                                                              maxOffset,
                                                              triggerHaptic:
                                                                  true,
                                                              openPayoutPageAfterSnap:
                                                                  true,
                                                              curve: Curves
                                                                  .easeOutCubic,
                                                            );
                                                          } else {
                                                            _animateSwipeTo(
                                                              0,
                                                              curve: Curves
                                                                  .easeOutCubic,
                                                            );
                                                          }
                                                        },
                                                        onHorizontalDragCancel: () {
                                                          if (_payoutSwipeOffset >=
                                                              snapThreshold) {
                                                            _animateSwipeTo(
                                                              maxOffset,
                                                              triggerHaptic:
                                                                  true,
                                                              openPayoutPageAfterSnap:
                                                                  true,
                                                              curve: Curves
                                                                  .easeOutCubic,
                                                            );
                                                          } else {
                                                            _animateSwipeTo(
                                                              0,
                                                              curve: Curves
                                                                  .easeOutCubic,
                                                            );
                                                          }
                                                        },
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                s(15),
                                                              ),
                                                          child: Stack(
                                                            fit:
                                                                StackFit.expand,
                                                            alignment: Alignment
                                                                .center,
                                                            children: [
                                                              ColoredBox(
                                                                color:
                                                                    HSLColor.fromAHSL(
                                                                      0.3,
                                                                      211,
                                                                      1.0,
                                                                      0.50,
                                                                    ).toColor(),
                                                              ),
                                                              if (trailWidth >
                                                                  0)
                                                                Positioned(
                                                                  left: 0,
                                                                  top: 0,
                                                                  bottom: 0,
                                                                  child: SizedBox(
                                                                    width:
                                                                        trailWidth,
                                                                    height: double
                                                                        .infinity,
                                                                    child: const ColoredBox(
                                                                      color: Color(
                                                                        0xFF007AFF,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              Positioned(
                                                                right: 0,
                                                                top: 0,
                                                                bottom: 0,
                                                                child: IgnorePointer(
                                                                  ignoring:
                                                                      !_showSwipeEndCap,
                                                                  child: AnimatedOpacity(
                                                                    opacity:
                                                                        _showSwipeEndCap
                                                                        ? 1
                                                                        : 0,
                                                                    duration: Duration(
                                                                      milliseconds:
                                                                          _showSwipeEndCap
                                                                          ? 160
                                                                          : 80,
                                                                    ),
                                                                    curve: Curves
                                                                        .easeInOut,
                                                                    child: SizedBox(
                                                                      width:
                                                                          handleWidth,
                                                                      height: double
                                                                          .infinity,
                                                                      child: DecoratedBox(
                                                                        decoration: BoxDecoration(
                                                                          color: HSLColor.fromAHSL(
                                                                            0.3,
                                                                            211,
                                                                            1.0,
                                                                            0.50,
                                                                          ).toColor(),
                                                                          border: Border.all(
                                                                            color: const Color(
                                                                              0xFFCCCCCC,
                                                                            ),
                                                                            width: s(
                                                                              1,
                                                                            ),
                                                                          ),
                                                                          borderRadius: BorderRadius.circular(
                                                                            s(
                                                                              15,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              Positioned.fill(
                                                                child: Center(
                                                                  child: Text(
                                                                    'Wischen zum Auszahlen',
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: TextStyle(
                                                                      color: const Color(
                                                                        0xFF4DAAFC,
                                                                      ),
                                                                      fontSize:
                                                                          s(16),
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              if (trailWidth >
                                                                  0)
                                                                Positioned.fill(
                                                                  child: ClipRect(
                                                                    clipper:
                                                                        _SwipeTrailClipper(
                                                                          trailWidth,
                                                                        ),
                                                                    child: Center(
                                                                      child: Text(
                                                                        'Wischen zum Auszahlen',
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                        style: TextStyle(
                                                                          color: const Color(
                                                                            0xFFF2F2F2,
                                                                          ),
                                                                          fontSize: s(
                                                                            16,
                                                                          ),
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              Positioned(
                                                                left:
                                                                    clampedOffset,
                                                                top: 0,
                                                                bottom: 0,
                                                                child: SizedBox(
                                                                  width:
                                                                      handleWidth,
                                                                  height: double
                                                                      .infinity,
                                                                  child: Container(
                                                                    decoration: BoxDecoration(
                                                                      color: const Color(
                                                                        0xFFD9D9D9,
                                                                      ),
                                                                      boxShadow:
                                                                          _payoutSwipeOffset >
                                                                              0
                                                                          ? [
                                                                              BoxShadow(
                                                                                color: HSLColor.fromAHSL(
                                                                                  0.25,
                                                                                  0,
                                                                                  0,
                                                                                  0,
                                                                                ).toColor(),
                                                                                offset: Offset(
                                                                                  -s(
                                                                                    3,
                                                                                  ),
                                                                                  0,
                                                                                ),
                                                                                blurRadius: s(
                                                                                  4,
                                                                                ),
                                                                                spreadRadius: 0,
                                                                              ),
                                                                            ]
                                                                          : [],
                                                                      borderRadius: BorderRadius.only(
                                                                        topLeft:
                                                                            Radius.circular(
                                                                              handleCornerRadius,
                                                                            ),
                                                                        bottomLeft:
                                                                            Radius.circular(
                                                                              handleCornerRadius,
                                                                            ),
                                                                        topRight:
                                                                            Radius.circular(
                                                                              rightCornerRadius,
                                                                            ),
                                                                        bottomRight:
                                                                            Radius.circular(
                                                                              rightCornerRadius,
                                                                            ),
                                                                      ),
                                                                    ),
                                                                    alignment:
                                                                        Alignment
                                                                            .centerRight,
                                                                    padding:
                                                                        EdgeInsets.only(
                                                                          right:
                                                                              s(
                                                                                5,
                                                                              ),
                                                                        ),
                                                                    child: SizedBox(
                                                                      width: s(
                                                                        45,
                                                                      ),
                                                                      height: s(
                                                                        34,
                                                                      ),
                                                                      child: Stack(
                                                                        clipBehavior:
                                                                            Clip.none,
                                                                        alignment:
                                                                            Alignment.centerLeft,
                                                                        children: [
                                                                          Positioned(
                                                                            left:
                                                                                0,
                                                                            child: ScaleTransition(
                                                                              scale: _firstSwipeChevronScale,
                                                                              child: SFSymbolHelper.getChevronRight(
                                                                                size: s(
                                                                                  28,
                                                                                ),
                                                                                color: HSLColor.fromAHSL(
                                                                                  0.59,
                                                                                  0,
                                                                                  0,
                                                                                  0.22,
                                                                                ).toColor(),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Positioned(
                                                                            left: s(
                                                                              9,
                                                                            ),
                                                                            child: ScaleTransition(
                                                                              scale: _secondSwipeChevronScale,
                                                                              child: SFSymbolHelper.getChevronRight(
                                                                                size: s(
                                                                                  28,
                                                                                ),
                                                                                color: const Color(
                                                                                  0xFF1A1A1A,
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
                                                              if (_isPayoutProcessing)
                                                                Positioned.fill(
                                                                  child: Center(
                                                                    child: SizedBox.square(
                                                                      dimension:
                                                                          s(22),
                                                                      child: CircularProgressIndicator(
                                                                        strokeWidth:
                                                                            s(
                                                                              2.5,
                                                                            ),
                                                                        color: const Color(
                                                                          0xFFF2F2F2,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: s(0)),
                                        ] else if (_standardPayoutIndex ==
                                            null) ...[
                                          SizedBox(height: s(26)),
                                          ProfileDetailSwipeBackGestureBlocker(
                                            child: Semantics(
                                              button: true,
                                              label:
                                                  'Jetzt Auszahlung hinzufügen',
                                              child: GestureDetector(
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                onTap: () {
                                                  if (_selectedPayoutIndex ==
                                                      2) {
                                                    setState(() {
                                                      _selectedPayoutIndex = 0;
                                                    });
                                                  }
                                                  _showFilterOverlay();
                                                },
                                                child: Container(
                                                  height: s(60),
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: HSLColor.fromAHSL(
                                                      0.3,
                                                      211,
                                                      1.0,
                                                      0.50,
                                                    ).toColor(),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          s(15),
                                                        ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    'Jetzt Auszahlung hinzufügen',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: const Color(
                                                        0xFF4DAAFC,
                                                      ),
                                                      fontSize: s(17),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: s(0)),
                                        ] else ...[
                                          SizedBox(height: s(0)),
                                        ],
                                        Semantics(
                                          button: true,
                                          label: 'Auszahlungshistorie ansehen',
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () {
                                              _pushWithFade(
                                                PayoutHistoryPage(
                                                  isDarkOverride: isDark,
                                                ),
                                              );
                                            },
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                minHeight: 44,
                                              ),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  'Auszahlungshistorie ansehen',
                                                  style: TextStyle(
                                                    color: const Color(
                                                      0xFFB3B3B3,
                                                    ),
                                                    fontSize: s(16),
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    decoration: TextDecoration
                                                        .underline,
                                                    decorationColor:
                                                        const Color(0xFFB3B3B3),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : _PaymentsPageSkeleton(s: s, isDark: isDark),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: _isPayoutProcessing ? 1 : 0,
              child: const ColoredBox(color: Color(0x33000000)),
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentsPageSkeleton extends StatelessWidget {
  const _PaymentsPageSkeleton({required this.s, required this.isDark});

  final double Function(double) s;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return StretchingOverscrollIndicator(
      axisDirection: AxisDirection.down,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(s(16), 0, s(16), s(20)),
        children: [
          SizedBox(height: s(26)),
          ProfileDetailSkeletonBlock(
            isDark: isDark,
            width: s(112),
            height: s(22),
            borderRadius: s(11),
          ),
          SizedBox(height: s(16)),
          ProfileDetailSkeletonBlock(
            isDark: isDark,
            height: s(102),
            borderRadius: s(18),
          ),
          SizedBox(height: s(18)),
          ProfileDetailSkeletonBlock(
            isDark: isDark,
            height: s(188),
            borderRadius: s(18),
          ),
          SizedBox(height: s(18)),
          ProfileDetailSkeletonBlock(
            isDark: isDark,
            height: s(138),
            borderRadius: s(18),
          ),
        ],
      ),
    );
  }
}

class _PaymentsWarmupPhaseOnePage extends StatelessWidget {
  const _PaymentsWarmupPhaseOnePage({
    required this.s,
    required this.bgColor,
    required this.textColor,
    required this.paymentMethods,
  });

  final double Function(double) s;
  final Color bgColor;
  final Color textColor;
  final List<_PaymentMethodData> paymentMethods;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleSpacing: null,
        title: Text(
          'Zahlungen & Auszahlungen',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: s(20),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        left: true,
        right: true,
        bottom: false,
        child: StretchingOverscrollIndicator(
          axisDirection: AxisDirection.down,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(s(16), 0, s(16), s(20)),
            children: [
              SizedBox(height: s(26)),
              Text(
                'Zahlungen',
                style: TextStyle(
                  color: textColor,
                  fontSize: s(20),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: s(16)),
              Row(
                children: [
                  SFSymbolHelper.getIcon(
                    iconPath: 'assets/icons/plus.circle.fill.svg',
                    width: s(50),
                    height: s(50),
                    color: Colors.white,
                  ),
                  SizedBox(width: s(12)),
                  for (final _PaymentMethodData method in paymentMethods) ...[
                    _StatusCircle(
                      borderColor: const Color(0xFF007AFF),
                      borderWidth: s(3),
                      showBorder: false,
                      showCheckmark: false,
                      child: SFSymbolHelper.getIcon(
                        iconPath: method.iconPath,
                        width: s(28),
                        height: s(28),
                        color: method.iconColor,
                      ),
                    ),
                    SizedBox(width: s(12)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentsWarmupPhaseTwoPage extends StatelessWidget {
  const _PaymentsWarmupPhaseTwoPage({
    required this.s,
    required this.bgColor,
    required this.textColor,
    required this.payoutCard,
  });

  final double Function(double) s;
  final Color bgColor;
  final Color textColor;
  final _PayoutCardContent payoutCard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleSpacing: null,
        title: Text(
          'Zahlungen & Auszahlungen',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: s(20),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        left: true,
        right: true,
        bottom: false,
        child: StretchingOverscrollIndicator(
          axisDirection: AxisDirection.down,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(s(16), 0, s(16), s(20)),
            children: [
              SizedBox(height: s(26)),
              Text(
                'Auszahlungen',
                style: TextStyle(
                  color: textColor,
                  fontSize: s(20),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: s(14)),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(s(16)),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(s(18)),
                  border: Border.all(
                    width: s(1),
                    color: const Color(0xFF007AFF),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payoutCard.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFFF2F2F2),
                        fontSize: s(24),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: s(6)),
                    Text(
                      payoutCard.amount,
                      style: TextStyle(
                        color: const Color(0xFFF2F2F2),
                        fontSize: s(30),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: s(14)),
                    Container(
                      height: s(45),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF),
                        borderRadius: BorderRadius.circular(s(15)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Wischen zum Auszahlen',
                            style: TextStyle(
                              color: const Color(0xFFF2F2F2),
                              fontSize: s(16),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: s(8)),
                          SFSymbolHelper.getChevronRight(
                            size: s(15),
                            color: const Color(0xFFF2F2F2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayoutCardContent {
  final String title;
  final String amount;
  final String statusText;
  final String feeLabel;
  final String minLabel;
  final String nextLabel;
  final String minAmount;

  const _PayoutCardContent({
    required this.title,
    required this.amount,
    required this.statusText,
    required this.feeLabel,
    required this.minLabel,
    required this.nextLabel,
    required this.minAmount,
  });
}

class _PaymentMethodData {
  final String iconPath;
  final Color? iconColor;
  final String semanticsLabel;
  const _PaymentMethodData({
    required this.iconPath,
    required this.semanticsLabel,
    this.iconColor,
  });
}

class _SwipeTrailClipper extends CustomClipper<Rect> {
  final double width;

  const _SwipeTrailClipper(this.width);
  @override
  Rect getClip(Size size) {
    final double clampedWidth = width.clamp(0.0, size.width);
    return Rect.fromLTWH(0, 0, clampedWidth, size.height);
  }

  @override
  bool shouldReclip(covariant _SwipeTrailClipper oldClipper) {
    return oldClipper.width != width;
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  const _TrianglePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _StatusCircle extends StatelessWidget {
  final Widget? child;
  final Color? borderColor;
  final double? borderWidth;
  final bool showBorder;
  final bool showCheckmark;

  const _StatusCircle({
    this.child,
    this.borderColor,
    this.borderWidth,
    this.showBorder = false,
    this.showCheckmark = false,
  });

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);
    final double size = ui.s(50);
    final double strokeWidth = borderWidth ?? ui.s(1);

    // --- Nested Logik für den Haken ---
    const double iconSizeRaw = 15.0;
    final double iconSize = ui.s(iconSizeRaw);
    final double iconRadius = iconSize / 2;
    final double padding = ui.s(2.0); // Der Abstand für den "Einschnitt"

    // Ableitung der Kreisgröße: (Radius + Padding) * 2
    final double backgroundCircleSize = (iconRadius + padding) * 2;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Äußerer blauer Rahmen (Stroke)
          if (borderColor != null)
            Positioned(
              left: -strokeWidth,
              top: -strokeWidth,
              child: AnimatedOpacity(
                opacity: showBorder ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  width: size + (strokeWidth * 2),
                  height: size + (strokeWidth * 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor!, width: strokeWidth),
                  ),
                ),
              ),
            ),
          // Haupt-Kreis (Weiß/Grau)
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: Color(0xFFE6E6E6),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: child,
          ),
          // Der "Nested" Checkmark-Einschnitt unten rechts
          Positioned(
            // Positionierung so, dass der Einschnitt den Rand überlappt
            right: -ui.s(2),
            bottom: -ui.s(2),
            child: AnimatedOpacity(
              opacity: showCheckmark ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: IgnorePointer(
                ignoring: !showCheckmark,
                child: Container(
                  width: backgroundCircleSize,
                  height: backgroundCircleSize,
                  decoration: const BoxDecoration(
                    color: Color(
                      0xFF020202,
                    ), // Hintergrundfarbe für den Cut-out
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center, // Macht das Icon "nested"
                  child: SFSymbolHelper.getIcon(
                    iconPath: 'assets/icons/checkmark.circle.fill.svg',
                    width: iconSize,
                    height: iconSize,
                    color: const Color(0xFF007AFF),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayoutButton extends StatelessWidget {
  final double width;
  final bool isSelected;
  final VoidCallback onTap;
  final String label;
  final double tapHeight;
  final double visualHeight;
  final Color textColor;
  const _PayoutButton({
    required this.width,
    required this.isSelected,
    required this.onTap,
    required this.label,
    required this.tapHeight,
    required this.visualHeight,
    required this.textColor,
  });
  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: SizedBox(
          key: ValueKey<bool>(isSelected),
          width: width,
          height: tapHeight,
          child: Center(
            child: Container(
              width: width,
              height: visualHeight,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(ui.s(9)),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: ui.s(12),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
