import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';

class SFSymbolHelper {
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Maps app icon assets to SF Symbols plus Flutter icon fallbacks.
  ///
  /// AppleLiquidSymbol resolves native iOS symbols to image bytes and
  /// paints them as normal Flutter images, so mapped icons can use the plugin
  /// without per-icon PlatformView compositing artifacts.
  static final Map<String, _SFSymbolIconDefinition> _iconDefinitions = {
    'assets/icons/person.circle.fill.svg': _SFSymbolIconDefinition(
      name: 'person.circle.fill',
      fallbackIcon: CupertinoIcons.person_circle_fill,
    ),
    'assets/icons/checkmark.circle.fill.svg': _SFSymbolIconDefinition(
      name: 'checkmark.circle.fill',
      fallbackIcon: CupertinoIcons.checkmark_circle_fill,
    ),
    'assets/icons/checkmark.seal.fill.svg': _SFSymbolIconDefinition(
      name: 'checkmark.seal.fill',
      fallbackIcon: CupertinoIcons.checkmark_seal_fill,
    ),
    'assets/icons/star.fill.svg': _SFSymbolIconDefinition(
      name: 'star.fill',
      fallbackIcon: CupertinoIcons.star_fill,
    ),
    'assets/icons/bell.fill.svg': _SFSymbolIconDefinition(
      name: 'bell.fill',
      fallbackIcon: CupertinoIcons.bell_fill,
    ),
    'assets/icons/lock.shield.fill.svg': _SFSymbolIconDefinition(
      name: 'lock.shield.fill',
      fallbackIcon: CupertinoIcons.lock_shield_fill,
    ),
    'assets/icons/creditcard.fill.svg': _SFSymbolIconDefinition(
      name: 'creditcard.fill',
      fallbackIcon: CupertinoIcons.creditcard_fill,
    ),
    'assets/icons/scroll.fill.svg': _SFSymbolIconDefinition(
      name: 'scroll.fill',
      fallbackIcon: CupertinoIcons.doc_text_fill,
    ),
    'assets/icons/list.bullet.rectangle.portrait.fill.svg':
        _SFSymbolIconDefinition(
          name: 'storefront.fill',
          fallbackIcon: Icons.storefront_rounded,
        ),
    'assets/icons/briefcase.fill.svg': _SFSymbolIconDefinition(
      name: 'briefcase.fill',
      fallbackIcon: Icons.work_rounded,
    ),
    'assets/icons/circle.grid.3x3.fill.svg': _SFSymbolIconDefinition(
      name: 'circle.grid.3x3.fill',
      fallbackIcon: CupertinoIcons.circle_grid_3x3_fill,
    ),
    'assets/icons/gift.fill.svg': _SFSymbolIconDefinition(
      name: 'gift.fill',
      fallbackIcon: CupertinoIcons.gift_fill,
    ),
    'assets/icons/headset.svg': _SFSymbolIconDefinition(
      name: 'headset',
      fallbackIcon: CupertinoIcons.headphones,
    ),
    'assets/icons/plus.circle.fill.svg': _SFSymbolIconDefinition(
      name: 'plus.circle.fill',
      fallbackIcon: CupertinoIcons.plus_circle_fill,
    ),
    'square.and.pencil.circle.fill': _SFSymbolIconDefinition(
      name: 'square.and.pencil.circle.fill',
      fallbackIcon: CupertinoIcons.square_pencil,
    ),
    'assets/icons/xmark.circle.fill.svg': _SFSymbolIconDefinition(
      name: 'xmark.circle.fill',
      fallbackIcon: CupertinoIcons.xmark_circle_fill,
    ),
    'assets/icons/xmark.svg': _SFSymbolIconDefinition(
      name: 'xmark',
      fallbackIcon: CupertinoIcons.xmark,
    ),
    'assets/icons/close.svg': _SFSymbolIconDefinition(
      name: 'xmark',
      fallbackIcon: CupertinoIcons.xmark,
    ),
    'assets/icons/eye.circle.fill.svg': _SFSymbolIconDefinition(
      name: 'eye.circle.fill',
      fallbackIcon: Icons.visibility_rounded,
    ),
    'assets/icons/eye.slash.fill.svg': _SFSymbolIconDefinition(
      name: 'eye.slash.fill',
      fallbackIcon: CupertinoIcons.eye_slash_fill,
    ),
    'assets/icons/arrow.up.right.svg': _SFSymbolIconDefinition(
      name: 'arrow.up.right',
      fallbackIcon: CupertinoIcons.arrow_up_right,
    ),
    'assets/icons/clock.arrow.trianglehead.counterclockwise.rotate.90.svg':
        _SFSymbolIconDefinition(
          name: 'clock.arrow.trianglehead.counterclockwise.rotate.90',
          fallbackIcon: CupertinoIcons.arrow_counterclockwise_circle,
        ),
    'assets/icons/apple.logo.svg': _SFSymbolIconDefinition(
      name: 'apple.logo',
      fallbackIcon: Icons.apple,
    ),
    'assets/icons/add.svg': _SFSymbolIconDefinition(
      name: 'plus',
      fallbackIcon: CupertinoIcons.plus,
    ),
    'assets/icons/plus.svg': _SFSymbolIconDefinition(
      name: 'plus',
      fallbackIcon: CupertinoIcons.plus,
    ),
    'assets/icons/verified.svg': _SFSymbolIconDefinition(
      name: 'checkmark.seal.fill',
      fallbackIcon: CupertinoIcons.checkmark_seal_fill,
    ),
    'assets/icons/screwdriver-wrench.svg': _SFSymbolIconDefinition(
      name: 'wrench.and.screwdriver',
      fallbackIcon: CupertinoIcons.wrench,
    ),
    'assets/icons/wrench.and.screwdriver.fill.svg': _SFSymbolIconDefinition(
      name: 'wrench.and.screwdriver.fill',
      fallbackIcon: CupertinoIcons.wrench,
    ),
    'cart.badge.clock.fill': _SFSymbolIconDefinition(
      name: 'cart.badge.clock.fill',
      fallbackIcon: Icons.shopping_cart_rounded,
    ),
    'pawprint.fill': _SFSymbolIconDefinition(
      name: 'pawprint.fill',
      fallbackIcon: Icons.pets_rounded,
    ),
    'shippingbox.fill': _SFSymbolIconDefinition(
      name: 'shippingbox.fill',
      fallbackIcon: Icons.inventory_2_rounded,
    ),
    'book.fill': _SFSymbolIconDefinition(
      name: 'book.fill',
      fallbackIcon: CupertinoIcons.book_fill,
    ),
    'tree.fill': _SFSymbolIconDefinition(
      name: 'tree.fill',
      fallbackIcon: Icons.park_rounded,
    ),
    'macbook.and.iphone': _SFSymbolIconDefinition(
      name: 'macbook.and.iphone',
      fallbackIcon: Icons.devices_rounded,
    ),
    'alarm.fill': _SFSymbolIconDefinition(
      name: 'alarm.fill',
      fallbackIcon: Icons.alarm_rounded,
    ),
    'hourglass': _SFSymbolIconDefinition(
      name: 'hourglass',
      fallbackIcon: Icons.hourglass_empty_rounded,
    ),
  };

  static const Set<String> _rawSvgIcons = {
    'assets/icons/PayPal.svg',
    'assets/icons/paypal_groß.svg',
    'assets/icons/visa_groß.svg',
    'assets/icons/logo.png',
    'assets/icons/branding.png',
  };

  static bool _usesSvgAsset(String iconPath) {
    if (_rawSvgIcons.contains(iconPath)) {
      return true;
    }
    return !_iconDefinitions.containsKey(iconPath);
  }

  static Future<void> precacheIcons(
    BuildContext context,
    Iterable<String> iconPaths,
  ) async {
    final Set<String> uniquePaths = iconPaths.toSet();
    await Future.wait(
      uniquePaths.map((iconPath) async {
        if (!_usesSvgAsset(iconPath)) {
          return;
        }

        try {
          await SvgAssetLoader(iconPath).loadBytes(context);
        } catch (_) {
          // Warm-up is best-effort only and should never block UI flows.
        }
      }),
    );
  }

  /// Returns a mapped liquid SF Symbol when available, otherwise the raw asset.
  static Widget getIcon({
    required String iconPath,
    double? width,
    double? height,
    Color? color,
    AppleLiquidSymbolWeight? weight,
  }) {
    final _SFSymbolIconDefinition? iconDefinition = _iconDefinitions[iconPath];
    if (iconDefinition != null) {
      final double resolvedSize = _resolveIconSize(width, height);
      return SizedBox(
        width: width ?? resolvedSize,
        height: height ?? resolvedSize,
        child: Center(
          child: AppleLiquidSymbol(
            iconDefinition.name,
            size: resolvedSize,
            color: color,
            weight: weight,
            fallbackIcon: iconDefinition.fallbackIcon,
          ),
        ),
      );
    }

    if (_rawSvgIcons.contains(iconPath)) {
      return SvgPicture.asset(
        iconPath,
        width: width,
        height: height,
        colorFilter: color != null
            ? ColorFilter.mode(color, BlendMode.srcIn)
            : null,
      );
    }
    return SvgPicture.asset(
      iconPath,
      width: width,
      height: height,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
    );
  }

  static Widget getChevronRight({required double size, required Color color}) {
    return Icon(Icons.keyboard_arrow_right, size: size, color: color);
  }

  /// Updates the mapping for a specific icon path
  static void updateIconMapping(String iconPath, String sfSymbolName) {
    _iconDefinitions[iconPath] = _SFSymbolIconDefinition(
      name: sfSymbolName,
      fallbackIcon: _fallbackIconForSymbol(sfSymbolName),
    );
  }

  /// Gets all available icon paths that have SF Symbol mappings
  static List<String> get mappedIconPaths => _iconDefinitions.keys.toList();

  static double _resolveIconSize(double? width, double? height) {
    if (width != null && height != null) {
      return math.min(width, height);
    }
    return width ?? height ?? 24;
  }

  static IconData _fallbackIconForSymbol(String sfSymbolName) {
    switch (sfSymbolName) {
      case 'scroll.fill':
        return CupertinoIcons.doc_text_fill;
      case 'circle.grid.3x3.fill':
        return CupertinoIcons.circle_grid_3x3_fill;
      case 'plus.circle.fill':
        return CupertinoIcons.plus_circle_fill;
      case 'xmark':
        return CupertinoIcons.xmark;
      case 'plus':
        return CupertinoIcons.plus;
      case 'checkmark.seal.fill':
        return CupertinoIcons.checkmark_seal_fill;
      case 'checkmark.circle.fill':
        return CupertinoIcons.checkmark_circle_fill;
      case 'lock.shield.fill':
        return CupertinoIcons.lock_shield_fill;
      case 'person.circle.fill':
        return CupertinoIcons.person_circle_fill;
      case 'bell.fill':
        return CupertinoIcons.bell_fill;
      case 'star.fill':
        return CupertinoIcons.star_fill;
      case 'creditcard.fill':
        return CupertinoIcons.creditcard_fill;
      case 'gift.fill':
        return CupertinoIcons.gift_fill;
      case 'headset':
        return CupertinoIcons.headphones;
      case 'square.and.pencil.circle.fill':
        return CupertinoIcons.square_pencil;
      case 'xmark.circle.fill':
        return CupertinoIcons.xmark_circle_fill;
      case 'eye.circle.fill':
        return Icons.visibility_rounded;
      case 'eye.slash.fill':
        return CupertinoIcons.eye_slash_fill;
      case 'arrow.up.right':
        return CupertinoIcons.arrow_up_right;
      case 'clock.arrow.trianglehead.counterclockwise.rotate.90':
        return CupertinoIcons.arrow_counterclockwise_circle;
      case 'apple.logo':
        return Icons.apple;
      case 'storefront.fill':
        return Icons.storefront_rounded;
      case 'briefcase.fill':
        return Icons.work_rounded;
      case 'alarm.fill':
        return Icons.alarm_rounded;
      case 'hourglass':
        return Icons.hourglass_empty_rounded;
      case 'wrench.and.screwdriver':
      case 'wrench.and.screwdriver.fill':
        return CupertinoIcons.wrench;
      default:
        return CupertinoIcons.question_circle;
    }
  }

  /// Returns an SF Symbol for bottom navigation bar icons
  static Widget getBottomNavIcon({
    required String sfSymbolName,
    required double size,
    required Color color,
  }) {
    // Use Cupertino Icons on iOS for native SF Symbol look.
    // Fallback to Material Icons on other platforms.
    IconData iconData;
    if (isIOS) {
      switch (sfSymbolName) {
        case 'house':
          iconData = CupertinoIcons.house;
          break;
        case 'headset':
          iconData = CupertinoIcons.headphones;
          break;
        case 'bubble.left.and.text.bubble.right.fill':
          iconData = CupertinoIcons.chat_bubble_2_fill;
          break;
        case 'person':
          iconData = CupertinoIcons.person;
          break;
        default:
          iconData = CupertinoIcons.question_circle;
      }
    } else {
      switch (sfSymbolName) {
        case 'house':
          iconData = Icons.home;
          break;
        case 'headset':
          iconData = Icons.headset;
          break;
        case 'bubble.left.and.text.bubble.right.fill':
          iconData = Icons.forum;
          break;
        case 'person':
          iconData = Icons.person_outline;
          break;
        default:
          iconData = Icons.help_outline;
      }
    }

    if (isIOS) {
      return Text(
        String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          fontSize: size,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Icon(iconData, size: size, color: color);
  }
}

class _SFSymbolIconDefinition {
  const _SFSymbolIconDefinition({
    required this.name,
    required this.fallbackIcon,
  });

  final String name;
  final IconData fallbackIcon;
}
