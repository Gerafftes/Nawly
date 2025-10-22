import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/start-tab/ich_helfe_gerne.dart';
import 'pages/start-tab/erstellen.dart';
import 'pages/start-tab/feste_angebote.dart';
import 'pages/profile_tab.dart';
import 'pages/support_tab.dart';
import 'widgets/home_action_button.dart';
import 'widgets/shake_overlay.dart';
import 'services/shake_detector.dart';
import 'services/sf_symbol_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MiniJobNow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007AFF)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  int _bottomNavIndex = 0;
  int _mainTabIndex = 0;
  String _themeMode = 'auto'; // 'light', 'auto', 'dark'
  bool _showShakeOverlay = false;
  ShakeDetector? _shakeDetector;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
    _initializeShakeDetector();
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
    _shakeDetector = null;
    super.dispose();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = prefs.getString('theme_mode') ?? 'auto';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        _themeMode == 'auto'
            ? MediaQuery.of(context).platformBrightness == Brightness.dark
            : _themeMode == 'dark';
    final Color bgColor = isDark ? Colors.black : const Color(0xFFE6E6E6);
    final Color cardColor =
        isDark
            ? const Color(0xFF0D0D0D)
            : const Color(0xFFF2F2F2); // Nicht ausgewählt
    final Color cardColorActive =
        isDark ? const Color(0xFF1A1A1A) : Colors.white; // Ausgewählt
    final Color borderColor =
        isDark
            ? const Color.fromRGBO(255, 255, 255, 0.18)
            : const Color(0xFFCCCCCC);
    final Color secondaryText =
        isDark
            ? const Color.fromRGBO(255, 255, 255, 0.7)
            : const Color.fromRGBO(13, 13, 13, 0.7);
    final Color jobCardColor = isDark ? cardColor : const Color(0xFFF2F2F2);
    final Color jobButtonColor =
        isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final Color textColor =
        isDark ? const Color(0xFFF2F2F2) : const Color(0xFF0D0D0D);
    final Color timeTextColor =
        isDark ? const Color(0xFFB3B3B3) : const Color(0xFF4D4D4D);
    final Color bellIconColor = isDark ? Colors.white : const Color(0xFF0D0D0D);
    final Color homeActionIconColor =
        isDark ? Colors.white : const Color(0xFF1A1A1A);
    final Color buttonTextColor =
        isDark ? const Color(0xFFF2F2F2) : const Color(0xFF0D0D0D);

    Widget content;
    switch (selectedIndex) {
      case 0:
        content = IchHelfeGerneContent(
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
        );
        break;
      case 1:
        content = HilfeSuchenContent(
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
      case 2:
        content = IchBieteAnContent(
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

    Widget withPullToRefresh(Widget child, {EdgeInsetsGeometry? padding}) {
      final Widget scrollable = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: padding,
        child: child,
      );

      // Keep the organic stretch/bounce, but remove the spinner animation
      // by omitting RefreshIndicator.
      return StretchingOverscrollIndicator(
        axisDirection: AxisDirection.down,
        child: scrollable,
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'SF Pro'),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        color: bgColor,
        child: Scaffold(
          backgroundColor: bgColor,
          extendBody: true,
          appBar: _bottomNavIndex == 2
              ? null
              : AppBar(
                  backgroundColor: bgColor,
                  elevation: 0,
                  leading: IconButton(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          color: bellIconColor,
                          size: 28,
                        ),
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF2121),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onPressed: () => setState(() => _bottomNavIndex = 3),
                  ),
                  title: Text(
                    'MiniJobNow',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    GestureDetector(
                      onTap: () => setState(() => _bottomNavIndex = 2),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: CircleAvatar(
                          backgroundColor: cardColor,
                          radius: 20,
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          body: Stack(
            children: [
              IndexedStack(
                index: _bottomNavIndex,
                children: [
                  withPullToRefresh(
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 92,
                        left: 16.0,
                        right: 16.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          // Drei große Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              HomeActionButton(
                                iconPath: 'assets/icons/wrench.and.screwdriver.svg',
                                label: 'Ich helfe\ngern',
                                color:
                                    selectedIndex == 0
                                        ? cardColorActive
                                        : cardColor,
                                onTap: () => setState(() => selectedIndex = 0),
                                isSelected: selectedIndex == 0,
                                textColor: textColor,
                                iconColor:
                                    isDark
                                        ? const Color(0xFFEBEBEB)
                                        : const Color(0xFF1A1A1A),
                              ),
                              HomeActionButton(
                                iconPath: 'assets/icons/plus.svg',
                                label: 'Aufträge\nerstellen',
                                color:
                                    selectedIndex == 1
                                        ? cardColorActive
                                        : cardColor,
                                onTap: () => setState(() => selectedIndex = 1),
                                isSelected: selectedIndex == 1,
                                textColor: textColor,
                                iconColor:
                                    isDark
                                        ? const Color(0xFFEBEBEB)
                                        : const Color(0xFF1A1A1A),
                              ),
                              HomeActionButton(
                                iconPath: 'assets/icons/list.bullet.rectangle.portrait.fill.svg',
                                label: 'Feste\nDienstl.',
                                color:
                                    selectedIndex == 2
                                        ? cardColorActive
                                        : cardColor,
                                onTap: () => setState(() => selectedIndex = 2),
                                isSelected: selectedIndex == 2,
                                textColor: textColor,
                                iconColor:
                                    isDark
                                        ? const Color(0xFFEBEBEB)
                                        : const Color(0xFF1A1A1A),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          content,
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  withPullToRefresh(
                    const SupportTabContent(),
                    padding: const EdgeInsets.only(
                      bottom: 92,
                      left: 16.0,
                      right: 16.0,
                    ),
                  ),
                  withPullToRefresh(
                    ProfileTabContent(
                      textColor: textColor,
                    ),
                    padding: const EdgeInsets.only(
                      bottom: 92,
                      left: 16.0,
                      right: 16.0,
                    ),
                  ),
                  Center(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              ShakeOverlay(
                isVisible: _showShakeOverlay,
                onDismiss: _dismissShakeOverlay,
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.only(bottom: 4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: SizedBox(
                  height: 64,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                        child: const SizedBox(),
                      ),
                      LiquidGlass(
                        clipBehavior: Clip.antiAlias,
                        shape: const LiquidRoundedSuperellipse(
                          borderRadius: Radius.circular(36),
                        ),
                        glassContainsChild: false,
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            canvasColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            bottomNavigationBarTheme:
                                BottomNavigationBarThemeData(
                                  selectedItemColor:
                                      isDark
                                          ? Colors.white
                                          : const Color(0xFF000000),
                                  unselectedItemColor:
                                      isDark
                                          ? const Color.fromARGB(
                                            153,
                                            255,
                                            255,
                                            255,
                                          )
                                          : const Color(0xFF333333),
                                ),
                          ),
                          child: BottomNavigationBar(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            showSelectedLabels: true,
                            showUnselectedLabels: true,
                            selectedLabelStyle: TextStyle(
                              fontWeight: FontWeight.w500, // Medium weight
                            ),
                            unselectedLabelStyle: TextStyle(
                              fontWeight: FontWeight.w500, // Medium weight
                            ),
                            items: [
                              BottomNavigationBarItem(
                                icon: SFSymbolHelper.getBottomNavIcon(
                                  sfSymbolName: 'house',
                                  size: 20,
                                  color: isDark
                                      ? const Color.fromARGB(153, 255, 255, 255)
                                      : const Color(0xFF333333),
                                ),
                                activeIcon: SFSymbolHelper.getBottomNavIcon(
                                  sfSymbolName: 'house',
                                  size: 20,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF000000),
                                ),
                                label: 'Start',
                              ),
                              BottomNavigationBarItem(
                                icon: SFSymbolHelper.getIcon(
                                  iconPath: 'assets/icons/headset.svg',
                                  width: 20,
                                  height: 20,
                                  color: isDark
                                      ? const Color.fromARGB(153, 255, 255, 255)
                                      : const Color(0xFF333333),
                                ),
                                activeIcon: SFSymbolHelper.getIcon(
                                  iconPath: 'assets/icons/headset.svg',
                                  width: 20,
                                  height: 20,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF000000),
                                ),
                                label: 'Support',
                              ),
                              BottomNavigationBarItem(
                                icon: SFSymbolHelper.getBottomNavIcon(
                                  sfSymbolName: 'person',
                                  size: 20,
                                  color: isDark
                                      ? const Color.fromARGB(153, 255, 255, 255)
                                      : const Color(0xFF333333),
                                ),
                                activeIcon: SFSymbolHelper.getBottomNavIcon(
                                  sfSymbolName: 'person',
                                  size: 20,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF000000),
                                ),
                                label: 'Profil',
                              ),
                            ],
                            currentIndex:
                                _bottomNavIndex < 3
                                    ? _bottomNavIndex
                                    : _mainTabIndex,
                            onTap: (index) {
                              setState(() {
                                if (index == 0 && _bottomNavIndex == 0) {
                                  selectedIndex = 0;
                                } else {
                                  _bottomNavIndex = index;
                                  if (index < 3) _mainTabIndex = index;
                                }
                              });
                            },
                            type: BottomNavigationBarType.fixed,
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
      ),
    );
  }
}
