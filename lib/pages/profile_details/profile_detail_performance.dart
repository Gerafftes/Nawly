import 'dart:async';
import 'package:flutter/material.dart';

const Duration kProfileDetailPushFadeDuration = Duration(milliseconds: 250);
const Duration kProfileDetailPushAnimationTolerance = Duration(
  milliseconds: 48,
);
const Duration kProfileDetailSwipeDuration = Duration(milliseconds: 260);

class ProfileDetailWarmupRegistry {
  ProfileDetailWarmupRegistry();

  static final ProfileDetailWarmupRegistry instance =
      ProfileDetailWarmupRegistry();

  final Set<String> _warmedPages = <String>{};

  bool isWarmed(String key) => _warmedPages.contains(key);

  bool markWarmed(String key) => _warmedPages.add(key);
}

mixin ProfileDetailPerformanceMixin<T extends StatefulWidget> on State<T> {
  final Stopwatch _profileDetailStopwatch = Stopwatch()..start();
  bool _isDeferredContentReady = false;
  bool _hasLoggedFirstContentFrame = false;
  Timer? _deferredContentTimer;

  @protected
  ProfileDetailWarmupRegistry get warmupRegistry =>
      ProfileDetailWarmupRegistry.instance;

  @override
  void dispose() {
    _deferredContentTimer?.cancel();
    super.dispose();
  }

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
      !warmupRegistry.isWarmed(profileDetailWarmupKey);

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
      _deferredContentTimer = Timer(deferredContentDelay, _showDeferredContent);
    });
  }

  void _showDeferredContent() {
    _deferredContentTimer = null;
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
    final bool wasWarmed = warmupRegistry.isWarmed(profileDetailWarmupKey);
    warmupRegistry.markWarmed(profileDetailWarmupKey);
    _profileDetailStopwatch.stop();
    debugPrint(
      '[$profileDetailPerformanceLabel] first content frame: '
      '${_profileDetailStopwatch.elapsedMilliseconds} ms, '
      'warmed=$wasWarmed',
    );
  }

  void _logWarmupFrame() {
    final bool didWarmPage = warmupRegistry.markWarmed(profileDetailWarmupKey);
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

class ProfileDetailFadeRouteProbe extends StatefulWidget {
  const ProfileDetailFadeRouteProbe({
    super.key,
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
  State<ProfileDetailFadeRouteProbe> createState() =>
      _ProfileDetailFadeRouteProbeState();
}

class _ProfileDetailFadeRouteProbeState
    extends State<ProfileDetailFadeRouteProbe> {
  final Stopwatch _stopwatch = Stopwatch()..start();
  bool _didLogCompletion = false;

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_handleAnimationStatus);
  }

  @override
  void didUpdateWidget(covariant ProfileDetailFadeRouteProbe oldWidget) {
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
