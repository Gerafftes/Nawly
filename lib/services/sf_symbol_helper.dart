import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SFSymbolHelper {
  static bool get isIOS => Platform.isIOS;

  /// Maps custom icon paths to SF Symbol names
  /// You can specify which SF Symbol to use for each custom icon
  static final Map<String, String> _iconToSFSymbolMap = {
    'assets/icons/add.svg': 'plus',
    'assets/icons/verified.svg': 'lock.shield.fill',
    'assets/icons/close.svg': 'xmark',
    'assets/icons/screwdriver-wrench.svg': 'wrench.and.screwdriver',
  };

  /// Returns an icon widget that uses Cupertino Icons on iOS and SVG on other platforms
  static Widget getIcon({
    required String iconPath,
    required double width,
    required double height,
    Color? color,
  }) {
    if (isIOS && _iconToSFSymbolMap.containsKey(iconPath)) {
      final sfSymbolName = _iconToSFSymbolMap[iconPath]!;
      IconData iconData;
      switch (sfSymbolName) {
        case 'lock.shield.fill':
          iconData = CupertinoIcons.lock_shield_fill;
          break;
        case 'xmark':
          iconData = CupertinoIcons.xmark;
          break;
        case 'plus':
          iconData = CupertinoIcons.plus;
          break;
        case 'wrench.and.screwdriver':
          iconData = CupertinoIcons.wrench;
          break;
        default:
          iconData = CupertinoIcons.question_circle;
      }
      return Icon(
        iconData,
        size: width,
        color: color ?? Colors.black,
      );
    } else {
      // Fallback to SVG for non-iOS or unmapped icons
      return SvgPicture.asset(
        iconPath,
        width: width,
        height: height,
        colorFilter: color != null 
            ? ColorFilter.mode(color, BlendMode.srcIn)
            : null,
      );
    }
  }

  /// Updates the mapping for a specific icon path
  static void updateIconMapping(String iconPath, String sfSymbolName) {
    _iconToSFSymbolMap[iconPath] = sfSymbolName;
  }

  /// Gets all available icon paths that have SF Symbol mappings
  static List<String> get mappedIconPaths => _iconToSFSymbolMap.keys.toList();

  /// Returns an SF Symbol for bottom navigation bar icons
  static Widget getBottomNavIcon({
    required String sfSymbolName,
    required double size,
    required Color color,
  }) {
    // Use Cupertino Icons on iOS for native SF Symbol look
    // Fallback to Material Icons on other platforms
    IconData iconData;
    if (isIOS) {
      switch (sfSymbolName) {
        case 'house':
          iconData = CupertinoIcons.house;
          break;
        case 'headset':
          iconData = CupertinoIcons.headphones;
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
        case 'person':
          iconData = Icons.person_outline;
          break;
        default:
          iconData = Icons.help_outline;
      }
    }

    // For bold icons, we need to use a different approach
    // On iOS, use CupertinoIcons with a custom text style for bold effect
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
    } else {
      return Icon(
        iconData,
        size: size,
        color: color,
      );
    }
  }
}
