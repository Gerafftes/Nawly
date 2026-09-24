// Compatibility entry point for existing profile pages.
// Each library owns one concern; no mutable state lives in this facade.
export 'profile_detail_gestures.dart' show ProfileDetailSwipeBackGestureBlocker;
export 'profile_detail_performance.dart'
    show
        kProfileDetailPushFadeDuration,
        kProfileDetailPushAnimationTolerance,
        kProfileDetailSwipeDuration,
        ProfileDetailWarmupRegistry,
        ProfileDetailPerformanceMixin,
        ProfileDetailSkeletonBlock;
export 'profile_detail_routes.dart';
