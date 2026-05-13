import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'legal_page.dart';
import '../../liquid_glass/liquid_glass.dart';
import '../../services/sf_symbol_helper.dart';
import '../../services/ui_scale.dart';
import 'profile_detail_page_utils.dart';

enum _VerificationEntryKey { name, address, idCard, email, phone, twoFactor }

enum _VerificationStatus { unverified, pending, verified }

class VerificationPage extends StatefulWidget {
  static const Duration _progressAnimationDuration = Duration(
    milliseconds: 620,
  );

  const VerificationPage({
    super.key,
    this.completedSteps = 0,
    this.isDarkOverride,
    this.prewarm = false,
  }) : assert(completedSteps >= 0 && completedSteps <= 6);

  final int completedSteps;
  final bool? isDarkOverride;
  final bool prewarm;

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage>
    with ProfileDetailPerformanceMixin<VerificationPage> {
  static const Set<String> _verificationWarmupIconPaths = <String>{
    'assets/icons/checkmark.circle.fill.svg',
    'assets/icons/checkmark.seal.fill.svg',
    'assets/icons/close.svg',
  };
  int _selectedPayoutIndex = 0;
  bool _showVerificationInfoBox = true;
  bool _scheduledWarmup = false;
  static const List<_VerificationEntryKey> _progressOrder = [
    _VerificationEntryKey.name,
    _VerificationEntryKey.address,
    _VerificationEntryKey.idCard,
    _VerificationEntryKey.email,
    _VerificationEntryKey.phone,
    _VerificationEntryKey.twoFactor,
  ];

  late final Map<_VerificationEntryKey, _VerificationStatus> _entryStatuses;

  @override
  String get profileDetailPerformanceLabel => 'VerificationPage';

  @override
  bool get deferHeavyContent => true;

  @override
  bool get isProfileDetailWarmup => widget.prewarm;

  static const List<_VerificationEntryData> _identityCards = [
    _VerificationEntryData(
      key: _VerificationEntryKey.name,
      title: 'Name',
      accessLabel: 'Privat',
      unverifiedStatusText: 'Noch nicht eingerichtet',
      verifiedStatusText: 'Bestätigt',
    ),
    _VerificationEntryData(
      key: _VerificationEntryKey.address,
      title: 'Adresse',
      accessLabel: 'Privat',
      unverifiedStatusText: 'Noch nicht eingerichtet',
      verifiedStatusText: 'Hinterlegt',
    ),
    _VerificationEntryData(
      key: _VerificationEntryKey.idCard,
      title: 'Ausweis',
      accessLabel: 'Privat',
      unverifiedStatusText: 'Noch nicht eingerichtet',
      verifiedStatusText: 'Geprüft',
      pendingStatusText: 'Wird geprüft',
    ),
  ];

  static const List<_VerificationEntryData> _contactCards = [
    _VerificationEntryData(
      key: _VerificationEntryKey.email,
      title: 'E-Mail-Adresse',
      accessLabel: 'Privat',
      unverifiedStatusText: 'Noch nicht eingerichtet',
      verifiedStatusText: 'Bestätigt',
    ),
    _VerificationEntryData(
      key: _VerificationEntryKey.phone,
      title: 'Telefonnummer',
      accessLabel: 'Privat',
      unverifiedStatusText: 'Noch nicht eingerichtet',
      verifiedStatusText: 'Bestätigt',
    ),
  ];

  static const List<_VerificationEntryData> _securityCards = [
    _VerificationEntryData(
      key: _VerificationEntryKey.twoFactor,
      title: '2FA',
      accessLabel: 'Privat',
      unverifiedStatusText: 'Noch nicht eingerichtet',
      verifiedStatusText: 'Aktiviert',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entryStatuses = {
      for (final _VerificationEntryKey key in _progressOrder)
        key: _VerificationStatus.unverified,
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduledWarmup) {
      return;
    }

    _scheduledWarmup = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        SFSymbolHelper.precacheIcons(context, _verificationWarmupIconPaths),
      );
    });
  }

  List<_VerificationEntryData> _cardsForSelectedTab() {
    switch (_selectedPayoutIndex) {
      case 0:
        return _identityCards;
      case 1:
        return _contactCards;
      default:
        return _securityCards;
    }
  }

  int _countCompletedSteps() {
    return _entryStatuses.values
        .where((status) => status == _VerificationStatus.verified)
        .length;
  }

  _VerificationStatus _statusFor(_VerificationEntryData entry) {
    return _entryStatuses[entry.key] ?? _VerificationStatus.unverified;
  }

  String _statusTextFor(_VerificationEntryData entry) {
    switch (_statusFor(entry)) {
      case _VerificationStatus.verified:
        return entry.verifiedStatusText;
      case _VerificationStatus.pending:
        return entry.pendingStatusText ?? entry.unverifiedStatusText;
      case _VerificationStatus.unverified:
        return entry.unverifiedStatusText;
    }
  }

  void _handleVerificationTap(_VerificationEntryData entry) {
    if (_statusFor(entry) == _VerificationStatus.verified) {
      return;
    }
    setState(() {
      _entryStatuses[entry.key] = _VerificationStatus.verified;
    });
  }

  void _openLegalPage() {
    final bool isDark =
        widget.isDarkOverride ??
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    Navigator.of(context).push(
      buildProfileDetailFadeRoute<void>(
        page: LegalPage(isDarkOverride: isDark),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);
    double s(double value) => ui.s(value);
    final TextScaler textScaler = MediaQuery.textScalerOf(context);
    final bool isDark =
        widget.isDarkOverride ??
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final EdgeInsets viewPadding = MediaQuery.of(context).viewPadding;
    final Color bgColor = isDark
        ? const Color(0xFF020202)
        : const Color(0xFFE6E6E6);
    final Color cardColor = isDark
        ? const Color(0xFF0D0D0D)
        : const Color(0xFFF2F2F2);
    final Color cardColorActive = isDark
        ? const Color(0xFF1A1A1A)
        : Colors.white;
    final Color textColor = isDark
        ? const Color(0xFFF2F2F2)
        : const Color(0xFF0D0D0D);
    final Color secondaryTextColor = isDark
        ? const Color(0xFFB3B3B3)
        : const Color(0xFF4D4D4D);
    final Color dividerColor = isDark
        ? const Color(0xFF1B1B1B)
        : const Color(0xFFE2E2E2);
    const int totalSteps = 6;
    final int completedSteps = _countCompletedSteps();
    final bool isVerificationComplete = completedSteps == totalSteps;
    final double progress = completedSteps / totalSteps;
    final double payoutToggleBarHeight = s(39);
    final double payoutToggleButtonHeight = s(27);
    final double payoutToggleTapHeight = math.max(44, payoutToggleBarHeight);
    final double infoBoxGap = s(19);
    final double infoBottomInset = viewPadding.bottom;
    final double infoContentInsetTop = math.max(9.0, s(9));
    final double infoContentInsetBottom = math.max(9.0, s(14));
    final double infoContentInsetLeft = math.max(9.0, s(9));
    const String infoTitleText = 'Hinweis zur Verifizierung';
    const String infoDescriptionPrefix =
        'Verifizierungsdetails siehst nur du. Andere sehen nur\ndeinen Status. Mehr in der ';
    const String infoDescriptionLinkText = 'Datenschutzerklärung';
    const String infoDescriptionSuffix = '.';
    final TextStyle infoTitleStyle = TextStyle(
      color: const Color(0xFFBCBCBC),
      fontSize: s(15),
      fontWeight: FontWeight.w600,
    );
    final TextStyle infoDescriptionStyle = TextStyle(
      color: const Color(0xFF747474),
      fontSize: s(11.5),
      fontWeight: FontWeight.w600,
    );
    final TextStyle infoDescriptionLinkStyle = infoDescriptionStyle.copyWith(
      color: const Color(0xFF4DAAFC),
      decoration: TextDecoration.underline,
      decorationColor: const Color(0xFF4DAAFC),
    );
    final String progressTitleText = isVerificationComplete
        ? 'Verifizierung abgeschlossen'
        : 'Fortschritt';
    final String progressDescriptionText = isVerificationComplete
        ? 'Alle Angaben wurden\nerfolgreich eingerichtet.'
        : '$completedSteps von $totalSteps abgeschlossen';
    final List<_VerificationEntryData> cards = _cardsForSelectedTab();
    final Color verificationActionButtonColor = HSLColor.fromAHSL(
      0.30,
      211,
      1,
      0.5,
    ).toColor();
    final Color verifiedActionButtonColor = const Color(0xFF1A1A1A);

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
        automaticallyImplyLeading: false,
        leading: ProfileDetailBackButton(color: textColor, iconSize: ui.s(20)),
        iconTheme: IconThemeData(color: textColor, size: ui.s(20)),
        title: Text(
          'Verifizierung',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: ui.s(20),
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
                builder: (context, _) {
                  final TextPainter infoTitlePainter = TextPainter(
                    text: TextSpan(text: infoTitleText, style: infoTitleStyle),
                    textDirection: Directionality.of(context),
                    textScaler: textScaler,
                    maxLines: 1,
                  )..layout();
                  final TextSpan infoDescriptionSpan = TextSpan(
                    style: infoDescriptionStyle,
                    children: [
                      const TextSpan(text: infoDescriptionPrefix),
                      TextSpan(
                        text: infoDescriptionLinkText,
                        style: infoDescriptionLinkStyle,
                      ),
                      const TextSpan(text: infoDescriptionSuffix),
                    ],
                  );
                  final TextPainter infoDescriptionPainter = TextPainter(
                    text: infoDescriptionSpan,
                    textDirection: Directionality.of(context),
                    textScaler: textScaler,
                    maxLines: 3,
                  )..layout();
                  final int infoDescriptionLinkStart =
                      infoDescriptionPrefix.length;
                  final int infoDescriptionLinkEnd =
                      infoDescriptionLinkStart + infoDescriptionLinkText.length;
                  final List<TextBox> infoDescriptionLinkBoxes =
                      infoDescriptionPainter.getBoxesForSelection(
                        TextSelection(
                          baseOffset: infoDescriptionLinkStart,
                          extentOffset: infoDescriptionLinkEnd,
                        ),
                      );
                  Rect infoDescriptionLinkRect = Rect.zero;
                  for (final TextBox box in infoDescriptionLinkBoxes) {
                    final Rect boxRect = box.toRect();
                    infoDescriptionLinkRect =
                        infoDescriptionLinkRect == Rect.zero
                        ? boxRect
                        : infoDescriptionLinkRect.expandToInclude(boxRect);
                  }
                  final double infoDescriptionTopOffset =
                      s(17) + s(7) + infoTitlePainter.height + s(2);
                  final Rect infoDescriptionLinkRectInInfoBox =
                      infoDescriptionLinkRect == Rect.zero
                      ? Rect.zero
                      : infoDescriptionLinkRect.shift(
                          Offset(
                            infoContentInsetLeft,
                            infoContentInsetTop + infoDescriptionTopOffset,
                          ),
                        );
                  final Rect infoDescriptionLinkTapRect =
                      infoDescriptionLinkRectInInfoBox == Rect.zero
                      ? Rect.zero
                      : Rect.fromCenter(
                          center: infoDescriptionLinkRectInInfoBox.center,
                          width: infoDescriptionLinkRectInInfoBox.width,
                          height: math.max(
                            44.0,
                            infoDescriptionLinkRectInInfoBox.height,
                          ),
                        );
                  final double infoContentHeight =
                      s(17) +
                      s(7) +
                      infoTitlePainter.height +
                      s(2) +
                      infoDescriptionPainter.height;
                  final double infoBoxHeight =
                      (infoContentInsetTop +
                              infoContentHeight +
                              infoContentInsetBottom)
                          .ceilToDouble();
                  final double infoBottomExtra = _showVerificationInfoBox
                      ? infoBoxGap + infoBoxHeight + infoBottomInset
                      : 0;
                  final EdgeInsetsGeometry scrollPadding = EdgeInsets.fromLTRB(
                    s(16),
                    0,
                    s(16),
                    s(20) + infoBottomExtra,
                  );

                  double measureTextWidth(String text, TextStyle style) {
                    final TextPainter painter = TextPainter(
                      text: TextSpan(text: text, style: style),
                      textDirection: Directionality.of(context),
                      textScaler: textScaler,
                      maxLines: 1,
                    )..layout();
                    return painter.width;
                  }

                  return Stack(
                    children: [
                      StretchingOverscrollIndicator(
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
                                      Container(
                                        width: double.infinity,
                                        constraints: BoxConstraints(
                                          minHeight: s(100),
                                        ),
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              top: 0,
                                              left: 0,
                                              right: s(49.5),
                                              bottom: 0,
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  color: cardColor,
                                                  borderRadius:
                                                      BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(
                                                              s(15),
                                                            ),
                                                        bottomLeft:
                                                            Radius.circular(
                                                              s(15),
                                                            ),
                                                      ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 0,
                                              right: 0,
                                              bottom: 0,
                                              width: s(99),
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  color: cardColor,
                                                  borderRadius:
                                                      BorderRadius.only(
                                                        topRight:
                                                            Radius.circular(
                                                              s(49.5),
                                                            ),
                                                        bottomRight:
                                                            Radius.circular(
                                                              s(49.5),
                                                            ),
                                                      ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.fromLTRB(
                                                s(25),
                                                s(11.5),
                                                s(11),
                                                s(11.5),
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          progressTitleText,
                                                          style: TextStyle(
                                                            color: const Color(
                                                              0xFFB3B3B3,
                                                            ),
                                                            fontSize: s(16),
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                        SizedBox(height: s(4)),
                                                        Text(
                                                          progressDescriptionText,
                                                          style: TextStyle(
                                                            color: textColor,
                                                            fontSize: s(16),
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(width: s(12)),
                                                  if (isVerificationComplete)
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                        right: s(26),
                                                      ),
                                                      child: SizedBox(
                                                        width: s(26),
                                                        height: s(26),
                                                        child: SFSymbolHelper.getIcon(
                                                          iconPath:
                                                              'assets/icons/checkmark.circle.fill.svg',
                                                          width: s(26),
                                                          height: s(26),
                                                          color: const Color(
                                                            0xFF007AFF,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  else
                                                    SizedBox(
                                                      width: s(77),
                                                      height: s(77),
                                                      child: TweenAnimationBuilder<double>(
                                                        tween: Tween<double>(
                                                          end: progress,
                                                        ),
                                                        duration: VerificationPage
                                                            ._progressAnimationDuration,
                                                        curve: Curves
                                                            .easeInOutCubic,
                                                        builder:
                                                            (
                                                              context,
                                                              animatedProgress,
                                                              child,
                                                            ) {
                                                              final int
                                                              animatedPercent =
                                                                  (animatedProgress *
                                                                          100)
                                                                      .round();
                                                              return Stack(
                                                                fit: StackFit
                                                                    .expand,
                                                                children: [
                                                                  CustomPaint(
                                                                    painter: _VerificationProgressRingPainter(
                                                                      progress:
                                                                          animatedProgress,
                                                                      baseColor:
                                                                          const Color(
                                                                            0xFFB3B3B3,
                                                                          ),
                                                                      progressColor:
                                                                          const Color(
                                                                            0xFF4DAAFC,
                                                                          ),
                                                                      strokeWidth:
                                                                          s(3),
                                                                    ),
                                                                  ),
                                                                  Center(
                                                                    child: Text(
                                                                      '$animatedPercent%',
                                                                      style: TextStyle(
                                                                        color:
                                                                            textColor,
                                                                        fontSize:
                                                                            s(
                                                                              18,
                                                                            ),
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
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
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: s(11)),
                                      Container(
                                        width: double.infinity,
                                        height: s(1),
                                        color: dividerColor,
                                      ),
                                      SizedBox(height: s(14)),
                                      SizedBox(
                                        height: payoutToggleTapHeight,
                                        width: double.infinity,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              height: payoutToggleBarHeight,
                                              decoration: BoxDecoration(
                                                color: cardColor,
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
                                                  final double spacing = s(12);
                                                  final double buttonWidth =
                                                      ((constraints.maxWidth -
                                                                  (spacing *
                                                                      2)) /
                                                              3)
                                                          .clamp(0.0, s(114))
                                                          .toDouble();
                                                  return Row(
                                                    children: [
                                                      _VerificationOptionButton(
                                                        width: buttonWidth,
                                                        isSelected:
                                                            _selectedPayoutIndex ==
                                                            0,
                                                        onTap: () => setState(
                                                          () =>
                                                              _selectedPayoutIndex =
                                                                  0,
                                                        ),
                                                        label: 'Identität',
                                                        tapHeight:
                                                            payoutToggleTapHeight,
                                                        visualHeight:
                                                            payoutToggleButtonHeight,
                                                        textColor: textColor,
                                                        selectedColor:
                                                            cardColorActive,
                                                        unselectedColor:
                                                            cardColor,
                                                      ),
                                                      SizedBox(width: spacing),
                                                      _VerificationOptionButton(
                                                        width: buttonWidth,
                                                        isSelected:
                                                            _selectedPayoutIndex ==
                                                            1,
                                                        onTap: () => setState(
                                                          () =>
                                                              _selectedPayoutIndex =
                                                                  1,
                                                        ),
                                                        label: 'Kontakt',
                                                        tapHeight:
                                                            payoutToggleTapHeight,
                                                        visualHeight:
                                                            payoutToggleButtonHeight,
                                                        textColor: textColor,
                                                        selectedColor:
                                                            cardColorActive,
                                                        unselectedColor:
                                                            cardColor,
                                                      ),
                                                      SizedBox(width: spacing),
                                                      _VerificationOptionButton(
                                                        width: buttonWidth,
                                                        isSelected:
                                                            _selectedPayoutIndex ==
                                                            2,
                                                        onTap: () => setState(
                                                          () =>
                                                              _selectedPayoutIndex =
                                                                  2,
                                                        ),
                                                        label: 'Sicherheit',
                                                        tapHeight:
                                                            payoutToggleTapHeight,
                                                        visualHeight:
                                                            payoutToggleButtonHeight,
                                                        textColor: textColor,
                                                        selectedColor:
                                                            cardColorActive,
                                                        unselectedColor:
                                                            cardColor,
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: s(20)),
                                      _VerificationEntryGroup(
                                        color: cardColor,
                                        borderRadius: s(15),
                                        children: [
                                          for (final MapEntry<
                                                int,
                                                _VerificationEntryData
                                              >
                                              cardEntry
                                              in cards.asMap().entries)
                                            VerifizierungCard(
                                              title: cardEntry.value.title,
                                              statusText: _statusTextFor(
                                                cardEntry.value,
                                              ),
                                              accessLabel:
                                                  cardEntry.value.accessLabel,
                                              color: cardColor,
                                              textColor: textColor,
                                              buttonColor:
                                                  _statusFor(cardEntry.value) ==
                                                      _VerificationStatus
                                                          .verified
                                                  ? verifiedActionButtonColor
                                                  : verificationActionButtonColor,
                                              statusTextColor:
                                                  secondaryTextColor,
                                              buttonTextColor:
                                                  _statusFor(cardEntry.value) ==
                                                      _VerificationStatus
                                                          .verified
                                                  ? const Color(0xFFF2F2F2)
                                                  : const Color(0xFF4DAAFC),
                                              buttonLabel:
                                                  _statusFor(cardEntry.value) ==
                                                      _VerificationStatus
                                                          .verified
                                                  ? 'Bearbeiten'
                                                  : 'Verifizieren',
                                              onButtonTap: () =>
                                                  _handleVerificationTap(
                                                    cardEntry.value,
                                                  ),
                                              showVerified: true,
                                              embedInGroup: true,
                                              showDivider:
                                                  cardEntry.key !=
                                                  cards.length - 1,
                                              dividerColor: dividerColor,
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: s(20)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_showVerificationInfoBox)
                        Positioned(
                          left: viewPadding.left + s(16),
                          right: viewPadding.right + s(16),
                          bottom: infoBottomInset + infoBoxGap,
                          child: RepaintBoundary(
                            child: Container(
                              height: infoBoxHeight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(s(15)),
                                ),
                              ),
                              child: GlassPressable(
                                borderRadius: s(15),
                                child: GlassSurface(
                                  config: LiquidGlassStyle.infoBox(
                                    isDark: isDark,
                                    s: s,
                                  ),
                                  isDark: isDark,
                                  borderRadius: s(15),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: infoContentInsetLeft,
                                        top: infoContentInsetTop,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Builder(
                                              builder: (context) {
                                                final TextStyle badgeTextStyle =
                                                    TextStyle(
                                                      color: const Color(
                                                        0xFF4DAAFC,
                                                      ),
                                                      fontSize: s(12),
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      height: 1.0,
                                                    );
                                                final double badgeBaseWidth = s(
                                                  36,
                                                );
                                                final double
                                                badgeBaseTextWidth =
                                                    measureTextWidth(
                                                      'Neu',
                                                      badgeTextStyle,
                                                    );
                                                final double
                                                badgeHorizontalPadding =
                                                    badgeBaseWidth >
                                                        badgeBaseTextWidth
                                                    ? (badgeBaseWidth -
                                                              badgeBaseTextWidth) /
                                                          2
                                                    : 0;
                                                return Container(
                                                  height: s(17),
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal:
                                                        badgeHorizontalPadding,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: HSLColor.fromAHSL(
                                                      0.3,
                                                      211,
                                                      1.0,
                                                      0.50,
                                                    ).toColor(),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          s(7),
                                                        ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    'Wichtig',
                                                    textAlign: TextAlign.center,
                                                    style: badgeTextStyle,
                                                  ),
                                                );
                                              },
                                            ),
                                            SizedBox(height: s(7)),
                                            Text(
                                              infoTitleText,
                                              style: infoTitleStyle,
                                            ),
                                            SizedBox(height: s(2)),
                                            RichText(
                                              textScaler: textScaler,
                                              text: infoDescriptionSpan,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.translucent,
                                          onTapUp: (details) {
                                            if (infoDescriptionLinkTapRect !=
                                                    Rect.zero &&
                                                infoDescriptionLinkTapRect
                                                    .contains(
                                                      details.localPosition,
                                                    )) {
                                              _openLegalPage();
                                            }
                                          },
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Semantics(
                                          button: true,
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () {
                                              setState(() {
                                                _showVerificationInfoBox =
                                                    false;
                                              });
                                            },
                                            child: SizedBox(
                                              width: 44,
                                              height: 44,
                                              child: Align(
                                                alignment: Alignment.topRight,
                                                child: Padding(
                                                  padding: EdgeInsets.only(
                                                    top: s(12),
                                                    right: s(12),
                                                  ),
                                                  child: SFSymbolHelper.getIcon(
                                                    iconPath:
                                                        'assets/icons/close.svg',
                                                    width: s(12),
                                                    height: s(12),
                                                    color: const Color(
                                                      0xFF747474,
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
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              )
            : _VerificationPageSkeleton(s: s, isDark: isDark),
      ),
    );
  }
}

class _VerificationPageSkeleton extends StatelessWidget {
  const _VerificationPageSkeleton({required this.s, required this.isDark});

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
            height: s(100),
            borderRadius: s(15),
          ),
          SizedBox(height: s(14)),
          ProfileDetailSkeletonBlock(
            isDark: isDark,
            height: s(39),
            borderRadius: s(15),
          ),
          SizedBox(height: s(20)),
          ProfileDetailSkeletonBlock(
            isDark: isDark,
            height: s(354),
            borderRadius: s(15),
          ),
        ],
      ),
    );
  }
}

class _VerificationEntryData {
  const _VerificationEntryData({
    required this.key,
    required this.title,
    required this.accessLabel,
    required this.unverifiedStatusText,
    required this.verifiedStatusText,
    this.pendingStatusText,
  });

  final _VerificationEntryKey key;
  final String title;
  final String accessLabel;
  final String unverifiedStatusText;
  final String verifiedStatusText;
  final String? pendingStatusText;
}

class VerifizierungCard extends StatelessWidget {
  const VerifizierungCard({
    super.key,
    required this.title,
    required this.statusText,
    required this.accessLabel,
    required this.color,
    required this.textColor,
    required this.buttonColor,
    required this.statusTextColor,
    required this.buttonTextColor,
    required this.onButtonTap,
    this.buttonLabel = 'Verifizieren',
    this.showVerified = false,
    this.embedInGroup = false,
    this.showDivider = false,
    this.dividerColor,
  });

  final String title;
  final String statusText;
  final String accessLabel;
  final Color color;
  final Color textColor;
  final Color buttonColor;
  final Color statusTextColor;
  final Color buttonTextColor;
  final VoidCallback onButtonTap;
  final String buttonLabel;
  final bool showVerified;
  final bool embedInGroup;
  final bool showDivider;
  final Color? dividerColor;

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);
    final TextDirection textDirection = Directionality.of(context);
    final String normalizedStatusText = statusText.trim();
    final TextStyle titleStyle = TextStyle(
      color: textColor,
      fontWeight: FontWeight.bold,
      fontSize: ui.s(17),
    );
    final TextStyle secondaryLineStyle = TextStyle(
      color: statusTextColor,
      fontWeight: FontWeight.bold,
      fontSize: ui.s(13.5),
      height: 1.4,
    );
    final TextStyle priceStyle = TextStyle(
      color: textColor,
      fontWeight: FontWeight.bold,
      fontSize: ui.s(16),
      height: 1.4,
    );
    final TextStyle buttonBaseTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: ui.s(14),
    );

    double measureSingleLineHeight(TextStyle style) {
      final TextPainter painter = TextPainter(
        text: TextSpan(text: 'Hg', style: style),
        textDirection: textDirection,
        maxLines: 1,
      )..layout();
      return painter.height;
    }

    final double startCardHeight =
        ui.s(15) +
        measureSingleLineHeight(titleStyle) +
        ui.s(10.5) +
        measureSingleLineHeight(
          TextStyle(
            color: statusTextColor,
            fontWeight: FontWeight.bold,
            fontSize: ui.s(13.5),
            height: 1.4,
          ),
        ) +
        measureSingleLineHeight(
          TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: ui.s(16),
            height: 1.4,
          ),
        ) +
        ui.s(10);
    final double fixedButtonWidth = ui.s(121);
    final Widget content = SizedBox(
      height: startCardHeight,
      child: Padding(
        padding: EdgeInsets.fromLTRB(ui.s(18), ui.s(15), ui.s(18), ui.s(10)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle,
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: SizedBox(
                            height: ui.s(38),
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Text(
                                normalizedStatusText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                strutStyle: StrutStyle(
                                  fontSize: ui.s(13.5),
                                  height: 1.4,
                                  forceStrutHeight: true,
                                ),
                                style: secondaryLineStyle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (showVerified) ...[
                        SFSymbolHelper.getIcon(
                          iconPath: 'assets/icons/verified.svg',
                          width: ui.s(17),
                          height: ui.s(17),
                          color: const Color(0xFF007AFF),
                        ),
                        SizedBox(width: ui.s(6)),
                      ],
                      Text(accessLabel, style: priceStyle),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: ui.s(12)),
            _VerificationActionButton(
              label: buttonLabel,
              width: fixedButtonWidth,
              height: ui.s(44),
              backgroundColor: buttonColor,
              textColor: buttonTextColor,
              textStyle: buttonBaseTextStyle,
              onTap: onButtonTap,
            ),
          ],
        ),
      ),
    );

    if (embedInGroup) {
      return Column(
        children: [
          content,
          if (showDivider)
            Container(
              margin: EdgeInsets.symmetric(horizontal: ui.s(18)),
              height: 1,
              color: dividerColor,
            ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(ui.s(15)),
      ),
      child: content,
    );
  }
}

class _VerificationEntryGroup extends StatelessWidget {
  const _VerificationEntryGroup({
    required this.color,
    required this.borderRadius,
    required this.children,
  });

  final Color color;
  final double borderRadius;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Column(children: children),
      ),
    );
  }
}

class _VerificationActionButton extends StatefulWidget {
  const _VerificationActionButton({
    required this.label,
    required this.width,
    required this.height,
    required this.backgroundColor,
    required this.textColor,
    required this.textStyle,
    required this.onTap,
  });

  final String label;
  final double width;
  final double height;
  final Color backgroundColor;
  final Color textColor;
  final TextStyle textStyle;
  final VoidCallback onTap;

  @override
  State<_VerificationActionButton> createState() =>
      _VerificationActionButtonState();
}

class _VerificationActionButtonState extends State<_VerificationActionButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }

    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);
    final BorderRadius borderRadius = BorderRadius.circular(ui.s(10));

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: borderRadius),
          onHighlightChanged: _setPressed,
          onTap: widget.onTap,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 120),
            opacity: _isPressed ? 0.72 : 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: borderRadius,
              ),
              child: Center(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: widget.textStyle.copyWith(color: widget.textColor),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VerificationProgressRingPainter extends CustomPainter {
  const _VerificationProgressRingPainter({
    required this.progress,
    required this.baseColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color baseColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = baseColor;

    final Paint progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = progressColor;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.shortestSide / 2) - (strokeWidth / 2);
    canvas.drawCircle(center, radius, basePaint);

    if (progress <= 0) return;
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);
    const double startAngle = -math.pi / 2;
    final double sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(arcRect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _VerificationProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _VerificationOptionButton extends StatelessWidget {
  const _VerificationOptionButton({
    required this.width,
    required this.isSelected,
    required this.onTap,
    required this.label,
    required this.tapHeight,
    required this.visualHeight,
    required this.textColor,
    required this.selectedColor,
    required this.unselectedColor,
  });

  final double width;
  final bool isSelected;
  final VoidCallback onTap;
  final String label;
  final double tapHeight;
  final double visualHeight;
  final Color textColor;
  final Color selectedColor;
  final Color unselectedColor;

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
                color: isSelected ? selectedColor : unselectedColor,
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
