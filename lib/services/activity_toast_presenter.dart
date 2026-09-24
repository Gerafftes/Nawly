import 'package:flutter/material.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';

abstract class ActivityToastPresenter {
  const ActivityToastPresenter();

  Future<bool> show({
    required String title,
    required String systemImage,
    required double placementOffset,
    required VoidCallback onOpen,
  });

  Future<bool> dismiss();
}

class MjnActivityToastPresenter extends ActivityToastPresenter {
  const MjnActivityToastPresenter();

  @override
  Future<bool> show({
    required String title,
    required String systemImage,
    required double placementOffset,
    required VoidCallback onOpen,
  }) {
    return AppleLiquidToast.show(
      title: title,
      duration: null,
      placementOffset: placementOffset,
      systemImage: systemImage,
      action: AppleLiquidToastAction(
        title: 'Öffnen',
        tintColor: const Color(0xFF007AFF),
        onPressed: onOpen,
      ),
    );
  }

  @override
  Future<bool> dismiss() => AppleLiquidToast.dismiss();
}
