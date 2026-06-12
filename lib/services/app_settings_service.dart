import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppSettingsService {
  static const MethodChannel _channel = MethodChannel('nawly/app_settings');

  static Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod<void>('open');
    } on MissingPluginException {
      debugPrint('App settings channel is not available on this platform.');
    } on PlatformException catch (error) {
      debugPrint('Failed to open app settings: ${error.message}');
    }
  }
}
