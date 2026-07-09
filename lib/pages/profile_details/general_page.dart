import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/app_settings_service.dart';
import '../../services/sf_symbol_helper.dart';
import '../../services/ui_scale.dart';
import '../../widgets/adaptive_bottom_sheet.dart';
import 'profile_detail_page_utils.dart';

class GeneralPage extends StatefulWidget {
  const GeneralPage({super.key, this.isDarkOverride, this.prewarm = false});

  final bool? isDarkOverride;
  final bool prewarm;

  @override
  State<GeneralPage> createState() => _GeneralPageState();
}

class _GeneralPageState extends State<GeneralPage>
    with ProfileDetailPerformanceMixin<GeneralPage> {
  static const Duration _generalOverlayPreloadDelay = Duration(
    milliseconds: 250,
  );
  static const Set<String> _generalOverlayWarmupIconPaths = <String>{
    'assets/icons/xmark.circle.fill.svg',
    'assets/icons/eye.circle.fill.svg',
  };

  bool _isDisplayNameAdded = false;
  bool _isSkillsAdded = false;
  String _displayName = '';
  String _skills = '';
  bool _scheduledOverlayWarmup = false;
  final Set<_GeneralOverlayType> _mountedPersistentOverlayHosts =
      <_GeneralOverlayType>{};
  Timer? _generalOverlayPreloadTimer;
  _GeneralOverlayType? _activeOverlayType;
  String? _displayNameValidationErrorText;
  String? _skillsValidationErrorText;
  Stopwatch? _displayNameOverlayStopwatch;
  Stopwatch? _skillsOverlayStopwatch;
  late final TextEditingController _displayNameController;
  late final TextEditingController _skillsController;

  @override
  String get profileDetailPerformanceLabel => 'GeneralPage';

  @override
  bool get isProfileDetailWarmup => widget.prewarm;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: _displayName);
    _skillsController = TextEditingController(text: _skills);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || isProfileDetailWarmup) {
        return;
      }
      _generalOverlayPreloadTimer = Timer(
        _generalOverlayPreloadDelay,
        _preloadGeneralOverlays,
      );
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
        SFSymbolHelper.precacheIcons(context, _generalOverlayWarmupIconPaths),
      );
    });
  }

  @override
  void dispose() {
    _generalOverlayPreloadTimer?.cancel();
    _displayNameController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  void _preloadGeneralOverlays() {
    _generalOverlayPreloadTimer = null;
    if (!mounted || isProfileDetailWarmup) {
      return;
    }

    final bool hasDisplayNameHost = _mountedPersistentOverlayHosts.contains(
      _GeneralOverlayType.displayName,
    );
    final bool hasSkillsHost = _mountedPersistentOverlayHosts.contains(
      _GeneralOverlayType.skills,
    );
    if (hasDisplayNameHost && hasSkillsHost) {
      return;
    }

    setState(() {
      _mountedPersistentOverlayHosts.addAll(const <_GeneralOverlayType>[
        _GeneralOverlayType.displayName,
        _GeneralOverlayType.skills,
      ]);
    });
  }

  void _ensurePersistentOverlayHostMounted(_GeneralOverlayType overlayType) {
    if (_mountedPersistentOverlayHosts.contains(overlayType)) {
      return;
    }

    _mountedPersistentOverlayHosts.add(overlayType);
  }

  bool _isPersistentOverlayHostMounted(_GeneralOverlayType overlayType) {
    return _mountedPersistentOverlayHosts.contains(overlayType);
  }

  bool get _hasMountedPersistentOverlayHosts =>
      _mountedPersistentOverlayHosts.isNotEmpty;

  void _showGeneralOverlay(_GeneralOverlayType overlayType) {
    final _GeneralOverlayConfig config = _configForOverlayType(overlayType);
    final TextEditingController controller = _controllerForOverlayType(
      overlayType,
    );

    _ensurePersistentOverlayHostMounted(overlayType);
    controller.value = TextEditingValue(
      text: config.initialFieldValue ?? '',
      selection: TextSelection.collapsed(
        offset: (config.initialFieldValue ?? '').length,
      ),
    );

    setState(() {
      _setValidationErrorForOverlayType(overlayType, null);
      _setOverlayStopwatchForType(overlayType, Stopwatch()..start());
      _activeOverlayType = overlayType;
    });
  }

  void _handleDisplayNameAction() {
    _showGeneralOverlay(_GeneralOverlayType.displayName);
  }

  void _handleSkillsAction() {
    if (!_isSkillsAdded) {
      setState(() {
        _isSkillsAdded = true;
      });
    }
    _showGeneralOverlay(_GeneralOverlayType.skills);
  }

  void _dismissGeneralOverlay() {
    if (_activeOverlayType == null) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _setValidationErrorForOverlayType(_activeOverlayType!, null);
      _setOverlayStopwatchForType(_activeOverlayType!, null);
      _activeOverlayType = null;
    });
  }

  _GeneralOverlayConfig _configForOverlayType(_GeneralOverlayType overlayType) {
    switch (overlayType) {
      case _GeneralOverlayType.displayName:
        return _displayNameOverlayConfig();
      case _GeneralOverlayType.skills:
        return _skillsOverlayConfig();
    }
  }

  TextEditingController _controllerForOverlayType(
    _GeneralOverlayType overlayType,
  ) {
    switch (overlayType) {
      case _GeneralOverlayType.displayName:
        return _displayNameController;
      case _GeneralOverlayType.skills:
        return _skillsController;
    }
  }

  String? _validationErrorForOverlayType(_GeneralOverlayType overlayType) {
    switch (overlayType) {
      case _GeneralOverlayType.displayName:
        return _displayNameValidationErrorText;
      case _GeneralOverlayType.skills:
        return _skillsValidationErrorText;
    }
  }

  void _setValidationErrorForOverlayType(
    _GeneralOverlayType overlayType,
    String? validationErrorText,
  ) {
    switch (overlayType) {
      case _GeneralOverlayType.displayName:
        _displayNameValidationErrorText = validationErrorText;
      case _GeneralOverlayType.skills:
        _skillsValidationErrorText = validationErrorText;
    }
  }

  Stopwatch? _overlayStopwatchForType(_GeneralOverlayType overlayType) {
    switch (overlayType) {
      case _GeneralOverlayType.displayName:
        return _displayNameOverlayStopwatch;
      case _GeneralOverlayType.skills:
        return _skillsOverlayStopwatch;
    }
  }

  void _setOverlayStopwatchForType(
    _GeneralOverlayType overlayType,
    Stopwatch? stopwatch,
  ) {
    switch (overlayType) {
      case _GeneralOverlayType.displayName:
        _displayNameOverlayStopwatch = stopwatch;
      case _GeneralOverlayType.skills:
        _skillsOverlayStopwatch = stopwatch;
    }
  }

  bool _isAddButtonActiveForOverlayType(_GeneralOverlayType overlayType) {
    final _GeneralOverlayConfig config = _configForOverlayType(overlayType);
    final String currentValue = _controllerForOverlayType(overlayType).text;
    return config.validator?.call(currentValue.trim()) == null;
  }

  void _handleOverlayDraftChanged(
    _GeneralOverlayType overlayType,
    String value,
  ) {
    if (_validationErrorForOverlayType(overlayType) == null) {
      setState(() {});
      return;
    }

    setState(() {
      _setValidationErrorForOverlayType(overlayType, null);
    });
  }

  void _handleOverlaySave(
    _GeneralOverlayType overlayType, {
    required bool closeAfterSave,
  }) {
    final _GeneralOverlayConfig config = _configForOverlayType(overlayType);
    final TextEditingController controller = _controllerForOverlayType(
      overlayType,
    );
    final String nextValue = controller.text.trim();
    final String? validationError = config.validator?.call(nextValue);

    if (validationError != null) {
      setState(() {
        _setValidationErrorForOverlayType(overlayType, validationError);
      });
      return;
    }

    final String resolvedValue = nextValue.isEmpty
        ? (config.initialFieldValue ?? '')
        : nextValue;

    config.onSave?.call(resolvedValue);
    controller.value = TextEditingValue(
      text: resolvedValue,
      selection: TextSelection.collapsed(offset: resolvedValue.length),
    );

    setState(() {
      _setValidationErrorForOverlayType(overlayType, null);
    });

    if (closeAfterSave) {
      _dismissGeneralOverlay();
    }
  }

  _GeneralOverlayConfig _displayNameOverlayConfig() {
    return _GeneralOverlayConfig(
      performanceLabel: 'display_name',
      title: 'Anzeigename hinzufügen',
      preferredHeight: 324,
      subtitle: 'Dieser Name ist öffentlich sichtbar',
      showAddButton: false,
      fieldTopSpacingFromSubtitle: 0,
      fieldLabelText: 'Anzeigename eingeben',
      initialFieldValue: _displayName,
      fieldHintText: 'Gerafftes',
      fieldHintColor: HSLColor.fromAHSL(0.70, 0, 0, 0.45).toColor(),
      validator: (value) {
        if (value.length < 4) {
          return 'Anzeigename muss mindestens 4 Zeichen haben';
        }
        return null;
      },
      onSave: (value) {
        setState(() {
          _displayName = value;
          _isDisplayNameAdded = true;
        });
      },
    );
  }

  _GeneralOverlayConfig _skillsOverlayConfig() {
    return _GeneralOverlayConfig(
      performanceLabel: 'skills',
      title: 'Skills',
      preferredHeight: 445,
      subtitle: 'Skills werden in deinem Profil angezeigt',
      subtitleSingleLine: true,
      fieldTopSpacingFromSubtitle: 18,
      centeredContentBuilder: (_) => const _SkillChipRow(),
      fieldLabelText: 'Skills hinzufügen',
      initialFieldValue: _skills,
      fieldHintText: 'Nachhilfe',
      fieldHintColor: HSLColor.fromAHSL(0.70, 0, 0, 0.45).toColor(),
      validator: (value) {
        if (value.length < 4) {
          return 'Skills müssen mindestens 4 Zeichen lang sein';
        }
        return null;
      },
      onSave: (value) {
        setState(() {
          _skills = value;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);
    double s(double value) => ui.s(value);
    final bool isDark =
        widget.isDarkOverride ??
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final Color bgColor = isDark
        ? const Color(0xFF020202)
        : const Color(0xFFE6E6E6);
    final Color cardColor = isDark
        ? const Color(0xFF0D0D0D)
        : const Color(0xFFF2F2F2);
    final Color textColor = isDark
        ? const Color(0xFFF2F2F2)
        : const Color(0xFF0D0D0D);
    final Color secondaryTextColor = isDark
        ? const Color(0xFFB3B3B3)
        : const Color(0xFF4D4D4D);
    final Color dividerColor = isDark
        ? const Color(0xFF1B1B1B)
        : const Color(0xFFE2E2E2);
    final Color buttonColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final Color buttonTextColor = isDark
        ? const Color(0xFFF2F2F2)
        : const Color(0xFF0D0D0D);
    final Color addButtonColor = HSLColor.fromAHSL(
      0.30,
      211,
      1.0,
      0.50,
    ).toColor();
    const Color addButtonTextColor = Color(0xFF4DAAFC);
    final Color destructiveButtonColor = HSLColor.fromAHSL(
      0.30,
      359,
      1.0,
      0.63,
    ).toColor();
    final Color destructiveButtonStrokeColor = HSLColor.fromAHSL(
      1.0,
      359,
      1.0,
      0.63,
    ).toColor();
    final Color destructiveButtonTextColor = destructiveButtonStrokeColor;
    final double generalActionButtonWidth = s(121);
    final double generalActionButtonHeight = s(44);
    final _GeneralOverlayConfig displayNameConfig = _displayNameOverlayConfig();
    final _GeneralOverlayConfig skillsConfig = _skillsOverlayConfig();

    return PopScope(
      canPop: _activeOverlayType == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _activeOverlayType != null) {
          _dismissGeneralOverlay();
        }
      },
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
            iconSize: ui.s(20),
          ),
          iconTheme: IconThemeData(color: textColor, size: ui.s(20)),
          title: Text(
            'Allgemein',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: ui.s(20),
            ),
          ),
        ),
        body: Stack(
          children: [
            SafeArea(
              top: false,
              left: true,
              right: true,
              bottom: false,
              child: isInitialContentReady
                  ? StretchingOverscrollIndicator(
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
                              s(20),
                            ),
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
                                        'Profil',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: s(20),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: s(14)),
                                    _GeneralInfoGroup(
                                      backgroundColor: cardColor,
                                      borderRadius: s(15),
                                      children: [
                                        _GeneralInfoCard(
                                          title: 'Anzeigename',
                                          supportingText: _displayName.isEmpty
                                              ? 'Anzeigename eingeben'
                                              : _displayName,
                                          footerLabel: 'Öffentlich sichtbar',
                                          showFooterIcon: true,
                                          backgroundColor: cardColor,
                                          titleColor: textColor,
                                          supportingTextColor:
                                              secondaryTextColor,
                                          footerLabelColor: textColor,
                                          actionBackgroundColor: buttonColor,
                                          actionTextColor: buttonTextColor,
                                          actionLabel: _isDisplayNameAdded
                                              ? 'Bearbeiten'
                                              : 'Hinzufügen',
                                          onActionTap: _handleDisplayNameAction,
                                          addActionBackgroundColor:
                                              addButtonColor,
                                          addActionTextColor:
                                              addButtonTextColor,
                                          actionButtonWidth:
                                              generalActionButtonWidth,
                                          actionButtonHeight:
                                              generalActionButtonHeight,
                                          embedInGroup: true,
                                          showDivider: true,
                                          dividerColor: dividerColor,
                                        ),
                                        _GeneralInfoCard(
                                          title: 'Skills',
                                          supportingText: _skills.isEmpty
                                              ? 'Skills hinzufügen'
                                              : _skills,
                                          footerLabel: 'Öffentlich sichtbar',
                                          showFooterIcon: true,
                                          backgroundColor: cardColor,
                                          titleColor: textColor,
                                          supportingTextColor:
                                              secondaryTextColor,
                                          footerLabelColor: textColor,
                                          actionBackgroundColor: buttonColor,
                                          actionTextColor: buttonTextColor,
                                          actionLabel: _isSkillsAdded
                                              ? 'Bearbeiten'
                                              : 'Hinzufügen',
                                          onActionTap: _handleSkillsAction,
                                          addActionBackgroundColor:
                                              addButtonColor,
                                          addActionTextColor:
                                              addButtonTextColor,
                                          actionButtonWidth:
                                              generalActionButtonWidth,
                                          actionButtonHeight:
                                              generalActionButtonHeight,
                                          embedInGroup: true,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: s(21)),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'App',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: s(20),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: s(14)),
                                    RepaintBoundary(
                                      child: _AppSettingsGroup(
                                        backgroundColor: cardColor,
                                        textColor: textColor,
                                        dividerColor: dividerColor,
                                      ),
                                    ),
                                    SizedBox(height: s(21)),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Account',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: s(20),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: s(14)),
                                    _GeneralInfoGroup(
                                      backgroundColor: cardColor,
                                      borderRadius: s(15),
                                      children: [
                                        _GeneralInfoCard(
                                          title: 'Abmelden',
                                          supportingText:
                                              'Melde dich auf diesem Gerät\nvon deinem Konto ab.',
                                          supportingTextMaxLines: 2,
                                          backgroundColor: cardColor,
                                          titleColor: textColor,
                                          supportingTextColor:
                                              secondaryTextColor,
                                          footerLabelColor: textColor,
                                          actionBackgroundColor:
                                              destructiveButtonColor,
                                          actionTextColor:
                                              destructiveButtonTextColor,
                                          actionBorderColor:
                                              destructiveButtonStrokeColor,
                                          actionLabel: 'Abmelden',
                                          actionButtonWidth:
                                              generalActionButtonWidth,
                                          actionButtonHeight:
                                              generalActionButtonHeight,
                                          embedInGroup: true,
                                          showDivider: true,
                                          dividerColor: dividerColor,
                                        ),
                                        _GeneralInfoCard(
                                          title: 'Löschen',
                                          supportingText:
                                              'Dein Konto und deine Daten\nwerden dauerhaft entfernt.',
                                          supportingTextMaxLines: 2,
                                          backgroundColor: cardColor,
                                          titleColor: textColor,
                                          supportingTextColor:
                                              secondaryTextColor,
                                          footerLabelColor: textColor,
                                          actionBackgroundColor:
                                              destructiveButtonColor,
                                          actionTextColor:
                                              destructiveButtonTextColor,
                                          actionBorderColor:
                                              destructiveButtonStrokeColor,
                                          actionLabel: 'Löschen',
                                          actionButtonWidth:
                                              generalActionButtonWidth,
                                          actionButtonHeight:
                                              generalActionButtonHeight,
                                          embedInGroup: true,
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
                    )
                  : _GeneralPageSkeleton(s: s, isDark: isDark),
            ),
            if (_hasMountedPersistentOverlayHosts)
              Positioned.fill(
                child: _GeneralPersistentOverlayHost(
                  isDark: isDark,
                  activeOverlayType: _activeOverlayType,
                  showDisplayNameHost: _isPersistentOverlayHostMounted(
                    _GeneralOverlayType.displayName,
                  ),
                  showSkillsHost: _isPersistentOverlayHostMounted(
                    _GeneralOverlayType.skills,
                  ),
                  displayNameConfig: displayNameConfig,
                  skillsConfig: skillsConfig,
                  displayNameController: _displayNameController,
                  skillsController: _skillsController,
                  displayNameValidationErrorText:
                      _displayNameValidationErrorText,
                  skillsValidationErrorText: _skillsValidationErrorText,
                  displayNameIsAddButtonActive:
                      _isAddButtonActiveForOverlayType(
                        _GeneralOverlayType.displayName,
                      ),
                  skillsIsAddButtonActive: _isAddButtonActiveForOverlayType(
                    _GeneralOverlayType.skills,
                  ),
                  displayNamePerformanceStopwatch: _overlayStopwatchForType(
                    _GeneralOverlayType.displayName,
                  ),
                  skillsPerformanceStopwatch: _overlayStopwatchForType(
                    _GeneralOverlayType.skills,
                  ),
                  onDismiss: _dismissGeneralOverlay,
                  onDisplayNameDraftChanged: (value) {
                    _handleOverlayDraftChanged(
                      _GeneralOverlayType.displayName,
                      value,
                    );
                  },
                  onSkillsDraftChanged: (value) {
                    _handleOverlayDraftChanged(
                      _GeneralOverlayType.skills,
                      value,
                    );
                  },
                  onDisplayNameSave: ({required bool closeAfterSave}) {
                    _handleOverlaySave(
                      _GeneralOverlayType.displayName,
                      closeAfterSave: closeAfterSave,
                    );
                  },
                  onSkillsSave: ({required bool closeAfterSave}) {
                    _handleOverlaySave(
                      _GeneralOverlayType.skills,
                      closeAfterSave: closeAfterSave,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GeneralPageSkeleton extends StatelessWidget {
  const _GeneralPageSkeleton({required this.s, required this.isDark});

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
            width: s(92),
            height: s(22),
            borderRadius: s(11),
          ),
          SizedBox(height: s(14)),
          ProfileDetailSkeletonBlock(
            isDark: isDark,
            height: s(224),
            borderRadius: s(15),
          ),
          SizedBox(height: s(21)),
          ProfileDetailSkeletonBlock(
            isDark: isDark,
            width: s(70),
            height: s(22),
            borderRadius: s(11),
          ),
          SizedBox(height: s(14)),
          ProfileDetailSkeletonBlock(
            isDark: isDark,
            height: s(176),
            borderRadius: s(15),
          ),
          SizedBox(height: s(21)),
          ProfileDetailSkeletonBlock(
            isDark: isDark,
            width: s(104),
            height: s(22),
            borderRadius: s(11),
          ),
          SizedBox(height: s(14)),
          ProfileDetailSkeletonBlock(
            isDark: isDark,
            height: s(224),
            borderRadius: s(15),
          ),
        ],
      ),
    );
  }
}

enum _GeneralOverlayType { displayName, skills }

class _GeneralPersistentOverlayHost extends StatelessWidget {
  const _GeneralPersistentOverlayHost({
    required this.isDark,
    required this.activeOverlayType,
    required this.showDisplayNameHost,
    required this.showSkillsHost,
    required this.displayNameConfig,
    required this.skillsConfig,
    required this.displayNameController,
    required this.skillsController,
    required this.displayNameValidationErrorText,
    required this.skillsValidationErrorText,
    required this.displayNameIsAddButtonActive,
    required this.skillsIsAddButtonActive,
    required this.displayNamePerformanceStopwatch,
    required this.skillsPerformanceStopwatch,
    required this.onDismiss,
    required this.onDisplayNameDraftChanged,
    required this.onSkillsDraftChanged,
    required this.onDisplayNameSave,
    required this.onSkillsSave,
  });

  final bool isDark;
  final _GeneralOverlayType? activeOverlayType;
  final bool showDisplayNameHost;
  final bool showSkillsHost;
  final _GeneralOverlayConfig displayNameConfig;
  final _GeneralOverlayConfig skillsConfig;
  final TextEditingController displayNameController;
  final TextEditingController skillsController;
  final String? displayNameValidationErrorText;
  final String? skillsValidationErrorText;
  final bool displayNameIsAddButtonActive;
  final bool skillsIsAddButtonActive;
  final Stopwatch? displayNamePerformanceStopwatch;
  final Stopwatch? skillsPerformanceStopwatch;
  final VoidCallback onDismiss;
  final ValueChanged<String> onDisplayNameDraftChanged;
  final ValueChanged<String> onSkillsDraftChanged;
  final void Function({required bool closeAfterSave}) onDisplayNameSave;
  final void Function({required bool closeAfterSave}) onSkillsSave;

  @override
  Widget build(BuildContext context) {
    final bool isVisible = activeOverlayType != null;

    return IgnorePointer(
      ignoring: !isVisible,
      child: Stack(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            opacity: isVisible ? 1 : 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDismiss,
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.32),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          if (showDisplayNameHost)
            _GeneralAnimatedOverlaySheet(
              isVisible: activeOverlayType == _GeneralOverlayType.displayName,
              child: _GeneralOverlaySheet(
                config: displayNameConfig,
                isDark: isDark,
                performanceStopwatch: displayNamePerformanceStopwatch,
                textController: displayNameController,
                validationErrorText: displayNameValidationErrorText,
                isAddButtonActive: displayNameIsAddButtonActive,
                onDraftChanged: onDisplayNameDraftChanged,
                onSave: onDisplayNameSave,
              ),
            ),
          if (showSkillsHost)
            _GeneralAnimatedOverlaySheet(
              isVisible: activeOverlayType == _GeneralOverlayType.skills,
              child: _GeneralOverlaySheet(
                config: skillsConfig,
                isDark: isDark,
                performanceStopwatch: skillsPerformanceStopwatch,
                textController: skillsController,
                validationErrorText: skillsValidationErrorText,
                isAddButtonActive: skillsIsAddButtonActive,
                onDraftChanged: onSkillsDraftChanged,
                onSave: onSkillsSave,
              ),
            ),
        ],
      ),
    );
  }
}

class _GeneralAnimatedOverlaySheet extends StatelessWidget {
  const _GeneralAnimatedOverlaySheet({
    required this.isVisible,
    required this.child,
  });

  final bool isVisible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: IgnorePointer(
        ignoring: !isVisible,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          offset: isVisible ? Offset.zero : const Offset(0, 1.08),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            opacity: isVisible ? 1 : 0,
            child: RepaintBoundary(child: child),
          ),
        ),
      ),
    );
  }
}

class _GeneralOverlayConfig {
  const _GeneralOverlayConfig({
    required this.performanceLabel,
    required this.title,
    required this.preferredHeight,
    this.subtitle,
    this.subtitleSingleLine = false,
    this.showAddButton = true,
    this.fieldTopSpacingFromSubtitle,
    this.centeredContentBuilder,
    this.fieldLabelText,
    this.initialFieldValue,
    this.fieldHintText,
    this.fieldHintColor,
    this.onSave,
    this.validator,
  });

  final String performanceLabel;
  final String title;
  final double preferredHeight;
  final String? subtitle;
  final bool subtitleSingleLine;
  final bool showAddButton;
  final double? fieldTopSpacingFromSubtitle;
  final WidgetBuilder? centeredContentBuilder;
  final String? fieldLabelText;
  final String? initialFieldValue;
  final String? fieldHintText;
  final Color? fieldHintColor;
  final ValueChanged<String>? onSave;
  final String? Function(String value)? validator;
}

class _GeneralOverlaySheet extends StatefulWidget {
  const _GeneralOverlaySheet({
    required this.config,
    required this.isDark,
    this.performanceStopwatch,
    required this.textController,
    required this.validationErrorText,
    required this.isAddButtonActive,
    required this.onDraftChanged,
    required this.onSave,
  });

  final _GeneralOverlayConfig config;
  final bool isDark;
  final Stopwatch? performanceStopwatch;
  final TextEditingController textController;
  final String? validationErrorText;
  final bool isAddButtonActive;
  final ValueChanged<String> onDraftChanged;
  final void Function({required bool closeAfterSave}) onSave;

  @override
  State<_GeneralOverlaySheet> createState() => _GeneralOverlaySheetState();
}

class _GeneralOverlaySheetState extends State<_GeneralOverlaySheet> {
  bool _didLogFirstFrame = false;
  late bool _isFieldEditorReady;

  @override
  void initState() {
    super.initState();
    _isFieldEditorReady = widget.config.initialFieldValue == null;
    if (widget.performanceStopwatch != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _logFirstFrame();
        _scheduleFieldEditorMount();
      });
    } else {
      _scheduleFieldEditorMount();
    }
  }

  @override
  void didUpdateWidget(covariant _GeneralOverlaySheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(
      oldWidget.performanceStopwatch,
      widget.performanceStopwatch,
    )) {
      return;
    }

    _didLogFirstFrame = false;
    if (widget.performanceStopwatch == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _logFirstFrame();
      _scheduleFieldEditorMount();
    });
  }

  void _scheduleFieldEditorMount() {
    if (_isFieldEditorReady || widget.config.initialFieldValue == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isFieldEditorReady) {
        return;
      }
      setState(() {
        _isFieldEditorReady = true;
      });
    });
  }

  void _logFirstFrame() {
    if (_didLogFirstFrame || widget.performanceStopwatch == null) {
      return;
    }
    _didLogFirstFrame = true;
    widget.performanceStopwatch!.stop();
    debugPrint(
      '[GeneralOverlay:${widget.config.performanceLabel}] first frame: '
      '${widget.performanceStopwatch!.elapsedMilliseconds} ms',
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);
    double s(double value) => ui.s(value);
    final double overlayLeftInset = MediaQuery.of(context).padding.left + s(16);
    final double overlayRightInset =
        MediaQuery.of(context).padding.right + s(16);
    final double overlaySafeBottom = MediaQuery.of(context).viewPadding.bottom;
    final BorderRadius fieldBorderRadius = BorderRadius.circular(s(15));
    final Widget? centeredContent = widget.config.centeredContentBuilder?.call(
      context,
    );
    final Widget fieldEditor = widget.config.initialFieldValue == null
        ? const SizedBox.shrink()
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.config.fieldLabelText != null) ...[
                Text(
                  widget.config.fieldLabelText!,
                  style: TextStyle(
                    color: const Color(0xFF747474),
                    fontSize: s(18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: s(5)),
              ],
              SizedBox(
                height: s(60),
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: fieldBorderRadius,
                  child: _isFieldEditorReady
                      ? TextFormField(
                          controller: widget.textController,
                          onTapOutside: (_) {
                            FocusScope.of(context).unfocus();
                          },
                          onChanged: widget.onDraftChanged,
                          onFieldSubmitted: (_) =>
                              widget.onSave(closeAfterSave: true),
                          keyboardAppearance: Brightness.dark,
                          textInputAction: TextInputAction.done,
                          cursorColor: const Color(0xFF4DAAFC),
                          style: TextStyle(
                            color: const Color(0xFFF2F2F2),
                            fontSize: s(18),
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF050505),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: s(18),
                              vertical: s(18),
                            ),
                            hintText: widget.config.fieldHintText,
                            hintStyle: TextStyle(
                              color:
                                  widget.config.fieldHintColor ??
                                  const Color(0xFF747474),
                              fontSize: s(18),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFF050505),
                            borderRadius: fieldBorderRadius,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: s(18)),
                              child: Text(
                                widget.textController.text.isEmpty
                                    ? widget.config.fieldHintText ?? ''
                                    : widget.textController.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: widget.textController.text.isEmpty
                                      ? widget.config.fieldHintColor ??
                                            const Color(0xFF747474)
                                      : const Color(0xFFF2F2F2),
                                  fontSize: s(18),
                                  fontWeight: widget.textController.text.isEmpty
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          );

    final double validationMessageHeight =
        widget.config.fieldTopSpacingFromSubtitle == null ? 0 : s(20);

    return AdaptiveBottomSheet(
      isDark: widget.isDark,
      preferredHeight: s(widget.config.preferredHeight),
      child: Padding(
        padding: EdgeInsets.only(top: s(23)),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: overlayLeftInset,
                right: overlayRightInset,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.config.title,
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.isDark
                              ? const Color(0xFFF2F2F2)
                              : const Color(0xFF0D0D0D),
                          fontSize: s(30),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (widget.config.subtitle != null) ...[
                    SizedBox(height: s(0)),
                    if (widget.config.subtitleSingleLine)
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.config.subtitle!,
                            maxLines: 1,
                            softWrap: false,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFFB3B3B3),
                              fontSize: s(20),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    else
                      Text(
                        widget.config.subtitle!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFFB3B3B3),
                          fontSize: s(20),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: overlayLeftInset,
                  right: overlayRightInset,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double centeredContentReservedHeight =
                        centeredContent == null ? 0 : s(39);

                    return SizedBox(
                      width: double.infinity,
                      height: constraints.maxHeight,
                      child: Stack(
                        children: [
                          if (widget.config.fieldTopSpacingFromSubtitle != null)
                            Positioned(
                              top: s(6),
                              left: 0,
                              right: 0,
                              child: SizedBox(
                                height: validationMessageHeight,
                                child: widget.validationErrorText == null
                                    ? const SizedBox.shrink()
                                    : Text(
                                        widget.validationErrorText!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: const Color(0xFFD6543D),
                                          fontSize: s(13),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          Padding(
                            padding: EdgeInsets.only(
                              top: validationMessageHeight,
                              bottom: centeredContentReservedHeight,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.config.fieldTopSpacingFromSubtitle !=
                                    null)
                                  SizedBox(
                                    height: s(
                                      widget
                                          .config
                                          .fieldTopSpacingFromSubtitle!,
                                    ),
                                  ),
                                fieldEditor,
                              ],
                            ),
                          ),
                          if (centeredContent != null)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: centeredContent,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            if (widget.config.initialFieldValue != null)
              SizedBox(height: s(17)),
            if (widget.config.showAddButton) ...[
              Padding(
                padding: EdgeInsets.only(
                  left: overlayLeftInset,
                  right: overlayRightInset,
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onSave(closeAfterSave: false),
                  child: Container(
                    height: s(60),
                    decoration: BoxDecoration(
                      color: widget.isAddButtonActive
                          ? const Color(0xFF007AFF)
                          : HSLColor.fromAHSL(0.30, 211, 1.0, 0.50).toColor(),
                      borderRadius: BorderRadius.circular(s(15)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Hinzufügen',
                      style: TextStyle(
                        color: widget.isAddButtonActive
                            ? const Color(0xFFF2F2F2)
                            : HSLColor.fromAHSL(0.70, 0, 0, 0.95).toColor(),
                        fontSize: s(18),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: s(10)),
            ],
            Padding(
              padding: EdgeInsets.only(
                left: overlayLeftInset,
                right: overlayRightInset,
                bottom: overlaySafeBottom,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onSave(closeAfterSave: true),
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
  }
}

class _SkillChipRow extends StatefulWidget {
  const _SkillChipRow();

  @override
  State<_SkillChipRow> createState() => _SkillChipRowState();
}

class _SkillChipRowState extends State<_SkillChipRow> {
  static const Duration _chipSlideDuration = Duration(milliseconds: 220);

  final List<_SkillChipItem> _chips = <_SkillChipItem>[
    _SkillChipItem(id: 1, label: 'Garten...'),
    _SkillChipItem(id: 2, label: 'Umzugs...'),
    _SkillChipItem(id: 3, label: 'WLAN ein...'),
  ];

  Future<void> _removeChip(_SkillChipItem chip) async {
    if (chip.isRemoving) {
      return;
    }

    setState(() {
      chip.isRemoving = true;
    });

    await Future<void>.delayed(_chipSlideDuration);
    if (!mounted) {
      return;
    }

    setState(() {
      _chips.removeWhere((item) => item.id == chip.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(_chips.length, (index) {
        final _SkillChipItem chip = _chips[index];

        return AnimatedSize(
          key: ValueKey<int>(chip.id),
          duration: _chipSlideDuration,
          curve: Curves.easeInOut,
          alignment: Alignment.centerLeft,
          child: chip.isRemoving
              ? const SizedBox.shrink()
              : Padding(
                  padding: EdgeInsets.only(
                    right: index == _chips.length - 1 ? 0 : ui.s(8),
                  ),
                  child: _SkillChip(
                    label: chip.label,
                    onRemove: () => _removeChip(chip),
                  ),
                ),
        );
      }),
    );
  }
}

class _SkillChipItem {
  _SkillChipItem({required this.id, required this.label});

  final int id;
  final String label;
  bool isRemoving = false;
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label, this.onRemove});

  final String label;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);
    final double chipHeight = ui.s(22);
    final double iconSize = ui.s(12);
    final double iconTapTarget = ui.s(44);
    final double rightPadding = ui.s(5);
    final double iconTapRightInset =
        rightPadding + (iconSize / 2) - (iconTapTarget / 2);

    return SizedBox(
      height: chipHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: chipHeight,
            padding: EdgeInsets.fromLTRB(
              ui.s(10),
              ui.s(5),
              rightPadding,
              ui.s(5),
            ),
            decoration: BoxDecoration(
              color: HSLColor.fromAHSL(0.30, 211, 1.0, 0.50).toColor(),
              borderRadius: BorderRadius.circular(ui.s(100)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  label,
                  strutStyle: StrutStyle(
                    fontSize: ui.s(12),
                    height: 1,
                    forceStrutHeight: true,
                  ),
                  style: TextStyle(
                    color: const Color(0xFF4DAAFC),
                    fontSize: ui.s(12),
                    fontWeight: FontWeight.w400,
                    height: 1,
                  ),
                ),
                SizedBox(width: ui.s(5)),
                SFSymbolHelper.getIcon(
                  iconPath: 'assets/icons/xmark.circle.fill.svg',
                  width: iconSize,
                  height: iconSize,
                  color: HSLColor.fromAHSL(0.70, 0, 0, 0.95).toColor(),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: -(iconTapTarget - chipHeight) / 2,
              right: iconTapRightInset,
              child: SizedBox(
                width: iconTapTarget,
                height: iconTapTarget,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onRemove,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AppSettingsGroup extends StatelessWidget {
  const _AppSettingsGroup({
    required this.backgroundColor,
    required this.textColor,
    required this.dividerColor,
  });

  final Color backgroundColor;
  final Color textColor;
  final Color dividerColor;

  static const List<({String label, String value})> _entries = [
    (label: 'Sprache', value: 'Deutsch'),
    (label: 'Design', value: 'System'),
    (label: 'Standort', value: 'Verwalten'),
  ];

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);

    return ClipRRect(
      borderRadius: BorderRadius.circular(ui.s(15)),
      child: DecoratedBox(
        decoration: BoxDecoration(color: backgroundColor),
        child: Column(
          children: [
            for (final entry in _entries) ...[
              _AppSettingsRow(
                label: entry.label,
                value: entry.value,
                textColor: textColor,
                onTap: entry.label == 'Standort' || entry.label == 'Sprache'
                    ? () {
                        AppSettingsService.openAppSettings();
                      }
                    : null,
              ),
              if (entry != _entries.last)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: ui.s(16)),
                  height: 1,
                  color: dividerColor,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AppSettingsRow extends StatelessWidget {
  const _AppSettingsRow({
    required this.label,
    required this.value,
    required this.textColor,
    this.onTap,
  });

  final String label;
  final String value;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);
    final TextStyle valueTextStyle = TextStyle(
      color: const Color(0xFFB3B3B3),
      fontSize: ui.s(17),
      fontWeight: FontWeight.w500,
    );
    final Widget trailingContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: valueTextStyle),
        SizedBox(width: ui.s(11)),
        SFSymbolHelper.getChevronRight(
          color: const Color(0xFFF2F2F2),
          size: ui.s(26),
        ),
      ],
    );

    return SizedBox(
      height: ui.s(55),
      child: Padding(
        padding: EdgeInsets.only(left: ui.s(16), right: ui.s(18)),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: ui.s(17),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (onTap == null)
              trailingContent
            else
              _AppSettingsTrailingAction(
                label: value,
                onTap: onTap!,
                textStyle: valueTextStyle,
              ),
          ],
        ),
      ),
    );
  }
}

class _AppSettingsTrailingAction extends StatefulWidget {
  const _AppSettingsTrailingAction({
    required this.label,
    required this.onTap,
    required this.textStyle,
  });

  final String label;
  final VoidCallback onTap;
  final TextStyle textStyle;

  @override
  State<_AppSettingsTrailingAction> createState() =>
      _AppSettingsTrailingActionState();
}

class _AppSettingsTrailingActionState
    extends State<_AppSettingsTrailingAction> {
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

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: ui.s(8)),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: _isPressed ? 0.55 : 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label, style: widget.textStyle),
              SizedBox(width: ui.s(11)),
              SFSymbolHelper.getChevronRight(
                color: const Color(0xFFF2F2F2),
                size: ui.s(26),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GeneralInfoCard extends StatelessWidget {
  const _GeneralInfoCard({
    required this.title,
    required this.supportingText,
    required this.backgroundColor,
    required this.titleColor,
    required this.supportingTextColor,
    required this.footerLabelColor,
    required this.actionBackgroundColor,
    required this.actionTextColor,
    required this.actionLabel,
    required this.actionButtonWidth,
    required this.actionButtonHeight,
    this.onActionTap,
    this.addActionBackgroundColor,
    this.addActionTextColor,
    this.footerLabel,
    this.actionBorderColor,
    this.showFooterIcon = false,
    this.supportingTextMaxLines = 1,
    this.embedInGroup = false,
    this.showDivider = false,
    this.dividerColor,
  });

  final String title;
  final String supportingText;
  final String? footerLabel;
  final Color backgroundColor;
  final Color titleColor;
  final Color supportingTextColor;
  final Color footerLabelColor;
  final Color actionBackgroundColor;
  final Color actionTextColor;
  final Color? actionBorderColor;
  final String actionLabel;
  final double actionButtonWidth;
  final double actionButtonHeight;
  final VoidCallback? onActionTap;
  final Color? addActionBackgroundColor;
  final Color? addActionTextColor;
  final bool showFooterIcon;
  final int supportingTextMaxLines;
  final bool embedInGroup;
  final bool showDivider;
  final Color? dividerColor;

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);
    final TextStyle titleStyle = TextStyle(
      color: titleColor,
      fontWeight: FontWeight.bold,
      fontSize: ui.s(17),
    );
    final TextStyle supportingTextStyle = TextStyle(
      color: supportingTextColor,
      fontWeight: FontWeight.bold,
      fontSize: ui.s(13.5),
      height: 1.4,
    );
    final TextStyle footerLabelStyle = TextStyle(
      color: footerLabelColor,
      fontWeight: FontWeight.bold,
      fontSize: ui.s(16),
      height: 1.4,
    );
    final Widget content = Padding(
      padding: EdgeInsets.fromLTRB(ui.s(18), ui.s(15), ui.s(18), ui.s(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                  style: titleStyle,
                ),
                SizedBox(height: ui.s(10.5)),
                Text(
                  supportingText,
                  maxLines: supportingTextMaxLines,
                  overflow: TextOverflow.ellipsis,
                  strutStyle: StrutStyle(
                    fontSize: ui.s(13.5),
                    height: 1.4,
                    forceStrutHeight: true,
                  ),
                  style: supportingTextStyle,
                ),
                if (footerLabel != null)
                  Padding(
                    padding: EdgeInsets.only(top: ui.s(8)),
                    child: Row(
                      children: [
                        if (showFooterIcon) ...[
                          SFSymbolHelper.getIcon(
                            iconPath: 'assets/icons/eye.circle.fill.svg',
                            width: ui.s(17),
                            height: ui.s(17),
                            color: const Color(0xFF007AFF),
                          ),
                          SizedBox(width: ui.s(6)),
                        ],
                        Flexible(
                          child: Text(
                            footerLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: footerLabelStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: ui.s(12)),
          _GeneralActionButton(
            label: actionLabel,
            width: actionButtonWidth,
            height: actionButtonHeight,
            backgroundColor: actionLabel == 'Hinzufügen'
                ? (addActionBackgroundColor ?? actionBackgroundColor)
                : actionBackgroundColor,
            textColor: actionLabel == 'Hinzufügen'
                ? (addActionTextColor ?? actionTextColor)
                : actionTextColor,
            borderColor: actionBorderColor,
            onTap: onActionTap,
          ),
        ],
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
        color: backgroundColor,
        borderRadius: BorderRadius.circular(ui.s(15)),
      ),
      child: content,
    );
  }
}

class _GeneralInfoGroup extends StatelessWidget {
  const _GeneralInfoGroup({
    required this.backgroundColor,
    required this.borderRadius,
    required this.children,
  });

  final Color backgroundColor;
  final double borderRadius;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Column(children: children),
      ),
    );
  }
}

class _GeneralActionButton extends StatefulWidget {
  const _GeneralActionButton({
    required this.label,
    required this.width,
    required this.height,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    this.onTap,
  });

  final String label;
  final double width;
  final double height;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  State<_GeneralActionButton> createState() => _GeneralActionButtonState();
}

class _GeneralActionButtonState extends State<_GeneralActionButton> {
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
          onTap: widget.onTap ?? () {},
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 120),
            opacity: _isPressed ? 0.72 : 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: borderRadius,
                border: widget.borderColor != null
                    ? Border.all(color: widget.borderColor!, width: 1)
                    : null,
              ),
              child: Center(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: ui.s(14),
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
