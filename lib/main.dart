import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/user_profile_repository.dart';
import 'models/user_profile_models.dart';
import 'pages/tabs/start/jobs_find_content.dart';
import 'pages/tabs/create_tab.dart';
import 'pages/tabs/start/services_content.dart';
import 'pages/tabs/activity_tab.dart';
import 'pages/profile_details/profile_detail_page_utils.dart';
import 'pages/profile_details/profile_detail_prewarm.dart';
import 'pages/tabs/profile_tab.dart';
import 'pages/profile_details/verification_page.dart';
import 'widgets/home_action_button.dart';
import 'widgets/shake_overlay.dart';
import 'liquid_glass/liquid_glass.dart';
import 'services/shake_detector.dart';
import 'services/sf_symbol_helper.dart';
import 'services/ui_scale.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final UserProfileData userProfile = await const UserProfileDemoRepository()
      .loadProfile();
  runApp(MyApp(userProfile: userProfile));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.userProfile});

  final UserProfileData userProfile;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nawly',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      supportedLocales: const [Locale('de'), Locale('en'), Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007AFF)),
        useMaterial3: true,
      ),
      home: HomeScreen(userProfile: userProfile),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.userProfile});

  final UserProfileData userProfile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const int _startTabIndex = 0;
  static const int _activityTabIndex = 1;
  static const int _profileTabIndex = 2;
  static const int _createTabIndex = 3;
  static const int _notificationsTabIndex = 4;
  static const Duration _tabFadeInDuration = Duration(milliseconds: 250);
  static const Duration _tabFadeOutDuration = Duration(milliseconds: 250);
  static const Duration _startTabProfileWarmupDelay = Duration(seconds: 4);
  static const Duration _startTabProfileWarmupGap = Duration(milliseconds: 700);
  static const Duration _warmupUnmountDelay = Duration(milliseconds: 16);
  static const Duration _profileDetailOpenSwipeSettleDuration = Duration(
    milliseconds: 220,
  );
  static const double _profileDetailOpenSwipeDistanceFraction = 0.24;
  static const double _profileDetailOpenSwipeMinFlingVelocity = 520;
  static const double _profileDetailBackgroundParallaxFraction = 0.35;
  static const double _topBarScrolledUnderOffset = 2;

  int selectedIndex = 0;
  int _bottomNavIndex = 0;
  int _mainTabIndex = 0;
  WidgetBuilder? _lastProfileDetailPageBuilder;
  String _themeMode = 'auto';
  bool _showShakeOverlay = false;
  bool _showProfileInfoBox = true;
  bool _isProfileDetailRouteOpen = false;
  bool _isTopBarScrolledUnder = false;
  bool _showProfileDetailOpenSwipeStack = false;
  bool _openProfileDetailAfterSwipeAnimation = false;
  double _profileDetailOpenDragDistance = 0;
  double _profileDetailOpenSwipeProgress = 0;
  double _profileDetailBackgroundParallaxProgress = 0;
  ShakeDetector? _shakeDetector;
  Timer? _profileWarmupTimer;
  ProfileDetailPrewarmTarget? _activeProfileWarmupTarget;
  bool _hasQueuedProfileWarmupIconPrecache = false;
  final AppleLiquidSheetController _jobsFilterSheetController =
      AppleLiquidSheetController();
  late final AnimationController _profileDetailOpenSwipeController;
  Animation<double>? _profileDetailOpenSwipeAnimation;

  @override
  void initState() {
    super.initState();
    _profileDetailOpenSwipeController =
        AnimationController(
            vsync: this,
            duration: _profileDetailOpenSwipeSettleDuration,
          )
          ..addListener(_syncProfileDetailOpenSwipeAnimation)
          ..addStatusListener(_handleProfileDetailOpenSwipeAnimationStatus);
    _loadThemePreference();
    _initializeShakeDetector();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _syncDelayedProfileWarmup();
    });
  }

  void _initializeShakeDetector() {
    _shakeDetector = ShakeDetector(
      onShake: () {
        if (mounted) {
          setState(() {
            _showShakeOverlay = true;
          });
        }
      },
    );
    _shakeDetector!.startListening();
  }

  void _dismissShakeOverlay() {
    setState(() {
      _showShakeOverlay = false;
    });
  }

  @override
  void dispose() {
    _profileWarmupTimer?.cancel();
    _jobsFilterSheetController.dispose();
    _profileDetailOpenSwipeController.dispose();
    _shakeDetector = null;
    super.dispose();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = prefs.getString('theme_mode') ?? 'auto';
    });
  }

  void _pauseProfileWarmupForDetailRoute() {
    _profileWarmupTimer?.cancel();
    _profileWarmupTimer = null;
    setState(() {
      _isProfileDetailRouteOpen = true;
      _activeProfileWarmupTarget = null;
    });
  }

  void _resumeProfileWarmupAfterDetailRoute() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isProfileDetailRouteOpen = false;
    });
    _syncDelayedProfileWarmup();
  }

  void _pushWithFade(Widget page) {
    _pauseProfileWarmupForDetailRoute();
    Navigator.of(context)
        .push(
          buildProfileDetailFadeRoute<void>(
            page: page,
            onBackgroundProgressChanged: _setProfileDetailBackgroundParallax,
            transitionDuration: _tabFadeInDuration,
            reverseTransitionDuration: _tabFadeOutDuration,
          ),
        )
        .whenComplete(_resumeProfileWarmupAfterDetailRoute);
  }

  void _pushWithSwipe(
    Widget page, {
    Duration transitionDuration = kProfileDetailSwipeDuration,
    Duration? reverseTransitionDuration,
  }) {
    _pauseProfileWarmupForDetailRoute();
    Navigator.of(context)
        .push(
          buildProfileDetailSwipeRoute<void>(
            page: page,
            onBackgroundProgressChanged: _setProfileDetailBackgroundParallax,
            transitionDuration: transitionDuration,
            reverseTransitionDuration: reverseTransitionDuration,
          ),
        )
        .whenComplete(_resumeProfileWarmupAfterDetailRoute);
  }

  void _openProfileDetailPage(WidgetBuilder pageBuilder) {
    _lastProfileDetailPageBuilder = pageBuilder;
    _pushWithFade(pageBuilder(context));
  }

  void _setProfileDetailBackgroundParallax(double progress) {
    if (!mounted) {
      return;
    }

    final double nextProgress = progress.clamp(0.0, 1.0).toDouble();
    if ((_profileDetailBackgroundParallaxProgress - nextProgress).abs() <=
        0.001) {
      return;
    }

    setState(() {
      _profileDetailBackgroundParallaxProgress = nextProgress;
    });
  }

  bool get _canOpenLastProfileDetailFromProfile {
    return _bottomNavIndex == _profileTabIndex &&
        _lastProfileDetailPageBuilder != null;
  }

  void _startProfileDetailOpenSwipe(DragStartDetails _) {
    if (!_canOpenLastProfileDetailFromProfile) {
      return;
    }

    _profileDetailOpenSwipeController.stop();
    _profileDetailOpenSwipeAnimation = null;
    setState(() {
      _showProfileDetailOpenSwipeStack = true;
      _openProfileDetailAfterSwipeAnimation = false;
      _profileDetailOpenDragDistance = 0;
      _profileDetailOpenSwipeProgress = 0;
      _profileDetailBackgroundParallaxProgress = 0;
    });
  }

  void _updateProfileDetailOpenSwipe(DragUpdateDetails details, double width) {
    if (!_showProfileDetailOpenSwipeStack || width <= 0) {
      return;
    }

    final double primaryDelta = details.primaryDelta ?? 0;
    final double nextDragDistance =
        (_profileDetailOpenDragDistance - primaryDelta)
            .clamp(0.0, double.infinity)
            .toDouble();
    final double nextProgress = (nextDragDistance / width)
        .clamp(0.0, 1.0)
        .toDouble();
    if ((nextProgress - _profileDetailOpenSwipeProgress).abs() <= 0.001) {
      _profileDetailOpenDragDistance = nextDragDistance;
      return;
    }

    setState(() {
      _profileDetailOpenDragDistance = nextDragDistance;
      _profileDetailOpenSwipeProgress = nextProgress;
      _profileDetailBackgroundParallaxProgress = nextProgress;
    });
  }

  void _endProfileDetailOpenSwipe(DragEndDetails details, double width) {
    final WidgetBuilder? pageBuilder = _lastProfileDetailPageBuilder;
    if (!_showProfileDetailOpenSwipeStack ||
        pageBuilder == null ||
        width <= 0) {
      _profileDetailOpenDragDistance = 0;
      return;
    }

    final double velocity = details.primaryVelocity ?? 0;
    final double distanceThreshold =
        width * _profileDetailOpenSwipeDistanceFraction;
    final bool isCancelFling =
        velocity > _profileDetailOpenSwipeMinFlingVelocity;
    final bool hasOpenFling =
        velocity < -_profileDetailOpenSwipeMinFlingVelocity;
    final bool hasOpenDistance =
        _profileDetailOpenDragDistance >= distanceThreshold ||
        _profileDetailOpenSwipeProgress >=
            _profileDetailOpenSwipeDistanceFraction;
    final bool shouldOpenDetailPage =
        !isCancelFling && (hasOpenFling || hasOpenDistance);

    _animateProfileDetailOpenSwipeTo(
      shouldOpenDetailPage ? 1 : 0,
      openDetailPage: shouldOpenDetailPage,
    );
  }

  void _cancelProfileDetailOpenSwipe() {
    if (!_showProfileDetailOpenSwipeStack) {
      _profileDetailOpenDragDistance = 0;
      return;
    }

    _animateProfileDetailOpenSwipeTo(0, openDetailPage: false);
  }

  void _animateProfileDetailOpenSwipeTo(
    double target, {
    required bool openDetailPage,
  }) {
    _profileDetailOpenSwipeController.stop();
    final double animationDistance = (target - _profileDetailOpenSwipeProgress)
        .abs();
    final int durationMs =
        (_profileDetailOpenSwipeSettleDuration.inMilliseconds *
                animationDistance)
            .round()
            .clamp(90, _profileDetailOpenSwipeSettleDuration.inMilliseconds)
            .toInt();
    _profileDetailOpenSwipeController.duration = Duration(
      milliseconds: durationMs,
    );
    _profileDetailOpenSwipeAnimation =
        Tween<double>(
          begin: _profileDetailOpenSwipeProgress,
          end: target,
        ).animate(
          CurvedAnimation(
            parent: _profileDetailOpenSwipeController,
            curve: Curves.easeOutCubic,
          ),
        );
    _openProfileDetailAfterSwipeAnimation = openDetailPage;
    _profileDetailOpenSwipeController.forward(from: 0);
  }

  void _syncProfileDetailOpenSwipeAnimation() {
    final Animation<double>? animation = _profileDetailOpenSwipeAnimation;
    if (animation == null || !mounted) {
      return;
    }

    setState(() {
      final double nextProgress = animation.value.clamp(0.0, 1.0).toDouble();
      _profileDetailOpenSwipeProgress = nextProgress;
      _profileDetailBackgroundParallaxProgress = nextProgress;
    });
  }

  void _handleProfileDetailOpenSwipeAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }

    final bool shouldOpenDetailPage = _openProfileDetailAfterSwipeAnimation;
    final WidgetBuilder? pageBuilder = _lastProfileDetailPageBuilder;
    setState(() {
      _profileDetailOpenSwipeAnimation = null;
      _showProfileDetailOpenSwipeStack = false;
      _openProfileDetailAfterSwipeAnimation = false;
      _profileDetailOpenDragDistance = 0;
      _profileDetailOpenSwipeProgress = 0;
      _profileDetailBackgroundParallaxProgress = shouldOpenDetailPage ? 1 : 0;
    });

    if (shouldOpenDetailPage && pageBuilder != null) {
      _pushWithSwipe(
        pageBuilder(context),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: kProfileDetailSwipeDuration,
      );
    }
  }

  void _resetProfileDetailOpenSwipeState() {
    _profileDetailOpenSwipeController.stop();
    _profileDetailOpenSwipeAnimation = null;
    _showProfileDetailOpenSwipeStack = false;
    _openProfileDetailAfterSwipeAnimation = false;
    _profileDetailOpenDragDistance = 0;
    _profileDetailOpenSwipeProgress = 0;
    _profileDetailBackgroundParallaxProgress = 0;
  }

  bool _showsHomeTopBarChromeForIndex(int index) {
    final bool showBellButton =
        index != _activityTabIndex &&
        index != _profileTabIndex &&
        index != _createTabIndex;
    final bool showCreateTitle = index == _createTabIndex;
    final bool showActivityTitle = index == _activityTabIndex;
    final bool showBrandTitle =
        !showActivityTitle && index != _profileTabIndex && !showCreateTitle;
    return showBellButton ||
        showBrandTitle ||
        showCreateTitle ||
        showActivityTitle;
  }

  void _setTopBarScrolledUnder(bool value) {
    if (_isTopBarScrolledUnder == value) {
      return;
    }

    setState(() {
      _isTopBarScrolledUnder = value;
    });
  }

  bool _handleHomeScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical ||
        !_showsHomeTopBarChromeForIndex(_bottomNavIndex)) {
      return false;
    }

    _setTopBarScrolledUnder(
      notification.metrics.extentBefore > _topBarScrolledUnderOffset,
    );
    return false;
  }

  Color _resolveTopBarBackgroundColor(Color baseColor, bool isDark) {
    final double lightnessDelta = isDark ? 0.045 : 0.055;
    final HSLColor hslColor = HSLColor.fromColor(baseColor);
    return hslColor
        .withLightness(
          (hslColor.lightness + lightnessDelta).clamp(0.0, 1.0).toDouble(),
        )
        .toColor();
  }

  Widget _buildProfileDetailSwipePreview({
    required WidgetBuilder pageBuilder,
    required MediaQueryData mediaQuery,
    required ThemeData theme,
  }) {
    return Theme(
      data: theme,
      child: MediaQuery(
        data: mediaQuery,
        child: Navigator(
          key: ValueKey<WidgetBuilder>(pageBuilder),
          initialRoute: '/profile-detail-preview',
          onGenerateRoute: (settings) {
            return PageRouteBuilder<void>(
              settings: settings,
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              pageBuilder: (context, animation, secondaryAnimation) {
                if (settings.name == Navigator.defaultRouteName) {
                  return const SizedBox.shrink();
                }

                return pageBuilder(context);
              },
            );
          },
        ),
      ),
    );
  }

  void _syncDelayedProfileWarmup({
    Duration delay = _startTabProfileWarmupDelay,
  }) {
    _profileWarmupTimer?.cancel();
    _profileWarmupTimer = null;

    if (_isProfileDetailRouteOpen ||
        _bottomNavIndex != _startTabIndex ||
        _activeProfileWarmupTarget != null) {
      return;
    }

    if (nextPendingProfileDetailWarmupTarget() == null) {
      return;
    }

    _profileWarmupTimer = Timer(delay, () {
      if (!mounted ||
          _isProfileDetailRouteOpen ||
          _bottomNavIndex != _startTabIndex ||
          _activeProfileWarmupTarget != null) {
        return;
      }

      final ProfileDetailPrewarmTarget? target =
          nextPendingProfileDetailWarmupTarget();
      if (target == null) {
        return;
      }

      if (!_hasQueuedProfileWarmupIconPrecache) {
        _hasQueuedProfileWarmupIconPrecache = true;
        unawaited(precacheProfileDetailWarmupIcons(context));
      }

      setState(() {
        _activeProfileWarmupTarget = target;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(_warmupUnmountDelay, () {
          if (!mounted) {
            return;
          }
          setState(() {
            _activeProfileWarmupTarget = null;
          });
          _syncDelayedProfileWarmup(delay: _startTabProfileWarmupGap);
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData rootMediaQuery = MediaQuery.of(context);
    final ThemeData rootTheme = Theme.of(context);
    final bool isDark = _themeMode == 'auto'
        ? rootMediaQuery.platformBrightness == Brightness.dark
        : _themeMode == 'dark';
    final EdgeInsets viewPadding = rootMediaQuery.padding;
    final double topBarInset = viewPadding.top + kToolbarHeight;
    final ui = UiScale.of(context, designWidth: 402);
    double s(double value) => ui.s(value);
    final double profileHeaderTopInset = (((kToolbarHeight - s(28)) / 2) - s(2))
        .clamp(0.0, kToolbarHeight)
        .toDouble();
    final double safeBottom = viewPadding.bottom;
    final double bottomInset = safeBottom > s(4) ? safeBottom : s(4);
    final double bottomNavHeight = s(64);
    final double profileBottomGap = s(19);
    final double profileBottomBoxHeight = s(116);
    final Color bgColor = isDark
        ? const Color(0xFF020202)
        : const Color(0xFFE6E6E6);
    final Color cardColor = isDark
        ? const Color(0xFF0D0D0D)
        : const Color(0xFFF2F2F2);
    final Color startActionButtonColor = isDark
        ? const Color(0xFF111111)
        : const Color(0xFF0D0D0D);
    final Color startActionButtonActiveColor = isDark
        ? const Color(0xFF1C1C1E)
        : const Color(0xFF1A1A1A);
    const Color startActionButtonTextColor = Color(0xFFF2F2F2);
    const Color startActionButtonIconColor = Color(0xFFEBEBEB);
    final Color borderColor = isDark
        ? const Color.fromRGBO(255, 255, 255, 0.18)
        : const Color(0xFFCCCCCC);
    final Color secondaryText = isDark
        ? const Color.fromRGBO(255, 255, 255, 0.7)
        : const Color.fromRGBO(13, 13, 13, 0.7);
    final Color jobCardColor = isDark ? cardColor : const Color(0xFFF2F2F2);
    final Color jobButtonColor = isDark
        ? const Color(0xFF1A1A1A)
        : Colors.white;
    final Color textColor = isDark
        ? const Color(0xFFF2F2F2)
        : const Color(0xFF0D0D0D);
    final Color timeTextColor = isDark
        ? const Color(0xFFB3B3B3)
        : const Color(0xFF4D4D4D);
    final Color bellIconColor = isDark ? Colors.white : const Color(0xFF0D0D0D);
    final Color buttonTextColor = isDark
        ? const Color(0xFFF2F2F2)
        : const Color(0xFF0D0D0D);
    final Color topBarScrolledBackgroundColor = _resolveTopBarBackgroundColor(
      bgColor,
      isDark,
    );
    final Color topBarBackgroundColor = _isTopBarScrolledUnder
        ? topBarScrolledBackgroundColor
        : bgColor;
    final SystemUiOverlayStyle overlayStyle = isDark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    final bool showBellButton =
        _bottomNavIndex != _activityTabIndex &&
        _bottomNavIndex != _profileTabIndex &&
        _bottomNavIndex != _createTabIndex;
    final bool showCreateTitle = _bottomNavIndex == _createTabIndex;
    final bool showActivityTitle = _bottomNavIndex == _activityTabIndex;
    final bool showBrandTitle =
        !showActivityTitle &&
        _bottomNavIndex != _profileTabIndex &&
        !showCreateTitle;
    final bool showAppBarChrome =
        showBellButton ||
        showBrandTitle ||
        showCreateTitle ||
        showActivityTitle;

    Widget content;
    switch (selectedIndex) {
      case 0:
        content = JobsFindContent(
          cardColor: cardColor,
          secondaryText: secondaryText,
          borderColor: borderColor,
          textColor: textColor,
          jobCardColor: jobCardColor,
          jobButtonColor: jobButtonColor,
          timeTextColor: timeTextColor,
          filterIconColor: bellIconColor,
          themeMode: _themeMode,
          buttonTextColor: buttonTextColor,
          sheetController: _jobsFilterSheetController,
        );
        break;
      case 1:
        content = ServicesContent(
          cardColor: cardColor,
          secondaryText: secondaryText,
          borderColor: borderColor,
          textColor: textColor,
          jobCardColor: jobCardColor,
          jobButtonColor: jobButtonColor,
          timeTextColor: timeTextColor,
          buttonTextColor: buttonTextColor,
        );
        break;
      default:
        content = const SizedBox();
    }

    Widget buildCreateContent() {
      return CreateTabContent(
        cardColor: cardColor,
        secondaryText: secondaryText,
        borderColor: borderColor,
        textColor: textColor,
        jobCardColor: jobCardColor,
        jobButtonColor: jobButtonColor,
        timeTextColor: timeTextColor,
        buttonTextColor: buttonTextColor,
        scrollBottomPadding: bottomNavHeight + bottomInset,
      );
    }

    Widget withPullToRefresh(Widget child, {EdgeInsetsGeometry? padding}) {
      final Widget scrollable = SingleChildScrollView(
        primary: false,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: padding,
        child: child,
      );

      return StretchingOverscrollIndicator(
        axisDirection: AxisDirection.down,
        child: scrollable,
      );
    }

    Widget buildStartActionButton({
      required int index,
      required String iconPath,
      required String label,
    }) {
      final bool isSelected = selectedIndex == index;
      return HomeActionButton(
        iconPath: iconPath,
        label: label,
        color: isSelected
            ? startActionButtonActiveColor
            : startActionButtonColor,
        onTap: () => setState(() => selectedIndex = index),
        isSelected: isSelected,
        textColor: startActionButtonTextColor,
        iconColor: startActionButtonIconColor,
      );
    }

    Widget buildTab(int index) {
      switch (index) {
        case _startTabIndex:
          final Widget startContent = withPullToRefresh(
            Padding(
              padding: EdgeInsets.only(
                top: topBarInset,
                bottom: s(92),
                left: s(16),
                right: s(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      buildStartActionButton(
                        index: 0,
                        iconPath: 'assets/icons/briefcase.fill.svg',
                        label: 'Jobs finden',
                      ),
                      SizedBox(width: s(12)),
                      buildStartActionButton(
                        index: 1,
                        iconPath:
                            'assets/icons/list.bullet.rectangle.portrait.fill.svg',
                        label: 'Services',
                      ),
                    ],
                  ),
                  SizedBox(height: s(28)),
                  AnimatedSwitcher(
                    duration: _tabFadeInDuration,
                    reverseDuration: _tabFadeOutDuration,
                    switchInCurve: Curves.easeIn,
                    switchOutCurve: Curves.easeOut,
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        alignment: Alignment.topCenter,
                        children: [...previousChildren, ?currentChild],
                      );
                    },
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                      child: child,
                    ),
                    child: KeyedSubtree(
                      key: ValueKey<int>(selectedIndex),
                      child: content,
                    ),
                  ),
                  SizedBox(height: s(24)),
                ],
              ),
            ),
            padding: EdgeInsets.zero,
          );
          return AppleLiquidSheetBackgroundInteractionGuard(
            controller: _jobsFilterSheetController,
            child: startContent,
          );
        case _activityTabIndex:
          return withPullToRefresh(
            ActivityTabContent(jobCardColor: jobCardColor),
            padding: EdgeInsets.only(
              top: topBarInset,
              bottom: s(92),
              left: s(16),
              right: s(16),
            ),
          );
        case _profileTabIndex:
          final double profileBottomExtra = _showProfileInfoBox
              ? profileBottomGap + profileBottomBoxHeight
              : 0;
          final Widget profileTabContent = Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: viewPadding.top,
                  left: s(16),
                  right: s(16),
                ),
                child: SizedBox.expand(
                  child: RepaintBoundary(
                    child: ProfileTabContent(
                      userProfile: widget.userProfile,
                      textColor: textColor,
                      headerTopInset: profileHeaderTopInset,
                      isDark: isDark,
                      scrollBottomPadding:
                          bottomNavHeight + bottomInset + profileBottomExtra,
                      warmupPaused: _isProfileDetailRouteOpen,
                      onOpenDetailPage: _openProfileDetailPage,
                    ),
                  ),
                ),
              ),
              if (_showProfileInfoBox)
                Positioned(
                  left: viewPadding.left + s(16),
                  right: viewPadding.right + s(16),
                  bottom: bottomNavHeight + bottomInset + profileBottomGap,
                  child: RepaintBoundary(
                    child: _ProfileVerificationInfoBox(
                      isDark: isDark,
                      useGlassEffects: true,
                      s: s,
                      onDismiss: () {
                        setState(() {
                          _showProfileInfoBox = false;
                        });
                      },
                      onVerifyNow: () {
                        _openProfileDetailPage(
                          (_) => VerificationPage(
                            userProfile: widget.userProfile,
                            isDarkOverride: isDark,
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
          return LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final double parallaxProgress =
                  _profileDetailBackgroundParallaxProgress
                      .clamp(0.0, 1.0)
                      .toDouble();
              final Widget profileTab = Transform.translate(
                offset: Offset(
                  -width *
                      _profileDetailBackgroundParallaxFraction *
                      parallaxProgress,
                  0,
                ),
                child: profileTabContent,
              );

              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragStart: _startProfileDetailOpenSwipe,
                onHorizontalDragUpdate: (details) {
                  _updateProfileDetailOpenSwipe(details, width);
                },
                onHorizontalDragEnd: (details) {
                  _endProfileDetailOpenSwipe(details, width);
                },
                onHorizontalDragCancel: _cancelProfileDetailOpenSwipe,
                child: profileTab,
              );
            },
          );
        case _createTabIndex:
          return Padding(
            padding: EdgeInsets.only(
              top: topBarInset,
              left: s(16),
              right: s(16),
            ),
            child: SizedBox.expand(child: buildCreateContent()),
          );
        case _notificationsTabIndex:
          return Center(
            child: Text(
              'Notifications',
              style: TextStyle(
                color: textColor,
                fontSize: s(24),
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        default:
          return const SizedBox.shrink();
      }
    }

    final scaffold = Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        systemOverlayStyle: overlayStyle,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        leadingWidth: showCreateTitle || showActivityTitle ? 0 : s(56),
        leading: showCreateTitle || showActivityTitle
            ? const SizedBox.shrink()
            : AnimatedSwitcher(
                duration: _tabFadeInDuration,
                reverseDuration: _tabFadeOutDuration,
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [...previousChildren, ?currentChild],
                  );
                },
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  ),
                  child: child,
                ),
                child: !showBellButton
                    ? const SizedBox(key: ValueKey<String>('appbar-no-bell'))
                    : IconButton(
                        key: ValueKey<String>('appbar-bell-$_bottomNavIndex'),
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              color: bellIconColor,
                              size: s(28),
                            ),
                            Positioned(
                              top: s(-2),
                              right: s(-2),
                              child: Container(
                                width: s(8),
                                height: s(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF007AFF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onPressed: () {
                          setState(() {
                            _resetProfileDetailOpenSwipeState();
                            if (_bottomNavIndex == _notificationsTabIndex) {
                              _bottomNavIndex = _mainTabIndex;
                            } else {
                              if (_bottomNavIndex <= _createTabIndex) {
                                _mainTabIndex = _bottomNavIndex;
                              }
                              _bottomNavIndex = _notificationsTabIndex;
                            }
                            _isTopBarScrolledUnder = false;
                          });
                          _syncDelayedProfileWarmup();
                        },
                      ),
              ),
        title: const SizedBox.shrink(),
        centerTitle: false,
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleHomeScrollNotification,
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: _tabFadeInDuration,
              reverseDuration: _tabFadeOutDuration,
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.topCenter,
                  children: [...previousChildren, ?currentChild],
                );
              },
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: child,
              ),
              child: KeyedSubtree(
                key: ValueKey<int>(_bottomNavIndex),
                child: SizedBox.expand(child: buildTab(_bottomNavIndex)),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: showAppBarChrome ? 1 : 0),
                  duration: showAppBarChrome
                      ? _tabFadeInDuration
                      : _tabFadeOutDuration,
                  curve: Curves.easeInOut,
                  builder: (context, opacity, child) {
                    if (opacity <= 0) {
                      return const SizedBox.shrink();
                    }

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      height: topBarInset,
                      color: topBarBackgroundColor.withValues(alpha: opacity),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: viewPadding.top,
              left: 0,
              right: 0,
              height: kToolbarHeight,
              child: IgnorePointer(
                child: AnimatedSwitcher(
                  duration: _tabFadeInDuration,
                  reverseDuration: _tabFadeOutDuration,
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        for (final child in previousChildren)
                          Center(child: child),
                        if (currentChild != null) Center(child: currentChild),
                      ],
                    );
                  },
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    ),
                    child: child,
                  ),
                  child: showCreateTitle
                      ? Text(
                          'Was möchtest du erstellen?',
                          key: const ValueKey<String>('appbar-create-title'),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: s(22),
                          ),
                        )
                      : showActivityTitle
                      ? Text(
                          'Deine Aufträge',
                          key: const ValueKey<String>('appbar-activity-title'),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: s(22),
                          ),
                        )
                      : !showBrandTitle
                      ? const SizedBox(key: ValueKey<String>('appbar-no-title'))
                      : Text(
                          'Nawly',
                          key: const ValueKey<String>('appbar-title'),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: s(28),
                          ),
                        ),
                ),
              ),
            ),
            ShakeOverlay(
              isVisible: _showShakeOverlay,
              onDismiss: _dismissShakeOverlay,
            ),
            if (_activeProfileWarmupTarget != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: TickerMode(
                    enabled: false,
                    child: Offstage(
                      offstage: true,
                      child: ProfileDetailPrewarmHost(
                        target: _activeProfileWarmupTarget!,
                        isDark: isDark,
                        userProfile: widget.userProfile,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: s(85),
        child: AppleLiquidTabBar(
          currentIndex: _bottomNavIndex <= _createTabIndex
              ? _bottomNavIndex
              : _mainTabIndex,
          height: s(85),
          selectedTintColor: const Color(0xFF007AFF),
          items: const <AppleLiquidTabItem>[
            AppleLiquidTabItem(title: 'Start', systemImage: 'house.fill'),
            AppleLiquidTabItem(
              title: 'Aktivität',
              systemImage: 'list.bullet.rectangle.portrait.fill',
            ),
            AppleLiquidTabItem(
              title: 'Profil',
              systemImage: 'person.fill',
              notificationDotColor: Color(0xFF007AFF),
              notificationBadgeValue: '3',
            ),
          ],
          searchItem: const AppleLiquidTabItem(
            title: 'Erstellen',
            systemImage: 'plus',
            isSearch: true,
          ),
          onChanged: (index) {
            HapticFeedback.selectionClick();
            setState(() {
              _resetProfileDetailOpenSwipeState();
              if (index == _startTabIndex &&
                  _bottomNavIndex == _startTabIndex) {
                selectedIndex = 0;
              } else {
                _bottomNavIndex = index;
                _mainTabIndex = index;
                _isTopBarScrolledUnder = false;
              }
            });
            _syncDelayedProfileWarmup();
          },
        ),
      ),
    );

    final Widget scaffoldWithSwipeOverlay = LayoutBuilder(
      builder: (context, constraints) {
        final WidgetBuilder? detailPageBuilder = _lastProfileDetailPageBuilder;
        final bool showOpenSwipeStack =
            _showProfileDetailOpenSwipeStack && detailPageBuilder != null;
        final double openSwipeProgress = _profileDetailOpenSwipeProgress
            .clamp(0.0, 1.0)
            .toDouble();

        return Stack(
          fit: StackFit.expand,
          children: [
            scaffold,
            if (showOpenSwipeStack)
              Positioned.fill(
                child: IgnorePointer(
                  child: Transform.translate(
                    offset: Offset(
                      constraints.maxWidth * (1 - openSwipeProgress),
                      0,
                    ),
                    child: _buildProfileDetailSwipePreview(
                      pageBuilder: detailPageBuilder,
                      mediaQuery: rootMediaQuery,
                      theme: rootTheme,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.apply(fontFamily: 'SF Pro'),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          color: bgColor,
          child: scaffoldWithSwipeOverlay,
        ),
      ),
    );
  }
}

class _ProfileVerificationInfoBox extends StatelessWidget {
  const _ProfileVerificationInfoBox({
    required this.isDark,
    required this.useGlassEffects,
    required this.s,
    required this.onDismiss,
    required this.onVerifyNow,
  });

  final bool isDark;
  final bool useGlassEffects;
  final double Function(double) s;
  final VoidCallback onDismiss;
  final VoidCallback onVerifyNow;

  @override
  Widget build(BuildContext context) {
    final double infoBoxRadius = s(15);
    final double infoNestedRadius = s(7);

    final Widget content = Stack(
      children: [
        Positioned(
          top: s(8),
          left: s(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: s(8), vertical: s(2)),
                decoration: BoxDecoration(
                  color: HSLColor.fromAHSL(0.3, 211, 1.0, 0.50).toColor(),
                  borderRadius: BorderRadius.circular(infoNestedRadius),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Wichtig',
                  textAlign: TextAlign.center,
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
                'Verifiziere deinen Account',
                style: TextStyle(
                  color: const Color(0xFFBCBCBC),
                  fontSize: s(15),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: s(2)),
              Text(
                'Verifiziere bitte deine Email und deine\nTelefonnummer um loszulegen.',
                style: TextStyle(
                  color: const Color(0xFF747474),
                  fontSize: s(11.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDismiss,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(top: s(12), right: s(12)),
                    child: SFSymbolHelper.getIcon(
                      iconPath: 'assets/icons/xmark.svg',
                      width: s(15),
                      height: s(15),
                      color: const Color(0xFF747474),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: s(8),
          bottom: s(8),
          child: Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onVerifyNow,
              child: SizedBox(
                width: s(70),
                height: 44,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: s(70),
                    height: s(23),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: HSLColor.fromAHSL(0.50, 0, 0, 0.10).toColor(),
                        borderRadius: BorderRadius.circular(infoNestedRadius),
                        border: Border.all(
                          width: s(1),
                          color: HSLColor.fromAHSL(0.84, 0, 0, 0.18).toColor(),
                          strokeAlign: BorderSide.strokeAlignInside,
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Jetzt',
                              style: TextStyle(
                                color: const Color(0xFFB3B3B3),
                                fontSize: s(14),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: s(5)),
                            SFSymbolHelper.getIcon(
                              iconPath: 'assets/icons/arrow.up.right.svg',
                              width: s(12),
                              height: s(12),
                              color: const Color(0xFFB3B3B3),
                            ),
                          ],
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
    );

    final Widget glassChild = GlassSurface(
      config: LiquidGlassStyle.infoBox(isDark: isDark, s: s),
      isDark: isDark,
      borderRadius: infoBoxRadius,
      child: content,
    );

    final Widget lightweightChild = ClipRRect(
      borderRadius: BorderRadius.circular(infoBoxRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark
              ? const Color.fromRGBO(13, 13, 13, 0.94)
              : const Color.fromRGBO(255, 255, 255, 0.94),
          borderRadius: BorderRadius.circular(infoBoxRadius),
          border: Border.all(
            color: isDark
                ? const Color.fromRGBO(255, 255, 255, 0.08)
                : const Color(0xFFD9D9D9),
            width: s(1),
          ),
        ),
        child: content,
      ),
    );

    final Widget decoratedCard = AnimatedSwitcher(
      duration: const Duration(milliseconds: 140),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeOut,
      child: useGlassEffects
          ? GlassPressable(
              key: const ValueKey<String>('profile-info-glass'),
              borderRadius: infoBoxRadius,
              child: glassChild,
            )
          : SizedBox.expand(
              key: const ValueKey<String>('profile-info-flat'),
              child: lightweightChild,
            ),
    );

    return SizedBox(height: s(124), child: decoratedCard);
  }
}
