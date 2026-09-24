import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

final Map<Object, bool Function(Offset globalPosition)>
_profileDetailSwipeBackBlockers = <Object, bool Function(Offset)>{};

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

class ProfileDetailSwipeBackHitTestGate extends SingleChildRenderObjectWidget {
  const ProfileDetailSwipeBackHitTestGate({super.key, required super.child});

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
