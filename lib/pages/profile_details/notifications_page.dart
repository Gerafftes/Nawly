import 'package:flutter/material.dart';

import '../../liquid_glass/liquid_glass.dart';
import '../../services/sf_symbol_helper.dart';
import '../../services/ui_scale.dart';
import 'profile_detail_page_utils.dart';

enum _NotificationPreferenceKey { jobOffers, messages, payments, security }

const Duration _notificationsInfoOverlayTransitionDuration = Duration(
  milliseconds: 180,
);

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
    this.isDarkOverride,
    this.prewarm = false,
    this.prewarmPhase = 1,
  });

  final bool? isDarkOverride;
  final bool prewarm;
  final int prewarmPhase;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with ProfileDetailPerformanceMixin<NotificationsPage> {
  static const List<_NotificationSectionData> _notificationSections =
      <_NotificationSectionData>[
    _NotificationSectionData(
      title: 'Aktivität',
      description: 'Jobs und neue Kontakte in deiner Nähe.',
      preferences: <_NotificationPreferenceData>[
        _NotificationPreferenceData(
          key: _NotificationPreferenceKey.jobOffers,
          title: 'Jobangebote',
          supportingText: 'Anfragen, Änderungen und\nBestätigungen',
        ),
        _NotificationPreferenceData(
          key: _NotificationPreferenceKey.messages,
          title: 'Nachrichten',
          supportingText: 'Benachrichtigungen zu neuen\nChat-Nachrichten.',
        ),
      ],
    ),
    _NotificationSectionData(
      title: 'Wichtige Hinweise',
      description: 'Zahlungen und Sicherheit getrennt steuerbar.',
      badgeText: 'Empfohlen',
      preferences: <_NotificationPreferenceData>[
        _NotificationPreferenceData(
          key: _NotificationPreferenceKey.payments,
          title: 'Zahlungen & Auszahlungen',
          supportingText:
              'Eingänge, Auszahlungen und\nProbleme mit Auszahlungen.',
        ),
        _NotificationPreferenceData(
          key: _NotificationPreferenceKey.security,
          title: 'Sicherheitswarnungen',
          supportingText: 'Neue Logins und Änderungen an\nKonto oder Finanzen.',
        ),
      ],
    ),
  ];

  final Map<_NotificationPreferenceKey, bool> _enabledPreferences =
      <_NotificationPreferenceKey, bool>{
    _NotificationPreferenceKey.jobOffers: false,
    _NotificationPreferenceKey.messages: false,
    _NotificationPreferenceKey.payments: false,
    _NotificationPreferenceKey.security: false,
  };

  bool _showNotificationsInfoBox = true;

  @override
  String get profileDetailPerformanceLabel {
    if (widget.prewarm && widget.prewarmPhase == 0) {
      return 'NotificationsPage:phase_1';
    }
    return 'NotificationsPage';
  }

  @override
  String get profileDetailWarmupKey {
    if (widget.prewarm && widget.prewarmPhase == 0) {
      return 'NotificationsPage.phase_1';
    }
    return 'NotificationsPage';
  }

  @override
  bool get isProfileDetailWarmup => widget.prewarm;

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);
    double s(double value) => ui.s(value);
    final bool isDark = widget.isDarkOverride ??
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final EdgeInsets viewPadding = MediaQuery.of(context).viewPadding;
    final Color bgColor =
        isDark ? const Color(0xFF020202) : const Color(0xFFE6E6E6);
    final Color textColor =
        isDark ? const Color(0xFFF2F2F2) : const Color(0xFF0D0D0D);
    final Color secondaryTextColor =
        isDark ? const Color(0xFFB3B3B3) : const Color(0xFF4D4D4D);
    final Color cardColor =
        isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF2F2F2);
    final Color dividerColor =
        isDark ? const Color(0xFF1B1B1B) : const Color(0xFFE2E2E2);
    final bool includeAllSections = !widget.prewarm || widget.prewarmPhase > 0;
    final List<_NotificationSectionData> visibleSections = includeAllSections
        ? _notificationSections
        : _notificationSections.take(1).toList(growable: false);
    final double infoBoxGap = s(19);
    final bool shouldBuildInfoBox = isInitialContentReady && includeAllSections;
    final bool showInfoBox = shouldBuildInfoBox && _showNotificationsInfoBox;
    final double reservedBottomInset =
        showInfoBox ? s(138) + viewPadding.bottom + infoBoxGap : 0;

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
        iconTheme: IconThemeData(
          color: textColor,
          size: ui.s(20),
        ),
        title: Text(
          'Benachrichtigungen',
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
        child: Stack(
          children: [
            Positioned.fill(
              child: isInitialContentReady
                  ? _NotificationsContent(
                      s: s,
                      isDark: isDark,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      cardColor: cardColor,
                      dividerColor: dividerColor,
                      sections: visibleSections,
                      bottomPadding: reservedBottomInset,
                      enabledPreferences: _enabledPreferences,
                      onChanged: (_NotificationPreferenceKey key, bool value) {
                        setState(() {
                          _enabledPreferences[key] = value;
                        });
                      },
                    )
                  : _NotificationsSkeleton(
                      s: s,
                      isDark: isDark,
                    ),
            ),
            if (shouldBuildInfoBox)
              Positioned(
                left: viewPadding.left + s(16),
                right: viewPadding.right + s(16),
                bottom: viewPadding.bottom + infoBoxGap,
                child: IgnorePointer(
                  ignoring: !showInfoBox,
                  child: AnimatedSlide(
                    offset: showInfoBox ? Offset.zero : const Offset(0, 1.25),
                    duration: _notificationsInfoOverlayTransitionDuration,
                    curve: Curves.easeInOut,
                    child: AnimatedOpacity(
                      opacity: showInfoBox ? 1 : 0,
                      duration: _notificationsInfoOverlayTransitionDuration,
                      curve: Curves.easeInOut,
                      child: RepaintBoundary(
                        child: _NotificationsInfoOverlay(
                          s: s,
                          isDark: isDark,
                          onDismiss: () {
                            setState(() {
                              _showNotificationsInfoBox = false;
                            });
                          },
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

class _NotificationsContent extends StatelessWidget {
  const _NotificationsContent({
    required this.s,
    required this.isDark,
    required this.textColor,
    required this.secondaryTextColor,
    required this.cardColor,
    required this.dividerColor,
    required this.sections,
    required this.bottomPadding,
    required this.enabledPreferences,
    required this.onChanged,
  });

  final double Function(double) s;
  final bool isDark;
  final Color textColor;
  final Color secondaryTextColor;
  final Color cardColor;
  final Color dividerColor;
  final List<_NotificationSectionData> sections;
  final double bottomPadding;
  final Map<_NotificationPreferenceKey, bool> enabledPreferences;
  final void Function(_NotificationPreferenceKey key, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    return StretchingOverscrollIndicator(
      axisDirection: AxisDirection.down,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              s(16),
              0,
              s(16),
              bottomPadding,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: s(26)),
                  for (int index = 0; index < sections.length; index++) ...[
                    _NotificationSection(
                      s: s,
                      isDark: isDark,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      cardColor: cardColor,
                      dividerColor: dividerColor,
                      section: sections[index],
                      enabledPreferences: enabledPreferences,
                      onChanged: onChanged,
                    ),
                    if (index != sections.length - 1) SizedBox(height: s(28)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsSkeleton extends StatelessWidget {
  const _NotificationsSkeleton({
    required this.s,
    required this.isDark,
  });

  final double Function(double) s;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return StretchingOverscrollIndicator(
      axisDirection: AxisDirection.down,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          s(16),
          0,
          s(16),
          s(28),
        ),
        children: [
          SizedBox(height: s(26)),
          ProfileDetailSkeletonBlock(
            isDark: isDark,
            height: s(86),
            borderRadius: s(18),
          ),
          SizedBox(height: s(28)),
          ProfileDetailSkeletonBlock(
            isDark: isDark,
            width: s(104),
            height: s(22),
            borderRadius: s(11),
          ),
          SizedBox(height: s(21)),
          ProfileDetailSkeletonBlock(
            isDark: isDark,
            height: s(198),
            borderRadius: s(18),
          ),
          SizedBox(height: s(28)),
          ProfileDetailSkeletonBlock(
            isDark: isDark,
            width: s(142),
            height: s(22),
            borderRadius: s(11),
          ),
          SizedBox(height: s(21)),
          ProfileDetailSkeletonBlock(
            isDark: isDark,
            height: s(198),
            borderRadius: s(18),
          ),
        ],
      ),
    );
  }
}

class _NotificationsInfoOverlay extends StatelessWidget {
  const _NotificationsInfoOverlay({
    required this.s,
    required this.isDark,
    required this.onDismiss,
  });

  final double Function(double) s;
  final bool isDark;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final double infoBoxRadius = s(15);
    final double infoContentInset = s(8);
    final double infoBadgeRadius =
        (infoBoxRadius - infoContentInset).clamp(0.0, infoBoxRadius).toDouble();
    const String infoTitleText = 'Wichtige Benachrichtigungen';
    const String infoDescriptionText =
        'Sicherheits- und Zahlungsinfos helfen dir, keine wichtigen Änderungen zu verpassen.';
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

    return GlassPressable(
      borderRadius: infoBoxRadius,
      child: GlassSurface(
        config: LiquidGlassStyle.infoBox(
          isDark: isDark,
          s: s,
        ),
        isDark: isDark,
        borderRadius: infoBoxRadius,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            infoContentInset,
            infoContentInset,
            s(10),
            s(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: s(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: s(8),
                          vertical: s(2),
                        ),
                        decoration: BoxDecoration(
                          color:
                              HSLColor.fromAHSL(0.3, 211, 1.0, 0.50).toColor(),
                          borderRadius: BorderRadius.circular(infoBadgeRadius),
                        ),
                        child: Text(
                          'Hinweis',
                          style: TextStyle(
                            color: const Color(0xFF4DAAFC),
                            fontSize: s(12),
                            fontWeight: FontWeight.w400,
                            height: 1.0,
                          ),
                        ),
                      ),
                      SizedBox(height: s(7)),
                      Text(
                        infoTitleText,
                        style: infoTitleStyle,
                      ),
                      SizedBox(height: s(2)),
                      Text(
                        infoDescriptionText,
                        style: infoDescriptionStyle,
                      ),
                    ],
                  ),
                ),
              ),
              Semantics(
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDismiss,
                  child: SizedBox(
                    width: s(44),
                    height: s(44),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: s(2),
                          right: s(2),
                        ),
                        child: SFSymbolHelper.getIcon(
                          iconPath: 'assets/icons/close.svg',
                          width: s(12),
                          height: s(12),
                          color: const Color(0xFF747474),
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
    );
  }
}

class _NotificationSection extends StatelessWidget {
  const _NotificationSection({
    required this.s,
    required this.isDark,
    required this.textColor,
    required this.secondaryTextColor,
    required this.cardColor,
    required this.dividerColor,
    required this.section,
    required this.enabledPreferences,
    required this.onChanged,
  });

  final double Function(double) s;
  final bool isDark;
  final Color textColor;
  final Color secondaryTextColor;
  final Color cardColor;
  final Color dividerColor;
  final _NotificationSectionData section;
  final Map<_NotificationPreferenceKey, bool> enabledPreferences;
  final void Function(_NotificationPreferenceKey key, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                section.title,
                style: TextStyle(
                  color: textColor,
                  fontSize: s(22),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (section.badgeText != null) ...[
              SizedBox(width: s(8)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: s(8),
                  vertical: s(4),
                ),
                decoration: BoxDecoration(
                  color: HSLColor.fromAHSL(0.3, 211, 1.0, 0.50).toColor(),
                  borderRadius: BorderRadius.circular(s(100)),
                ),
                child: Text(
                  section.badgeText!,
                  style: TextStyle(
                    color: const Color(0xFF4DAAFC),
                    fontSize: s(12),
                    fontWeight: FontWeight.w400,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: s(14)),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(s(18)),
          ),
          child: Column(
            children: [
              for (int index = 0; index < section.preferences.length; index++)
                _NotificationPreferenceRow(
                  title: section.preferences[index].title,
                  supportingText: section.preferences[index].supportingText,
                  isDark: isDark,
                  titleColor: textColor,
                  supportingTextColor: secondaryTextColor,
                  dividerColor: dividerColor,
                  isEnabled:
                      enabledPreferences[section.preferences[index].key] ??
                          false,
                  showDivider: index != section.preferences.length - 1,
                  onChanged: (value) =>
                      onChanged(section.preferences[index].key, value),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationPreferenceRow extends StatelessWidget {
  const _NotificationPreferenceRow({
    required this.title,
    required this.supportingText,
    required this.isDark,
    required this.titleColor,
    required this.supportingTextColor,
    required this.dividerColor,
    required this.isEnabled,
    required this.showDivider,
    required this.onChanged,
  });

  final String title;
  final String supportingText;
  final bool isDark;
  final Color titleColor;
  final Color supportingTextColor;
  final Color dividerColor;
  final bool isEnabled;
  final bool showDivider;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            ui.s(18),
            ui.s(16),
            ui.s(18),
            ui.s(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.w600,
                        fontSize: ui.s(17),
                      ),
                    ),
                    SizedBox(height: ui.s(6)),
                    Text(
                      supportingText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: supportingTextColor,
                        fontWeight: FontWeight.w500,
                        fontSize: ui.s(13.5),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: ui.s(12)),
              Padding(
                padding: EdgeInsets.only(top: ui.s(4)),
                child: GlassSwitch(
                  isDark: isDark,
                  value: isEnabled,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ui.s(18)),
            child: Container(
              height: 1,
              color: dividerColor,
            ),
          ),
      ],
    );
  }
}

class _NotificationSectionData {
  const _NotificationSectionData({
    required this.title,
    required this.description,
    required this.preferences,
    this.badgeText,
  });

  final String title;
  final String description;
  final String? badgeText;
  final List<_NotificationPreferenceData> preferences;
}

class _NotificationPreferenceData {
  const _NotificationPreferenceData({
    required this.key,
    required this.title,
    required this.supportingText,
  });

  final _NotificationPreferenceKey key;
  final String title;
  final String supportingText;
}
