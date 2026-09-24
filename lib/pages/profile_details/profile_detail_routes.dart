import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'profile_detail_gestures.dart';
import 'profile_detail_performance.dart';

const double _profileDetailBackGestureEdgeWidthFraction = 0.085;
const double _profileDetailBackGestureMinEdgeWidth = 28;
const double _profileDetailBackGestureMaxEdgeWidth = 44;
const double _profileDetailBackGestureCommitProgress = 0.5;
const double _profileDetailBackGestureMinFlingVelocity = 420;

abstract class _ProfileDetailSwipeBackHandler {
  void startSwipeBack();
  void updateSwipeBack(double primaryDelta, double width);
  void endSwipeBack(double primaryVelocity);
}

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
          style: const ButtonStyle(
            backgroundColor: WidgetStatePropertyAll<Color>(Colors.transparent),
            overlayColor: WidgetStatePropertyAll<Color>(Colors.transparent),
          ),
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
  ValueChanged<double>? onBackgroundProgressChanged,
  String? performanceLabel,
  Duration transitionDuration = kProfileDetailPushFadeDuration,
  Duration? reverseTransitionDuration,
}) {
  final String label = performanceLabel ?? page.runtimeType.toString();
  return _ProfileDetailFadeRoute<T>(
    page: page,
    performanceLabel: label,
    onBackgroundProgressChanged: onBackgroundProgressChanged,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
  );
}

Route<T> buildProfileDetailSwipeRoute<T>({
  required Widget page,
  required ValueChanged<double> onBackgroundProgressChanged,
  String? performanceLabel,
  Duration transitionDuration = kProfileDetailSwipeDuration,
  Duration? reverseTransitionDuration,
}) {
  final String label = performanceLabel ?? page.runtimeType.toString();
  return _ProfileDetailSwipeRoute<T>(
    page: page,
    performanceLabel: label,
    onBackgroundProgressChanged: onBackgroundProgressChanged,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
  );
}

class _ProfileDetailFadeRoute<T> extends PageRoute<T>
    implements _ProfileDetailSwipeBackHandler {
  _ProfileDetailFadeRoute({
    required this.page,
    required this.performanceLabel,
    required this.onBackgroundProgressChanged,
    required Duration transitionDuration,
    Duration? reverseTransitionDuration,
  }) : _transitionDuration = transitionDuration,
       _reverseTransitionDuration =
           reverseTransitionDuration ?? transitionDuration;

  final Widget page;
  final String performanceLabel;
  final ValueChanged<double>? onBackgroundProgressChanged;
  final Duration _transitionDuration;
  final Duration _reverseTransitionDuration;
  bool _isSwipeBackActive = false;
  bool _usesSwipeBackVisual = false;
  bool _isPublishingSwipeBackProgress = false;

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
    return isCurrent && (navigator?.canPop() ?? false) && controller != null;
  }

  @override
  void startSwipeBack() {
    if (!canStartSwipeBack) {
      return;
    }

    _isSwipeBackActive = true;
    _usesSwipeBackVisual = true;
    _startPublishingSwipeBackProgress();
    controller!.stop();
  }

  @override
  void updateSwipeBack(double primaryDelta, double width) {
    final AnimationController? routeController = controller;
    if (!_isSwipeBackActive || routeController == null || width <= 0) {
      return;
    }

    final double nextValue = routeController.value - (primaryDelta / width);
    routeController.value = nextValue.clamp(0.0, 1.0).toDouble();
  }

  @override
  void endSwipeBack(double primaryVelocity) {
    final AnimationController? routeController = controller;
    if (!_isSwipeBackActive || routeController == null) {
      return;
    }

    _isSwipeBackActive = false;
    final bool isCancelFling =
        primaryVelocity < -_profileDetailBackGestureMinFlingVelocity;
    final bool isPopFling =
        primaryVelocity > _profileDetailBackGestureMinFlingVelocity;
    final bool hasPopDistance =
        routeController.value < _profileDetailBackGestureCommitProgress;
    final bool shouldPop = !isCancelFling && (isPopFling || hasPopDistance);

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
            _stopPublishingSwipeBackProgress();
          }
        });
  }

  Duration _remainingGestureAnimationDuration(double currentValue) {
    final double remaining = (1 - currentValue).clamp(0.0, 1.0).toDouble();
    final int baseDurationMs = reverseTransitionDuration.inMilliseconds > 0
        ? reverseTransitionDuration.inMilliseconds
        : kProfileDetailSwipeDuration.inMilliseconds;
    final int durationMs = (baseDurationMs * remaining)
        .round()
        .clamp(120, baseDurationMs)
        .toInt();
    return Duration(milliseconds: durationMs);
  }

  void _startPublishingSwipeBackProgress() {
    final AnimationController? routeController = controller;
    if (routeController == null ||
        onBackgroundProgressChanged == null ||
        _isPublishingSwipeBackProgress) {
      return;
    }

    _isPublishingSwipeBackProgress = true;
    routeController.addListener(_syncSwipeBackProgress);
    _syncSwipeBackProgress();
  }

  void _syncSwipeBackProgress() {
    _publishSwipeBackProgress(controller?.value ?? 0);
  }

  void _stopPublishingSwipeBackProgress() {
    final AnimationController? routeController = controller;
    final bool wasPublishing = _isPublishingSwipeBackProgress;
    if (_isPublishingSwipeBackProgress && routeController != null) {
      routeController.removeListener(_syncSwipeBackProgress);
    }
    _isPublishingSwipeBackProgress = false;
    if (wasPublishing) {
      _publishSwipeBackProgress(0);
    }
  }

  void _publishSwipeBackProgress(double progress) {
    final ValueChanged<double>? onProgressChanged = onBackgroundProgressChanged;
    if (onProgressChanged == null) {
      return;
    }

    final double clampedProgress = progress.clamp(0.0, 1.0).toDouble();
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        onProgressChanged(clampedProgress);
      });
      return;
    }

    onProgressChanged(clampedProgress);
  }

  @override
  void dispose() {
    _stopPublishingSwipeBackProgress();
    super.dispose();
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
    return ProfileDetailFadeRouteProbe(
      performanceLabel: performanceLabel,
      animation: animation,
      expectedDuration: transitionDuration,
      child: _ProfileDetailSwipeBackGesture(
        route: this,
        child: AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            if (!_usesSwipeBackVisual) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: child,
              );
            }

            final double width = MediaQuery.sizeOf(context).width;
            final double animationValue = animation.value
                .clamp(0.0, 1.0)
                .toDouble();
            return Transform.translate(
              offset: Offset(width * (1 - animationValue), 0),
              child: child,
            );
          },
        ),
      ),
    );
  }
}

class _ProfileDetailSwipeRoute<T> extends PageRoute<T>
    implements _ProfileDetailSwipeBackHandler {
  _ProfileDetailSwipeRoute({
    required this.page,
    required this.performanceLabel,
    required this.onBackgroundProgressChanged,
    required Duration transitionDuration,
    Duration? reverseTransitionDuration,
  }) : _transitionDuration = transitionDuration,
       _reverseTransitionDuration =
           reverseTransitionDuration ?? transitionDuration;

  final Widget page;
  final String performanceLabel;
  final ValueChanged<double> onBackgroundProgressChanged;
  final Duration _transitionDuration;
  final Duration _reverseTransitionDuration;
  bool _isSwipeBackActive = false;

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
    return isCurrent && (navigator?.canPop() ?? false) && controller != null;
  }

  @override
  void startSwipeBack() {
    if (!canStartSwipeBack) {
      return;
    }

    _isSwipeBackActive = true;
    controller!.stop();
  }

  @override
  void updateSwipeBack(double primaryDelta, double width) {
    final AnimationController? routeController = controller;
    if (!_isSwipeBackActive || routeController == null || width <= 0) {
      return;
    }

    final double nextValue = routeController.value - (primaryDelta / width);
    routeController.value = nextValue.clamp(0.0, 1.0).toDouble();
  }

  @override
  void endSwipeBack(double primaryVelocity) {
    final AnimationController? routeController = controller;
    if (!_isSwipeBackActive || routeController == null) {
      return;
    }

    _isSwipeBackActive = false;
    final bool isCancelFling =
        primaryVelocity < -_profileDetailBackGestureMinFlingVelocity;
    final bool isPopFling =
        primaryVelocity > _profileDetailBackGestureMinFlingVelocity;
    final bool hasPopDistance =
        routeController.value < _profileDetailBackGestureCommitProgress;
    final bool shouldPop = !isCancelFling && (isPopFling || hasPopDistance);

    if (shouldPop) {
      navigator?.pop();
      return;
    }

    routeController.animateTo(
      1,
      duration: _remainingGestureAnimationDuration(routeController.value),
      curve: Curves.easeOutCubic,
    );
  }

  Duration _remainingGestureAnimationDuration(double currentValue) {
    final double remaining = (1 - currentValue).clamp(0.0, 1.0).toDouble();
    final int baseDurationMs = reverseTransitionDuration.inMilliseconds > 0
        ? reverseTransitionDuration.inMilliseconds
        : kProfileDetailSwipeDuration.inMilliseconds;
    final int durationMs = (baseDurationMs * remaining)
        .round()
        .clamp(120, baseDurationMs)
        .toInt();
    return Duration(milliseconds: durationMs);
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
    return _ProfileDetailRouteProgressSync(
      animation: animation,
      onProgressChanged: onBackgroundProgressChanged,
      child: ProfileDetailFadeRouteProbe(
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
              final double animationValue = animation.value
                  .clamp(0.0, 1.0)
                  .toDouble();
              final double visualValue = _isSwipeBackActive
                  ? animationValue
                  : Curves.easeInOut.transform(animationValue);

              return Transform.translate(
                offset: Offset(width * (1 - visualValue), 0),
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileDetailRouteProgressSync extends StatefulWidget {
  const _ProfileDetailRouteProgressSync({
    required this.animation,
    required this.onProgressChanged,
    required this.child,
  });

  final Animation<double> animation;
  final ValueChanged<double> onProgressChanged;
  final Widget child;

  @override
  State<_ProfileDetailRouteProgressSync> createState() =>
      _ProfileDetailRouteProgressSyncState();
}

class _ProfileDetailRouteProgressSyncState
    extends State<_ProfileDetailRouteProgressSync> {
  double? _lastPublishedProgress;
  double? _pendingProgress;
  bool _hasScheduledPublish = false;

  @override
  void initState() {
    super.initState();
    widget.animation.addListener(_syncProgress);
    _syncProgress();
  }

  @override
  void didUpdateWidget(covariant _ProfileDetailRouteProgressSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation == widget.animation) {
      return;
    }

    oldWidget.animation.removeListener(_syncProgress);
    widget.animation.addListener(_syncProgress);
    _syncProgress();
  }

  void _syncProgress() {
    _publishProgress(widget.animation.value);
  }

  void _publishProgress(double progress, {bool force = false}) {
    final double clampedProgress = progress.clamp(0.0, 1.0).toDouble();
    if (!force &&
        _lastPublishedProgress != null &&
        (_lastPublishedProgress! - clampedProgress).abs() <= 0.001) {
      return;
    }

    _lastPublishedProgress = clampedProgress;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      _pendingProgress = clampedProgress;
      if (_hasScheduledPublish) {
        return;
      }

      _hasScheduledPublish = true;
      final ValueChanged<double> onProgressChanged = widget.onProgressChanged;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _hasScheduledPublish = false;
        final double? pendingProgress = _pendingProgress;
        _pendingProgress = null;
        if (pendingProgress == null) {
          return;
        }
        onProgressChanged(pendingProgress);
      });
      return;
    }

    widget.onProgressChanged(clampedProgress);
  }

  @override
  void dispose() {
    widget.animation.removeListener(_syncProgress);
    _publishProgress(0, force: true);
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

  final _ProfileDetailSwipeBackHandler route;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final EdgeInsets padding = MediaQuery.paddingOf(context);
    final double edgeWidth =
        (screenSize.width * _profileDetailBackGestureEdgeWidthFraction)
            .clamp(
              _profileDetailBackGestureMinEdgeWidth,
              _profileDetailBackGestureMaxEdgeWidth,
            )
            .toDouble();

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          left: 0,
          top: padding.top + kToolbarHeight,
          bottom: 0,
          width: edgeWidth,
          child: ProfileDetailSwipeBackHitTestGate(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: (_) => route.startSwipeBack(),
              onHorizontalDragUpdate: (details) {
                route.updateSwipeBack(
                  details.primaryDelta ?? 0,
                  screenSize.width,
                );
              },
              onHorizontalDragEnd: (details) {
                route.endSwipeBack(details.primaryVelocity ?? 0);
              },
              onHorizontalDragCancel: () => route.endSwipeBack(0),
            ),
          ),
        ),
      ],
    );
  }
}
