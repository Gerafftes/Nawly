import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/sf_symbol_helper.dart';
import '../../services/ui_scale.dart';
import '../profile_details/verification_page.dart';
import '../profile_details/notifications_page.dart';
import '../profile_details/payments_page.dart';
import '../profile_details/legal_page.dart';
import '../profile_details/general_page.dart';
import '../profile_details/affiliate_page.dart';
import '../profile_details/feedback_page.dart';
import '../profile_details/profile_detail_prewarm.dart';

const double _profileIconBaseSize = 21;
const double _profileChevronBaseSize = 28;
const Duration _profileDetailBatchWarmupDelay = Duration(milliseconds: 300);
const Duration _profileDetailBatchUnmountDelay = Duration(milliseconds: 16);

class ProfileTabContent extends StatefulWidget {
  final Color textColor;
  final double headerTopInset;
  final bool isDark;
  final double scrollBottomPadding;
  final ValueChanged<Widget> onOpenDetailPage;

  const ProfileTabContent({
    super.key,
    required this.textColor,
    required this.headerTopInset,
    required this.isDark,
    required this.scrollBottomPadding,
    required this.onOpenDetailPage,
  });

  @override
  State<ProfileTabContent> createState() => _ProfileTabContentState();
}

class _ProfileTabContentState extends State<ProfileTabContent> {
  bool _scheduledWarmup = false;
  Timer? _profileDetailWarmupTimer;
  List<ProfileDetailPrewarmTarget> _activePrewarmTargets =
      const <ProfileDetailPrewarmTarget>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduledWarmup) {
      return;
    }

    _scheduledWarmup = true;
    if (pendingProfileDetailWarmupTargets().isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _profileDetailWarmupTimer = Timer(
        _profileDetailBatchWarmupDelay,
        _startProfileDetailBatchWarmup,
      );
    });
  }

  @override
  void dispose() {
    _profileDetailWarmupTimer?.cancel();
    super.dispose();
  }

  void _startProfileDetailBatchWarmup() {
    _profileDetailWarmupTimer = null;
    if (!mounted || _activePrewarmTargets.isNotEmpty) {
      return;
    }

    final List<ProfileDetailPrewarmTarget> pendingTargets =
        pendingProfileDetailWarmupTargets();
    if (pendingTargets.isEmpty) {
      return;
    }

    unawaited(precacheProfileDetailWarmupIcons(context));
    setState(() {
      _activePrewarmTargets = pendingTargets;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(_profileDetailBatchUnmountDelay, () {
        if (!mounted) {
          return;
        }
        setState(() {
          _activePrewarmTargets = const <ProfileDetailPrewarmTarget>[];
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewPadding = MediaQuery.of(context).padding;
    final ui = UiScale.of(context, designWidth: 402);
    double s(double value) => ui.s(value);
    final double avatarBoxSize = s(65);
    final Color primaryContentColor = widget.isDark
        ? const Color(0xFFF2F2F2)
        : const Color(0xFF0D0D0D);
    final Color sectionSurfaceColor = widget.isDark
        ? const Color(0xFF0D0D0D)
        : const Color(0xFFF2F2F2);

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: widget.headerTopInset,
            bottom: 0,
            left: viewPadding.left,
            right: viewPadding.right,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileAvatarBadge(
                    width: avatarBoxSize,
                    isDark: widget.isDark,
                    letter: 'G',
                  ),
                  SizedBox(width: s(19)),
                  Expanded(
                    child: SizedBox(
                      height: s(65),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: s(2)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gerafftes',
                                  style: TextStyle(
                                    color: widget.textColor,
                                    fontSize: s(30),
                                    fontWeight: FontWeight.w700,
                                    height: 1.0,
                                  ),
                                ),
                                SizedBox(width: s(8)),
                                Padding(
                                  padding: EdgeInsets.only(top: s(2)),
                                  child: _ProfileRatingChip(s: s),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Padding(
                            padding: EdgeInsets.only(bottom: s(4)),
                            child: Text(
                              '5 Abgeschlossene Aufträge',
                              style: TextStyle(
                                color: const Color(0xFFB3B3B3),
                                fontSize: s(17),
                                fontWeight: FontWeight.w400,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: s(28)),
              Expanded(
                child: StretchingOverscrollIndicator(
                  axisDirection: AxisDirection.down,
                  child: SingleChildScrollView(
                    primary: false,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.only(
                      top: 0,
                      bottom: widget.scrollBottomPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProfileSectionCard(
                          s: s,
                          backgroundColor: sectionSurfaceColor,
                          children: [
                            _ProfileRow(
                              iconPath: 'assets/icons/circle.grid.3x3.fill.svg',
                              label: 'Allgemein',
                              showIndicator: true,
                              foregroundColor: primaryContentColor,
                              isDark: widget.isDark,
                              showDivider: true,
                              onTap: () {
                                widget.onOpenDetailPage(
                                  GeneralPage(isDarkOverride: widget.isDark),
                                );
                              },
                            ),
                            _ProfileRow(
                              iconPath: 'assets/icons/bell.fill.svg',
                              label: 'Benachrichtigungen',
                              showIndicator: false,
                              foregroundColor: primaryContentColor,
                              isDark: widget.isDark,
                              showDivider: true,
                              onTap: () {
                                widget.onOpenDetailPage(
                                  NotificationsPage(
                                    isDarkOverride: widget.isDark,
                                  ),
                                );
                              },
                            ),
                            _ProfileRow(
                              iconPath: 'assets/icons/creditcard.fill.svg',
                              label: 'Zahlungen & Auszahlungen',
                              showIndicator: true,
                              foregroundColor: primaryContentColor,
                              isDark: widget.isDark,
                              showDivider: true,
                              onTap: () {
                                widget.onOpenDetailPage(
                                  PaymentsPage(isDarkOverride: widget.isDark),
                                );
                              },
                            ),
                            _ProfileRow(
                              iconPath: 'assets/icons/checkmark.seal.fill.svg',
                              label: 'Verifizierung',
                              showIndicator: true,
                              foregroundColor: primaryContentColor,
                              isDark: widget.isDark,
                              showDivider: false,
                              onTap: () {
                                widget.onOpenDetailPage(
                                  VerificationPage(
                                    isDarkOverride: widget.isDark,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: s(14)),
                        _ProfileSectionCard(
                          s: s,
                          backgroundColor: sectionSurfaceColor,
                          children: [
                            _ProfileRow(
                              iconPath: 'assets/icons/scroll.fill.svg',
                              label: 'Rechtliches',
                              showIndicator: false,
                              foregroundColor: primaryContentColor,
                              isDark: widget.isDark,
                              showDivider: true,
                              onTap: () {
                                widget.onOpenDetailPage(
                                  LegalPage(isDarkOverride: widget.isDark),
                                );
                              },
                            ),
                            _ProfileRow(
                              iconPath: 'assets/icons/gift.fill.svg',
                              label: 'Affiliate',
                              showIndicator: false,
                              foregroundColor: primaryContentColor,
                              isDark: widget.isDark,
                              showDivider: true,
                              onTap: () {
                                widget.onOpenDetailPage(
                                  AffiliatePage(isDarkOverride: widget.isDark),
                                );
                              },
                            ),
                            _ProfileRow(
                              iconPath: 'assets/icons/headset.svg',
                              label: 'Feedback',
                              showIndicator: false,
                              foregroundColor: primaryContentColor,
                              isDark: widget.isDark,
                              showDivider: false,
                              onTap: () {
                                widget.onOpenDetailPage(
                                  FeedbackPage(isDarkOverride: widget.isDark),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_activePrewarmTargets.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: TickerMode(
                enabled: false,
                child: Offstage(
                  offstage: true,
                  child: ProfileDetailPrewarmBatchHost(
                    targets: _activePrewarmTargets,
                    isDark: widget.isDark,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String iconPath;
  final String label;
  final VoidCallback onTap;
  final bool showIndicator;
  final Color foregroundColor;
  final bool isDark;
  final bool showDivider;

  const _ProfileRow({
    required this.iconPath,
    required this.label,
    required this.onTap,
    required this.foregroundColor,
    required this.isDark,
    required this.showDivider,
    this.showIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);
    final double iconSize = ui.s(_profileIconBaseSize - 2);
    final double chevronSize = ui.s(_profileChevronBaseSize - 2);
    final Color iconTileColor = isDark
        ? const Color(0xFF141414)
        : const Color(0xFFFFFFFF);
    final Color dividerColor = isDark
        ? const Color(0xFF1B1B1B)
        : const Color(0xFFE2E2E2);

    return Column(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: ui.s(58)),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ui.s(16),
                vertical: ui.s(11),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: ui.s(34),
                        height: ui.s(34),
                        decoration: BoxDecoration(
                          color: iconTileColor,
                          borderRadius: BorderRadius.circular(ui.s(11)),
                        ),
                        child: Center(
                          child: SFSymbolHelper.getIcon(
                            iconPath: iconPath,
                            width: iconSize,
                            height: iconSize,
                            color: foregroundColor,
                          ),
                        ),
                      ),
                      SizedBox(width: ui.s(16)),
                      Text(
                        label,
                        style: TextStyle(
                          color: foregroundColor,
                          fontSize: ui.s(18),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showIndicator)
                        Container(
                          width: ui.s(7),
                          height: ui.s(7),
                          decoration: const BoxDecoration(
                            color: Color(0xFF007AFF),
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (showIndicator) SizedBox(width: ui.s(3)),
                      SFSymbolHelper.getChevronRight(
                        color: foregroundColor,
                        size: chevronSize,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Container(
            margin: EdgeInsets.symmetric(horizontal: ui.s(16)),
            height: 1,
            color: dividerColor,
          ),
      ],
    );
  }
}

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({
    required this.s,
    required this.backgroundColor,
    required this.children,
  });

  final double Function(double) s;
  final Color backgroundColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(s(20)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(s(20)),
        child: Column(children: children),
      ),
    );
  }
}

class _ProfileAvatarBadge extends StatelessWidget {
  const _ProfileAvatarBadge({
    required this.width,
    required this.isDark,
    required this.letter,
  });

  final double width;
  final bool isDark;
  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(width * 0.34),
        border: Border.all(
          color: isDark
              ? const Color.fromRGBO(255, 255, 255, 0.08)
              : const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: isDark ? const Color(0xFFF2F2F2) : const Color(0xFF0D0D0D),
            fontSize: width * 0.38,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _ProfileRatingChip extends StatelessWidget {
  const _ProfileRatingChip({required this.s});

  final double Function(double) s;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: s(24),
      padding: EdgeInsets.symmetric(horizontal: s(10)),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 122, 255, 0.16),
        borderRadius: BorderRadius.circular(s(100)),
        border: Border.all(
          color: const Color.fromRGBO(77, 170, 252, 0.26),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '4,9',
            style: TextStyle(
              color: const Color(0xFF007AFF),
              fontSize: s(11.5),
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          SizedBox(width: s(5)),
          SFSymbolHelper.getIcon(
            iconPath: 'assets/icons/star.fill.svg',
            width: s(12),
            height: s(12),
            color: const Color(0xFF007AFF),
          ),
        ],
      ),
    );
  }
}
