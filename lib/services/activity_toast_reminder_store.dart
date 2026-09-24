import 'package:shared_preferences/shared_preferences.dart';

class ActivityToastReminderStore {
  const ActivityToastReminderStore({
    this.preferencePrefix = _defaultPreferencePrefix,
  });

  static const String _defaultPreferencePrefix =
      'nawly.active_activity_toast_last_shown_at_v1';

  final String preferencePrefix;

  String _preferenceKey(String toastKey) => '$preferencePrefix.$toastKey';

  Future<DateTime?> loadLastShownAt(String toastKey) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final int? milliseconds = preferences.getInt(_preferenceKey(toastKey));
    if (milliseconds == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
  }

  Future<void> markShown(String toastKey, {DateTime? at}) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final DateTime timestamp = (at ?? DateTime.now()).toUtc();
    await preferences.setInt(
      _preferenceKey(toastKey),
      timestamp.millisecondsSinceEpoch,
    );
  }

  Future<void> clear(String toastKey) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(_preferenceKey(toastKey));
  }
}
