import 'package:shared_preferences/shared_preferences.dart';

class ActivityToastSeenStore {
  const ActivityToastSeenStore({this.preferenceKey = _defaultPreferenceKey});

  static const String _defaultPreferenceKey =
      'nawly.active_activity_toast_acknowledged_keys_v2';

  final String preferenceKey;

  Future<Set<String>> loadSeenKeys({
    Iterable<String> completedActivityIds = const <String>[],
  }) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final Set<String> seenKeys =
        (preferences.getStringList(preferenceKey) ?? const <String>[]).toSet();
    final Set<String> completedIds = completedActivityIds.toSet();
    if (completedIds.isEmpty) {
      return seenKeys;
    }

    final Set<String> activeKeys = seenKeys
        .where(
          (String key) => !completedIds.any(
            (String activityId) => key.startsWith('$activityId:'),
          ),
        )
        .toSet();
    if (activeKeys.length != seenKeys.length) {
      final List<String> sortedKeys = activeKeys.toList()..sort();
      await preferences.setStringList(preferenceKey, sortedKeys);
    }
    return activeKeys;
  }

  Future<void> markSeen(String key) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final Set<String> keys = {
      ...(preferences.getStringList(preferenceKey) ?? const <String>[]),
      key,
    };
    final List<String> sortedKeys = keys.toList()..sort();
    await preferences.setStringList(preferenceKey, sortedKeys);
  }

  Future<void> clear(String key) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<String> keys =
        (preferences.getStringList(preferenceKey) ?? const <String>[])
            .where((String value) => value != key)
            .toList();
    await preferences.setStringList(preferenceKey, keys);
  }
}
