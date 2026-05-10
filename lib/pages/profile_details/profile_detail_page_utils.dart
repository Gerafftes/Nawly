import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

const Duration kProfileDetailPushFadeDuration = Duration(milliseconds: 250);
const Duration kProfileDetailPushAnimationTolerance = Duration(
  milliseconds: 48,
);
const double kProfileDetailBackgroundParallaxFraction = 0.35;
const double _profileDetailBackGestureEdgeWidth = 34;
const double _profileDetailReopenGestureEdgeWidth =
    _profileDetailBackGestureEdgeWidth;
const double _profileDetailBackGestureMinFlingVelocityScreensPerSecond = 1;
const Duration _profileDetailSwipeBackPopDuration = Duration(milliseconds: 130);

final ValueNotifier<double> profileDetailBackgroundParallaxProgress =
    ValueNotifier<double>(0);
Widget? _lastClosedProfileDetailPage;

final Map<Object, double> _profileDetailRouteParallaxValues =
    <Object, double>{};
final Map<Object, bool Function(Offset globalPosition)>
_profileDetailSwipeBackBlockers = <Object, bool Function(Offset)>{};
double? _pendingProfileDetailParallaxProgress;
bool _hasScheduledProfileDetailParallaxPublish = false;

class ProfileDetailBackButton extends StatelessWidget {
  const ProfileDetailBackButton({super.key, this.color, this.iconSize});

  final Color? color;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final double? resolvedIconSize = iconSize == null ? null : iconSize! * 1.4;

    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      child: ExcludeSemantics(
        child: IconButton(
          tooltip: null,
          icon: const Icon(Icons.keyboard_arrow_left),
          color: color,
          iconSize: resolvedIconSize,
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              HapticFeedback.selectionClick();
            }
            Navigator.maybePop(context);
          },
        ),
      ),
    );
  }
}

Route<T> buildProfileDetailFadeRoute<T>({
  required Widget page,
  String? performanceLabel,
  Duration transitionDuration = kProfileDetailPushFadeDuration,
  Duration? reverseTransitionDuration,
  bool startWithSwipeOpenVisual = false,
}) {
  final String label = performanceLabel ?? page.runtimeType.toString();
  return _ProfileDetailSwipeBackRoute<T>(
    page: page,
    performanceLabel: label,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
    startWithSwipeOpenVisual: startWithSwipeOpenVisual,
  );
}

class ProfileDetailSwipeReopenGesture extends StatefulWidget {
  const ProfileDetailSwipeReopenGesture({super.key, required this.child});

  final Widget child;

  @override
  State<ProfileDetailSwipeReopenGesture> createState() =>
      _ProfileDetailSwipeReopenGestureState();
}

class _ProfileDetailSwipeReopenGestureState
    extends State<ProfileDetailSwipeReopenGesture> {
  _ProfileDetailSwipeBackRoute<void>? _activeSwipeOpenRoute;

  void _handleDragStart(DragStartDetails details) {
    if (_lastClosedProfileDetailPage == null) {
      return;
    }
    _activeSwipeOpenRoute ??= _startInteractiveOpen(context);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final double primaryDelta = details.primaryDelta ?? 0;
    if (_lastClosedProfileDetailPage == null) {
      return;
    }

    final _ProfileDetailSwipeBackRoute<void>? route =
        _activeSwipeOpenRoute ?? _startInteractiveOpen(context);
    route?.updateSwipeOpen(primaryDelta, MediaQuery.sizeOf(context).width);
  }

  void _handleDragEnd(DragEndDetails details) {
    final _ProfileDetailSwipeBackRoute<void>? route = _activeSwipeOpenRoute;
    if (route == null) {
      return;
    }

    _activeSwipeOpenRoute = null;
    route.endSwipeOpen(
      details.primaryVelocity ?? 0,
      MediaQuery.sizeOf(context).width,
      onOpened: () {
        _lastClosedProfileDetailPage = null;
      },
    );
  }

  void _handleDragCancel() {
    final _ProfileDetailSwipeBackRoute<void>? route = _activeSwipeOpenRoute;
    _activeSwipeOpenRoute = null;
    route?.cancelSwipeOpen();
  }

  _ProfileDetailSwipeBackRoute<void>? _startInteractiveOpen(
    BuildContext context,
  ) {
    final Widget? page = _lastClosedProfileDetailPage;
    if (page == null) {
      return null;
    }

    final _ProfileDetailSwipeBackRoute<void> route =
        _ProfileDetailSwipeBackRoute<void>(
          page: page,
          performanceLabel: page.runtimeType.toString(),
          transitionDuration: _profileDetailSwipeBackPopDuration,
          startWithSwipeOpenVisual: true,
        );
    _activeSwipeOpenRoute = route;
    Navigator.of(context).push(route);
    return route;
  }

  @override
  void dispose() {
    _activeSwipeOpenRoute?.cancelSwipeOpen();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProfileDetailSwipeReopenGesture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_lastClosedProfileDetailPage == null) {
      _activeSwipeOpenRoute?.cancelSwipeOpen();
      _activeSwipeOpenRoute = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: _profileDetailReopenGestureEdgeWidth,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: _handleDragStart,
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            onHorizontalDragCancel: _handleDragCancel,
          ),
        ),
      ],
    );
  }
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

bool _isProfileDetailSwipeBackBlocked(Offset globalPosition) {
  for (final bool Function(Offset globalPosition) blocker
      in _profileDetailSwipeBackBlockers.values) {
    if (blocker(globalPosition)) {
      return true;
    }
  }
  return false;
}

class ProfileDetailSwipeBackGestureBlocker extends StatefulWidget {
  const ProfileDetailSwipeBackGestureBlocker({super.key, required this.child});

  final Widget child;

  @override
  State<ProfileDetailSwipeBackGestureBlocker> createState() =>
      _ProfileDetailSwipeBackGestureBlockerState();
}

class _ProfileDetailSwipeBackGestureBlockerState
    extends State<ProfileDetailSwipeBackGestureBlocker> {
  final Object _owner = Object();
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _profileDetailSwipeBackBlockers[_owner] = _containsGlobalPosition;
  }

  bool _containsGlobalPosition(Offset globalPosition) {
    final BuildContext? context = _key.currentContext;
    if (context == null) {
      return false;
    }

    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return false;
    }

    final Offset topLeft = renderObject.localToGlobal(Offset.zero);
    return (topLeft & renderObject.size).contains(globalPosition);
  }

  @override
  void dispose() {
    _profileDetailSwipeBackBlockers.remove(_owner);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.child);
  }
}

class _ProfileDetailSwipeBackRoute<T> extends PageRoute<T> {
  _ProfileDetailSwipeBackRoute({
    required this.page,
    required this.performanceLabel,
    required Duration transitionDuration,
    Duration? reverseTransitionDuration,
    bool startWithSwipeOpenVisual = false,
  }) : _transitionDuration = transitionDuration,
       _reverseTransitionDuration =
           reverseTransitionDuration ?? transitionDuration,
       _startWithSwipeOpenVisual = startWithSwipeOpenVisual;

  final Widget page;
  final String performanceLabel;
  final Duration _transitionDuration;
  final Duration _reverseTransitionDuration;
  final bool _startWithSwipeOpenVisual;
  final Object _parallaxOwner = Object();
  bool _isSwipeGestureActive = false;
  bool _usesSwipeBackVisual = false;
  bool _isSyncingSwipeBackProgress = false;
  bool _storePageOnNextPop = false;

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

  @override
  TickerFuture didPush() {
    if (_startWithSwipeOpenVisual) {
      controller?.stop(canceled: false);
      controller?.value = 0;
      _usesSwipeBackVisual = true;
      _startSwipeBackProgressSync();
      return TickerFuture.complete()..then<void>((_) {
        if (requestFocus) {
          navigator!.focusNode.enclosingScope?.requestFocus();
        }
      });
    }
    _lastClosedProfileDetailPage = null;
    return super.didPush();
  }

  @override
  bool didPop(T? result) {
    final bool didPop = super.didPop(result);
    if (didPop && _storePageOnNextPop) {
      _lastClosedProfileDetailPage = page;
    } else if (didPop && !_startWithSwipeOpenVisual) {
      _lastClosedProfileDetailPage = null;
    }
    _storePageOnNextPop = false;
    return didPop;
  }

  bool get canStartSwipeBack {
    return isCurrent && (navigator?.canPop() ?? false);
  }

  void startSwipeBack() {
    if (!canStartSwipeBack || controller == null) {
      return;
    }
    _isSwipeGestureActive = true;
    _usesSwipeBackVisual = true;
    _startSwipeBackProgressSync();
    controller!.reverseDuration = _profileDetailSwipeBackPopDuration;
    controller!.stop();
  }

  void updateSwipeBack(double primaryDelta, double width) {
    if (!_isSwipeGestureActive || controller == null || width <= 0) {
      return;
    }
    final double nextValue = controller!.value - (primaryDelta / width);
    controller!.value = nextValue.clamp(0.0, 1.0);
  }

  void endSwipeBack(double primaryVelocity, double width) {
    final AnimationController? routeController = controller;
    if (!_isSwipeGestureActive || routeController == null) {
      return;
    }

    _isSwipeGestureActive = false;
    final double fractionalVelocity = width <= 0 ? 0 : primaryVelocity / width;
    final bool isFastEnough =
        fractionalVelocity.abs() >=
        _profileDetailBackGestureMinFlingVelocityScreensPerSecond;
    final bool shouldPop = isFastEnough
        ? fractionalVelocity > 0
        : routeController.value < 0.5;

    if (shouldPop) {
      _storePageOnNextPop = true;
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
            routeController.reverseDuration = _reverseTransitionDuration;
            _usesSwipeBackVisual = false;
            _stopSwipeBackProgressSync();
          }
        });
  }

  void updateSwipeOpen(double primaryDelta, double width) {
    final AnimationController? routeController = controller;
    if (routeController == null || width <= 0) {
      return;
    }

    _usesSwipeBackVisual = true;
    _startSwipeBackProgressSync();
    routeController.stop();
    final double nextValue = routeController.value - (primaryDelta / width);
    routeController.value = nextValue.clamp(0.0, 1.0);
  }

  void endSwipeOpen(
    double primaryVelocity,
    double width, {
    required VoidCallback onOpened,
  }) {
    final AnimationController? routeController = controller;
    if (routeController == null) {
      return;
    }

    final double fractionalVelocity = width <= 0 ? 0 : primaryVelocity / width;
    final bool isFastEnough =
        fractionalVelocity.abs() >=
        _profileDetailBackGestureMinFlingVelocityScreensPerSecond;
    final bool shouldOpen = isFastEnough
        ? fractionalVelocity < 0
        : routeController.value > 0.5;

    if (shouldOpen) {
      routeController
          .animateTo(
            1,
            duration: _gestureAnimationDurationForDistance(
              1 - routeController.value,
            ),
            curve: Curves.easeOutCubic,
          )
          .whenComplete(() {
            if (routeController.value == 1) {
              _usesSwipeBackVisual = false;
              _stopSwipeBackProgressSync();
              onOpened();
            }
          });
      return;
    }

    cancelSwipeOpen();
  }

  void cancelSwipeOpen() {
    final AnimationController? routeController = controller;
    if (routeController == null || !isActive) {
      return;
    }

    routeController
        .animateBack(
          0,
          duration: _gestureAnimationDurationForDistance(routeController.value),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
          if (isActive && routeController.value == 0) {
            navigator?.pop();
          }
        });
  }

  void _startSwipeBackProgressSync() {
    if (_isSyncingSwipeBackProgress || controller == null) {
      return;
    }
    _isSyncingSwipeBackProgress = true;
    controller!.addListener(_syncSwipeBackProgress);
    _syncSwipeBackProgress();
  }

  void _stopSwipeBackProgressSync() {
    if (!_isSyncingSwipeBackProgress || controller == null) {
      return;
    }
    controller!.removeListener(_syncSwipeBackProgress);
    _isSyncingSwipeBackProgress = false;
    _removeProfileDetailRouteParallaxValue(_parallaxOwner);
  }

  void _syncSwipeBackProgress() {
    if (controller == null) {
      return;
    }
    _setProfileDetailRouteParallaxValue(_parallaxOwner, controller!.value);
  }

  Duration _remainingGestureAnimationDuration(double currentValue) {
    return _gestureAnimationDurationForDistance(1 - currentValue);
  }

  Duration _gestureAnimationDurationForDistance(double distance) {
    final int durationMs =
        (transitionDuration.inMilliseconds * distance.clamp(0.0, 1.0)).round();
    return Duration(milliseconds: durationMs.clamp(60, 140));
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
    final Widget transition = _ProfileDetailSwipeBackGesture(
      route: this,
      child: AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) {
          final double width = MediaQuery.sizeOf(context).width;
          final double animationValue = animation.value.clamp(0.0, 1.0);
          final double visualValue = _usesSwipeBackVisual
              ? animationValue
              : Curves.easeInOut.transform(animationValue);

          return Transform.translate(
            offset: Offset(
              _usesSwipeBackVisual ? width * (1 - visualValue) : 0,
              0,
            ),
            child: FadeTransition(
              opacity: AlwaysStoppedAnimation<double>(
                _usesSwipeBackVisual ? 1 : visualValue,
              ),
              child: child,
            ),
          );
        },
      ),
    );

    if (_startWithSwipeOpenVisual) {
      return transition;
    }

    return _ProfileDetailFadeRouteProbe(
      performanceLabel: performanceLabel,
      animation: animation,
      expectedDuration: transitionDuration,
      child: transition,
    );
  }

  @override
  void dispose() {
    _stopSwipeBackProgressSync();
    super.dispose();
  }
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
          child: _ProfileDetailSwipeBackHitTestGate(
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
                route.endSwipeBack(
                  details.primaryVelocity ?? 0,
                  MediaQuery.sizeOf(context).width,
                );
              },
              onHorizontalDragCancel: () {
                route.endSwipeBack(0, MediaQuery.sizeOf(context).width);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileDetailSwipeBackHitTestGate extends SingleChildRenderObjectWidget {
  const _ProfileDetailSwipeBackHitTestGate({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _ProfileDetailSwipeBackHitTestGateRenderBox();
  }
}

class _ProfileDetailSwipeBackHitTestGateRenderBox extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final Offset globalPosition = localToGlobal(position);
    if (_isProfileDetailSwipeBackBlocked(globalPosition)) {
      return false;
    }
    return super.hitTest(result, position: position);
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
