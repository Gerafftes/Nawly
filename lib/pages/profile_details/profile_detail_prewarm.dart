import 'package:flutter/material.dart';

import '../../services/sf_symbol_helper.dart';
import 'affiliate_page.dart';
import 'feedback_page.dart';
import 'general_page.dart';
import 'legal_page.dart';
import 'notifications_page.dart';
import 'payments_page.dart';
import 'profile_detail_page_utils.dart';
import 'verification_page.dart';

const Set<String> kProfileDetailWarmupIconPaths = <String>{
  'assets/icons/gift.fill.svg',
  'assets/icons/headset.svg',
  'assets/icons/xmark.circle.fill.svg',
  'assets/icons/eye.circle.fill.svg',
  'assets/icons/close.svg',
  'assets/icons/checkmark.circle.fill.svg',
  'assets/icons/checkmark.seal.fill.svg',
  'assets/icons/verified.svg',
  'assets/icons/PayPal.svg',
  'assets/icons/apple.logo.svg',
  'assets/icons/paypal_groß.svg',
  'assets/icons/visa_groß.svg',
  'assets/icons/plus.circle.fill.svg',
};

const List<ProfileDetailPrewarmTarget> kProfileDetailPrewarmOrder =
    <ProfileDetailPrewarmTarget>[
      ProfileDetailPrewarmTarget.notificationsPhase1,
      ProfileDetailPrewarmTarget.notifications,
      ProfileDetailPrewarmTarget.verification,
      ProfileDetailPrewarmTarget.paymentsPhase1,
      ProfileDetailPrewarmTarget.paymentsPhase2,
      ProfileDetailPrewarmTarget.payments,
      ProfileDetailPrewarmTarget.general,
      ProfileDetailPrewarmTarget.legal,
      ProfileDetailPrewarmTarget.affiliate,
      ProfileDetailPrewarmTarget.feedback,
    ];

enum ProfileDetailPrewarmTarget {
  notificationsPhase1,
  notifications,
  verification,
  paymentsPhase1,
  paymentsPhase2,
  payments,
  general,
  legal,
  affiliate,
  feedback,
}

extension ProfileDetailPrewarmTargetX on ProfileDetailPrewarmTarget {
  String get warmupKey {
    switch (this) {
      case ProfileDetailPrewarmTarget.notificationsPhase1:
        return 'NotificationsPage.phase_1';
      case ProfileDetailPrewarmTarget.notifications:
        return 'NotificationsPage';
      case ProfileDetailPrewarmTarget.verification:
        return 'VerificationPage';
      case ProfileDetailPrewarmTarget.paymentsPhase1:
        return 'PaymentsPage.phase_1';
      case ProfileDetailPrewarmTarget.paymentsPhase2:
        return 'PaymentsPage.phase_2';
      case ProfileDetailPrewarmTarget.payments:
        return 'PaymentsPage';
      case ProfileDetailPrewarmTarget.general:
        return 'GeneralPage';
      case ProfileDetailPrewarmTarget.legal:
        return 'LegalPage';
      case ProfileDetailPrewarmTarget.affiliate:
        return 'AffiliatePage';
      case ProfileDetailPrewarmTarget.feedback:
        return 'FeedbackPage';
    }
  }
}

ProfileDetailPrewarmTarget? nextPendingProfileDetailWarmupTarget() {
  for (final ProfileDetailPrewarmTarget target in kProfileDetailPrewarmOrder) {
    if (!ProfileDetailWarmupRegistry.instance.isWarmed(target.warmupKey)) {
      return target;
    }
  }
  return null;
}

List<ProfileDetailPrewarmTarget> pendingProfileDetailWarmupTargets() {
  return kProfileDetailPrewarmOrder
      .where(
        (target) =>
            !ProfileDetailWarmupRegistry.instance.isWarmed(target.warmupKey),
      )
      .toList(growable: false);
}

Future<void> precacheProfileDetailWarmupIcons(BuildContext context) {
  return SFSymbolHelper.precacheIcons(context, kProfileDetailWarmupIconPaths);
}

class ProfileDetailPrewarmHost extends StatelessWidget {
  const ProfileDetailPrewarmHost({
    super.key,
    required this.target,
    required this.isDark,
  });

  final ProfileDetailPrewarmTarget target;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    switch (target) {
      case ProfileDetailPrewarmTarget.notificationsPhase1:
        return NotificationsPage(
          isDarkOverride: isDark,
          prewarm: true,
          prewarmPhase: 0,
        );
      case ProfileDetailPrewarmTarget.notifications:
        return NotificationsPage(
          isDarkOverride: isDark,
          prewarm: true,
          prewarmPhase: 1,
        );
      case ProfileDetailPrewarmTarget.verification:
        return VerificationPage(isDarkOverride: isDark, prewarm: true);
      case ProfileDetailPrewarmTarget.paymentsPhase1:
        return PaymentsPage(
          isDarkOverride: isDark,
          prewarm: true,
          prewarmPhase: 0,
        );
      case ProfileDetailPrewarmTarget.paymentsPhase2:
        return PaymentsPage(
          isDarkOverride: isDark,
          prewarm: true,
          prewarmPhase: 1,
        );
      case ProfileDetailPrewarmTarget.payments:
        return PaymentsPage(
          isDarkOverride: isDark,
          prewarm: true,
          prewarmPhase: 2,
        );
      case ProfileDetailPrewarmTarget.general:
        return GeneralPage(isDarkOverride: isDark, prewarm: true);
      case ProfileDetailPrewarmTarget.legal:
        return LegalPage(isDarkOverride: isDark);
      case ProfileDetailPrewarmTarget.affiliate:
        return AffiliatePage(isDarkOverride: isDark);
      case ProfileDetailPrewarmTarget.feedback:
        return FeedbackPage(isDarkOverride: isDark);
    }
  }
}

class ProfileDetailPrewarmBatchHost extends StatelessWidget {
  const ProfileDetailPrewarmBatchHost({
    super.key,
    required this.targets,
    required this.isDark,
  });

  final List<ProfileDetailPrewarmTarget> targets;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final ProfileDetailPrewarmTarget target in targets)
          ProfileDetailPrewarmHost(target: target, isDark: isDark),
      ],
    );
  }
}
