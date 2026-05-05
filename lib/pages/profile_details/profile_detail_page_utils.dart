import 'package:flutter/material.dart';

const Duration kProfileDetailPushFadeDuration = Duration(milliseconds: 250);
const Duration kProfileDetailPushAnimationTolerance = Duration(
  milliseconds: 48,
);

Route<T> buildProfileDetailFadeRoute<T>({
  required Widget page,
  String? performanceLabel,
  Duration transitionDuration = kProfileDetailPushFadeDuration,
  Duration? reverseTransitionDuration,
}) {
  final String label = performanceLabel ?? page.runtimeType.toString();
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration ?? transitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        _ProfileDetailFadeRouteProbe(
          performanceLabel: label,
          animation: animation,
          expectedDuration: transitionDuration,
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          ),
        ),
  );
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
