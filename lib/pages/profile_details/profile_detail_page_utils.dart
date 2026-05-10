import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

const Duration kProfileDetailPushFadeDuration = Duration(milliseconds: 250);
const Duration kProfileDetailPushAnimationTolerance = Duration(
  milliseconds: 48,
);
const double kProfileDetailBackgroundParallaxFraction = 0.35;
const double _profileDetailBackGestureEdgeWidth = 34;
const double _profileDetailBackGestureMinFlingVelocity = 420;

final ValueNotifier<double> profileDetailBackgroundParallaxProgress =
    ValueNotifier<double>(0);

final Map<Object, double> _profileDetailRouteParallaxValues =
    <Object, double>{};
double? _pendingProfileDetailParallaxProgress;
bool _hasScheduledProfileDetailParallaxPublish = false;

Route<T> buildProfileDetailFadeRoute<T>({
  required Widget page,
  String? performanceLabel,
  Duration transitionDuration = kProfileDetailPushFadeDuration,
  Duration? reverseTransitionDuration,
}) {
  final String label = performanceLabel ?? page.runtimeType.toString();
  return _ProfileDetailSwipeBackRoute<T>(
    page: page,
    performanceLabel: label,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
  );
}

void _setProfileDetailRouteParallaxValue(Object owner, double value) {
  _profileDetailRouteParallaxValues[owner] = value.clamp(0.0, 1.0);
  _publishProfileDetailParallaxProgress();
}

void _removeProfileDetailRouteParallaxValue(Object owner) {
  _profileDetailRouteParallaxValues.remove(owner);
  _publishProfileDetailParallaxProgress();
}

void _publishProfileDetailParallaxProgress() {
  double progress = 0;
  for (final double value in _profileDetailRouteParallaxValues.values) {
    if (value > progress) {
      progress = value;
    }
  }

  _setProfileDetailParallaxProgress(progress);
}

void _setProfileDetailParallaxProgress(double progress) {
  if ((profileDetailBackgroundParallaxProgress.value - progress).abs() >
      0.001) {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      _pendingProfileDetailParallaxProgress = progress;
      if (_hasScheduledProfileDetailParallaxPublish) {
        return;
      }

      _hasScheduledProfileDetailParallaxPublish = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _hasScheduledProfileDetailParallaxPublish = false;
        final double? pendingProgress = _pendingProfileDetailParallaxProgress;
        _pendingProfileDetailParallaxProgress = null;
        if (pendingProgress == null) {
          return;
        }
        _setProfileDetailParallaxProgress(pendingProgress);
      });
      return;
    }

    profileDetailBackgroundParallaxProgress.value = progress;
  }
}

class _ProfileDetailSwipeBackRoute<T> extends PageRoute<T> {
  _ProfileDetailSwipeBackRoute({
    required this.page,
    required this.performanceLabel,
    required Duration transitionDuration,
    Duration? reverseTransitionDuration,
  }) : _transitionDuration = transitionDuration,
       _reverseTransitionDuration =
           reverseTransitionDuration ?? transitionDuration;

  final Widget page;
  final String performanceLabel;
  final Duration _transitionDuration;
  final Duration _reverseTransitionDuration;
  bool _isSwipeGestureActive = false;
  bool _usesSwipeBackVisual = false;

  @override
  bool get opaque => true;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => _transitionDuration;

  @override
  Duration get reverseTransitionDuration => _reverseTransitionDuration;

  bool get canStartSwipeBack {
    return isCurrent && (navigator?.canPop() ?? false);
  }

  void startSwipeBack() {
    if (!canStartSwipeBack || controller == null) {
      return;
    }
    _isSwipeGestureActive = true;
    _usesSwipeBackVisual = true;
    controller!.stop();
  }

  void updateSwipeBack(double primaryDelta, double width) {
    if (!_isSwipeGestureActive || controller == null || width <= 0) {
      return;
    }
    final double nextValue = controller!.value - (primaryDelta / width);
    controller!.value = nextValue.clamp(0.0, 1.0);
  }

  void endSwipeBack(double primaryVelocity) {
    final AnimationController? routeController = controller;
    if (!_isSwipeGestureActive || routeController == null) {
      return;
    }

    _isSwipeGestureActive = false;
    final bool shouldPop =
        primaryVelocity > _profileDetailBackGestureMinFlingVelocity ||
        routeController.value < 0.5;

    if (shouldPop) {
      navigator?.pop();
      return;
    }

    routeController
        .animateTo(
          1,
          duration: _remainingGestureAnimationDuration(routeController.value),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
          if (routeController.value == 1) {
            _usesSwipeBackVisual = false;
          }
        });
  }

  Duration _remainingGestureAnimationDuration(double currentValue) {
    final int durationMs =
        (transitionDuration.inMilliseconds * (1 - currentValue).clamp(0.0, 1.0))
            .round();
    return Duration(milliseconds: durationMs.clamp(120, 260));
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return page;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _ProfileDetailRouteParallaxSync(
      animation: animation,
      child: _ProfileDetailFadeRouteProbe(
        performanceLabel: performanceLabel,
        animation: animation,
        expectedDuration: transitionDuration,
        child: _ProfileDetailSwipeBackGesture(
          route: this,
          child: AnimatedBuilder(
            animation: animation,
            child: child,
            builder: (context, child) {
              final double width = MediaQuery.sizeOf(context).width;
              final double animationValue = animation.value.clamp(0.0, 1.0);
              final bool shouldTranslate = _usesSwipeBackVisual;
              final double visualValue = shouldTranslate
                  ? animationValue
                  : Curves.easeInOut.transform(animationValue);

              return Transform.translate(
                offset: Offset(
                  shouldTranslate ? width * (1 - visualValue) : 0,
                  0,
                ),
                child: FadeTransition(
                  opacity: AlwaysStoppedAnimation<double>(visualValue),
                  child: child,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileDetailRouteParallaxSync extends StatefulWidget {
  const _ProfileDetailRouteParallaxSync({
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  State<_ProfileDetailRouteParallaxSync> createState() =>
      _ProfileDetailRouteParallaxSyncState();
}

class _ProfileDetailRouteParallaxSyncState
    extends State<_ProfileDetailRouteParallaxSync> {
  final Object _owner = Object();

  @override
  void initState() {
    super.initState();
    widget.animation.addListener(_syncProgress);
    _syncProgress();
  }

  @override
  void didUpdateWidget(covariant _ProfileDetailRouteParallaxSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation == widget.animation) {
      return;
    }
    oldWidget.animation.removeListener(_syncProgress);
    widget.animation.addListener(_syncProgress);
    _syncProgress();
  }

  void _syncProgress() {
    _setProfileDetailRouteParallaxValue(_owner, widget.animation.value);
  }

  @override
  void dispose() {
    widget.animation.removeListener(_syncProgress);
    _removeProfileDetailRouteParallaxValue(_owner);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ProfileDetailSwipeBackGesture extends StatelessWidget {
  const _ProfileDetailSwipeBackGesture({
    required this.route,
    required this.child,
  });

  final _ProfileDetailSwipeBackRoute<dynamic> route;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: _profileDetailBackGestureEdgeWidth,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) => route.startSwipeBack(),
            onHorizontalDragUpdate: (details) {
              route.updateSwipeBack(
                details.primaryDelta ?? 0,
                MediaQuery.sizeOf(context).width,
              );
            },
            onHorizontalDragEnd: (details) {
              route.endSwipeBack(details.primaryVelocity ?? 0);
            },
            onHorizontalDragCancel: () => route.endSwipeBack(0),
          ),
        ),
      ],
    );
  }
}

class ProfileDetailWarmupRegistry {
  ProfileDetailWarmupRegistry._();

  static final ProfileDetailWarmupRegistry instance =
      ProfileDetailWarmupRegistry._();

  final Set<String> _warmedPages = <String>{};

  bool isWarmed(String key) => _warmedPages.contains(key);

  bool markWarmed(String key) => _warmedPages.add(key);
}

mixin ProfileDetailPerformanceMixin<T extends StatefulWidget> on State<T> {
  final Stopwatch _profileDetailStopwatch = Stopwatch()..start();
  bool _isDeferredContentReady = false;
  bool _hasLoggedFirstContentFrame = false;

  @protected
  String get profileDetailPerformanceLabel;

  @protected
  bool get deferHeavyContent => false;

  @protected
  Duration get deferredContentDelay => kProfileDetailPushFadeDuration;

  @protected
  String get profileDetailWarmupKey => profileDetailPerformanceLabel;

  @protected
  bool get isProfileDetailWarmup => false;

  bool get _shouldDeferHeavyContent =>
      deferHeavyContent &&
      !isProfileDetailWarmup &&
      !ProfileDetailWarmupRegistry.instance.isWarmed(profileDetailWarmupKey);

  @protected
  bool get isInitialContentReady =>
      !_shouldDeferHeavyContent || _isDeferredContentReady;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (isProfileDetailWarmup) {
        _logWarmupFrame();
        return;
      }
      if (!_shouldDeferHeavyContent) {
        _logFirstContentFrame();
        return;
      }
      Future<void>.delayed(deferredContentDelay, _showDeferredContent);
    });
  }

  void _showDeferredContent() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isDeferredContentReady = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _logFirstContentFrame();
    });
  }

  void _logFirstContentFrame() {
    if (_hasLoggedFirstContentFrame) {
      return;
    }
    _hasLoggedFirstContentFrame = true;
    ProfileDetailWarmupRegistry.instance.markWarmed(profileDetailWarmupKey);
    _profileDetailStopwatch.stop();
    debugPrint(
      '[$profileDetailPerformanceLabel] first content frame: '
      '${_profileDetailStopwatch.elapsedMilliseconds} ms',
    );
  }

  void _logWarmupFrame() {
    final bool didWarmPage = ProfileDetailWarmupRegistry.instance.markWarmed(
      profileDetailWarmupKey,
    );
    if (!didWarmPage) {
      return;
    }
    _profileDetailStopwatch.stop();
    debugPrint(
      '[$profileDetailPerformanceLabel] warmup frame: '
      '${_profileDetailStopwatch.elapsedMilliseconds} ms',
    );
  }
}

class ProfileDetailSkeletonBlock extends StatelessWidget {
  const ProfileDetailSkeletonBlock({
    super.key,
    required this.isDark,
    required this.height,
    this.width,
    this.borderRadius = 15,
  });

  final bool isDark;
  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171717) : const Color(0xFFD4D4D4),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class _ProfileDetailFadeRouteProbe extends StatefulWidget {
  const _ProfileDetailFadeRouteProbe({
    required this.performanceLabel,
    required this.animation,
    required this.expectedDuration,
    required this.child,
  });

  final String performanceLabel;
  final Animation<double> animation;
  final Duration expectedDuration;
  final Widget child;

  @override
  State<_ProfileDetailFadeRouteProbe> createState() =>
      _ProfileDetailFadeRouteProbeState();
}

class _ProfileDetailFadeRouteProbeState
    extends State<_ProfileDetailFadeRouteProbe> {
  final Stopwatch _stopwatch = Stopwatch()..start();
  bool _didLogCompletion = false;

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_handleAnimationStatus);
  }

  @override
  void didUpdateWidget(covariant _ProfileDetailFadeRouteProbe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation == widget.animation) {
      return;
    }
    oldWidget.animation.removeStatusListener(_handleAnimationStatus);
    widget.animation.addStatusListener(_handleAnimationStatus);
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (_didLogCompletion || status != AnimationStatus.completed) {
      return;
    }

    _didLogCompletion = true;
    _stopwatch.stop();
    final int elapsedMs = _stopwatch.elapsedMilliseconds;
    final int expectedMs = widget.expectedDuration.inMilliseconds;
    final int lateByMs = elapsedMs - expectedMs;
    final bool fullyPlayed =
        lateByMs <= kProfileDetailPushAnimationTolerance.inMilliseconds;

    debugPrint(
      '[${widget.performanceLabel}] push fade animation: '
      'completed, fully_played=$fullyPlayed, '
      'elapsed=$elapsedMs ms, expected=$expectedMs ms'
      '${fullyPlayed ? '' : ', late_by=$lateByMs ms'}',
    );
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_handleAnimationStatus);
    if (!_didLogCompletion) {
      _stopwatch.stop();
      debugPrint(
        '[${widget.performanceLabel}] push fade animation: '
        'interrupted before completion, '
        'elapsed=${_stopwatch.elapsedMilliseconds} ms',
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
