import 'package:supabase_flutter/supabase_flutter.dart';

/// Gateway for data that is intentionally public, such as the job catalogue.
///
/// Private account data must not be added here. It is served by the
/// authenticated `private-data` Edge Function instead.
abstract class SupabaseDataGateway {
  const SupabaseDataGateway();

  Future<List<Map<String, Object?>>> loadJobs();
}

class SupabaseClientDataGateway extends SupabaseDataGateway {
  const SupabaseClientDataGateway(this.client);

  final SupabaseClient client;

  @override
  Future<List<Map<String, Object?>>> loadJobs() async {
    final List<Map<String, dynamic>> rows = await client
        .from('jobs')
        .select()
        .order('position');
    return rows
        .map((Map<String, dynamic> row) => Map<String, Object?>.from(row))
        .toList(growable: false);
  }
}

/// Gateway for encrypted private account data.
///
/// The account identifier is deliberately absent from this interface. The
/// Edge Function derives it from the verified JWT, so a client cannot ask for
/// another account's records.
abstract class SupabasePrivateDataGateway {
  const SupabasePrivateDataGateway();

  bool get isAuthenticated;

  Future<Map<String, Object?>?> loadProfile();

  Future<List<Map<String, Object?>>> loadActivities();

  Future<List<Map<String, Object?>>> loadActivityStatusHistory(
    List<String> activityIds,
  );
}

class SupabaseClientPrivateDataGateway extends SupabasePrivateDataGateway {
  const SupabaseClientPrivateDataGateway(this.client);

  final SupabaseClient client;

  @override
  bool get isAuthenticated => client.auth.currentUser != null;

  @override
  Future<Map<String, Object?>?> loadProfile() async {
    final Object? response = await _invoke('profile');
    if (response is! Map || !response.containsKey('profile')) {
      throw StateError('The private profile response has an invalid shape.');
    }
    final Object? profile = response['profile'];
    return profile == null ? null : _copyRow(profile);
  }

  @override
  Future<List<Map<String, Object?>>> loadActivities() async {
    final Object? response = await _invoke('activities');
    if (response is! Map) {
      throw StateError('The private activity response has an invalid shape.');
    }
    return _copyRows(response['activities']);
  }

  @override
  Future<List<Map<String, Object?>>> loadActivityStatusHistory(
    List<String> activityIds,
  ) async {
    if (activityIds.isEmpty) {
      return const <Map<String, Object?>>[];
    }
    // Keep an activity's history in one request and preserve the server's
    // ordering within that history. Duplicate IDs must not duplicate rows.
    final List<String> uniqueIds = activityIds.toSet().toList(growable: false);
    const int batchSize = 100; // private-data request contract
    final List<Map<String, Object?>> history = <Map<String, Object?>>[];
    for (int start = 0; start < uniqueIds.length; start += batchSize) {
      final int end = (start + batchSize).clamp(0, uniqueIds.length);
      final Object? response = await _invoke(
        'activity_status_history',
        extraBody: <String, Object?>{
          'activityIds': uniqueIds.sublist(start, end),
        },
      );
      if (response is! Map) {
        throw StateError('The private status response has an invalid shape.');
      }
      history.addAll(_copyRows(response['history']));
    }
    return history;
  }

  Future<Object?> _invoke(
    String operation, {
    Map<String, Object?> extraBody = const <String, Object?>{},
  }) async {
    final Map<String, Object?> body = <String, Object?>{
      'operation': operation,
      ...extraBody,
    };
    final FunctionResponse response = await client.functions.invoke(
      'private-data',
      body: body,
    );
    if (response.status < 200 || response.status >= 300) {
      throw StateError(
        'The private data server rejected the request '
        '(${response.status}).',
      );
    }
    return response.data;
  }

  Map<String, Object?> _copyRow(Object? value) {
    if (value is! Map) {
      throw StateError('The private data server returned an invalid row.');
    }
    return Map<String, Object?>.from(value);
  }

  List<Map<String, Object?>> _copyRows(Object? value) {
    if (value is! List) {
      throw StateError('The private data server returned invalid rows.');
    }
    return value.map(_copyRow).toList(growable: false);
  }
}
