import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';
import 'package:nawly/data/user_profile_repository.dart';
import 'package:nawly/models/user_profile_models.dart';
import 'package:nawly/pages/profile_details/affiliate_page.dart';
import 'package:nawly/pages/profile_details/feedback_page.dart';
import 'package:nawly/pages/profile_details/general_page.dart';
import 'package:nawly/pages/profile_details/legal_page.dart';
import 'package:nawly/pages/profile_details/notifications_page.dart';
import 'package:nawly/pages/profile_details/payments_page.dart';
import 'package:nawly/pages/profile_details/payout_history_page.dart';
import 'package:nawly/pages/profile_details/payout_processing_page.dart';
import 'package:nawly/pages/profile_details/verification_page.dart';
import 'package:nawly/pages/tabs/activity_tab.dart';
import 'package:nawly/pages/tabs/create_tab.dart';
import 'package:nawly/pages/tabs/profile_tab.dart';
import 'package:nawly/pages/tabs/start/jobs_find_content.dart';
import 'package:nawly/pages/tabs/start/services_content.dart';
import 'package:nawly/services/ui_scale.dart';
import 'package:nawly/widgets/home_action_button.dart';

const Map<String, Size> _phoneSizes = <String, Size>{
  'small phone': Size(320, 568),
  'compact Android': Size(360, 800),
  'design reference': Size(402, 874),
  'large phone': Size(430, 932),
};

const Color _backgroundColor = Color(0xFF020202);
const Color _cardColor = Color(0xFF0D0D0D);
const Color _secondaryTextColor = Color(0xFFB3B3B3);
const Color _borderColor = Color.fromRGBO(255, 255, 255, 0.18);
const Color _textColor = Color(0xFFF2F2F2);
const Color _buttonColor = Color(0xFF1A1A1A);
const EdgeInsets _phoneSafeArea = EdgeInsets.only(top: 24, bottom: 34);

void main() {
  late UserProfileData userProfile;

  setUpAll(() async {
    userProfile = await const UserProfileDemoRepository().loadProfile();
  });

  group('responsive primary layouts', () {
    for (final MapEntry<String, Size> phone in _phoneSizes.entries) {
      testWidgets('${phone.key} renders without layout errors', (
        WidgetTester tester,
      ) async {
        await _setPhoneSize(tester, phone.value);

        final AppleLiquidSheetController sheetController =
            AppleLiquidSheetController();
        addTearDown(sheetController.dispose);

        await _pumpScrollableScreen(
          tester,
          _StartContent(sheetController: sheetController),
        );
        _expectNoLayoutError(tester, '${phone.key}: Start');

        await _pumpScrollableScreen(
          tester,
          const ActivityTabContent(jobCardColor: _cardColor),
        );
        _expectNoLayoutError(tester, '${phone.key}: Aktivität');

        await _pumpBoundedScreen(
          tester,
          const CreateTabContent(
            cardColor: _cardColor,
            secondaryText: _secondaryTextColor,
            borderColor: _borderColor,
            textColor: _textColor,
            jobCardColor: _cardColor,
            jobButtonColor: _buttonColor,
            timeTextColor: _secondaryTextColor,
            buttonTextColor: _textColor,
            scrollBottomPadding: 85,
          ),
        );
        _expectNoLayoutError(tester, '${phone.key}: Erstellen');

        await _pumpBoundedScreen(
          tester,
          ProfileTabContent(
            userProfile: userProfile,
            textColor: _textColor,
            headerTopInset: 0,
            isDark: true,
            scrollBottomPadding: 85,
            warmupPaused: true,
            onOpenDetailPage: (_) {},
          ),
        );
        _expectNoLayoutError(tester, '${phone.key}: Profil');
      });
    }
  });

  group('responsive profile detail layouts', () {
    for (final MapEntry<String, Size> phone in <String, Size>{
      'small phone': _phoneSizes['small phone']!,
      'large phone': _phoneSizes['large phone']!,
    }.entries) {
      testWidgets('${phone.key} renders detail pages without layout errors', (
        WidgetTester tester,
      ) async {
        await _setPhoneSize(tester, phone.value);

        final List<Widget> detailPages = <Widget>[
          GeneralPage(
            userProfile: userProfile,
            isDarkOverride: true,
            prewarm: true,
          ),
          const NotificationsPage(isDarkOverride: true, prewarm: true),
          PaymentsPage(
            userProfile: userProfile,
            isDarkOverride: true,
            prewarm: true,
            prewarmPhase: 2,
          ),
          VerificationPage(
            userProfile: userProfile,
            isDarkOverride: true,
            prewarm: true,
          ),
          const LegalPage(isDarkOverride: true),
          const AffiliatePage(isDarkOverride: true),
          const FeedbackPage(isDarkOverride: true),
          const PayoutHistoryPage(),
          const PayoutProcessingPage(),
        ];

        for (final Widget page in detailPages) {
          await _pumpPage(tester, page);
          _expectNoLayoutError(tester, '${phone.key}: ${page.runtimeType}');
        }
      });
    }
  });
}

class _StartContent extends StatelessWidget {
  const _StartContent({required this.sheetController});

  final AppleLiquidSheetController sheetController;

  @override
  Widget build(BuildContext context) {
    final UiScale ui = UiScale.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            HomeActionButton(
              iconPath: 'assets/icons/briefcase.fill.svg',
              label: 'Jobs finden',
              color: const Color(0xFF1C1C1E),
              onTap: () {},
              isSelected: true,
              textColor: _textColor,
              iconColor: _textColor,
            ),
            SizedBox(width: ui.s(12)),
            HomeActionButton(
              iconPath: 'assets/icons/list.bullet.rectangle.portrait.fill.svg',
              label: 'Services',
              color: const Color(0xFF111111),
              onTap: () {},
              isSelected: false,
              textColor: _textColor,
              iconColor: _textColor,
            ),
          ],
        ),
        SizedBox(height: ui.s(28)),
        JobsFindContent(
          cardColor: _cardColor,
          secondaryText: _secondaryTextColor,
          borderColor: _borderColor,
          textColor: _textColor,
          jobCardColor: _cardColor,
          jobButtonColor: _buttonColor,
          timeTextColor: _secondaryTextColor,
          filterIconColor: _textColor,
          themeMode: 'dark',
          buttonTextColor: _textColor,
          sheetController: sheetController,
        ),
        SizedBox(height: ui.s(28)),
        const ServicesContent(
          cardColor: _cardColor,
          secondaryText: _secondaryTextColor,
          borderColor: _borderColor,
          textColor: _textColor,
          jobCardColor: _cardColor,
          jobButtonColor: _buttonColor,
          timeTextColor: _secondaryTextColor,
          buttonTextColor: _textColor,
        ),
      ],
    );
  }
}

Future<void> _setPhoneSize(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _pumpScrollableScreen(WidgetTester tester, Widget child) async {
  await _pumpPage(
    tester,
    Builder(
      builder: (BuildContext context) {
        final UiScale ui = UiScale.of(context);
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: ui.s(16)),
          child: child,
        );
      },
    ),
  );
}

Future<void> _pumpBoundedScreen(WidgetTester tester, Widget child) async {
  await _pumpPage(
    tester,
    Builder(
      builder: (BuildContext context) {
        final UiScale ui = UiScale.of(context);
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: ui.s(16)),
          child: child,
        );
      },
    ),
  );
}

Future<void> _pumpPage(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            padding: _phoneSafeArea,
            viewPadding: _phoneSafeArea,
            textScaler: const TextScaler.linear(1),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: Scaffold(backgroundColor: _backgroundColor, body: child),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void _expectNoLayoutError(WidgetTester tester, String layout) {
  expect(tester.takeException(), isNull, reason: '$layout has a layout error');
}
