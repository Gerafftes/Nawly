import 'package:flutter/material.dart';

import '../../services/ui_scale.dart';
import 'profile_detail_page_utils.dart';

class AffiliatePage extends StatefulWidget {
  const AffiliatePage({super.key, this.isDarkOverride});

  final bool? isDarkOverride;

  @override
  State<AffiliatePage> createState() => _AffiliatePageState();
}

class _AffiliatePageState extends State<AffiliatePage>
    with ProfileDetailPerformanceMixin<AffiliatePage> {
  @override
  String get profileDetailPerformanceLabel => 'AffiliatePage';

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);
    final bool isDark =
        widget.isDarkOverride ??
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final Color bgColor = isDark
        ? const Color(0xFF020202)
        : const Color(0xFFE6E6E6);
    final Color textColor = isDark
        ? const Color(0xFFF2F2F2)
        : const Color(0xFF0D0D0D);
    final Color secondaryTextColor = isDark
        ? Colors.white
        : const Color(0xFF0D0D0D);

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
          'Affiliate',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: ui.s(20),
          ),
        ),
      ),
      body: Center(
        child: Text(
          'Diese Seite wird bald verfügbar sein.',
          style: TextStyle(color: secondaryTextColor, fontSize: ui.s(16)),
        ),
      ),
    );
  }
}
