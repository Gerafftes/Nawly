import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nawly/data/supabase_data_gateway.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  for (final int count in <int>[0, 1, 100, 101, 201]) {
    test('loads $count activity histories in bounded requests', () async {
      final List<List<String>> batches = <List<String>>[];
      final SupabaseClient client = _client((http.Request request) async {
        expect(request.url.path, '/functions/v1/private-data');
        final Map<String, dynamic> body = jsonDecode(request.body);
        expect(
          body.keys,
          unorderedEquals(<String>['operation', 'activityIds']),
        );
        expect(body['operation'], 'activity_status_history');
        final List<String> ids = (body['activityIds'] as List).cast<String>();
        batches.add(ids);
        return http.Response(
          jsonEncode(<String, Object>{
            'history': <Map<String, Object>>[
              for (final String id in ids)
                for (final int position in <int>[2, 1])
                  <String, Object>{'activity_id': id, 'position': position},
            ],
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      });
      addTearDown(client.dispose);
      final List<String> ids = List<String>.generate(count, (int i) => 'id-$i');
      final rows = await SupabaseClientPrivateDataGateway(
        client,
      ).loadActivityStatusHistory(ids);
      expect(batches.length, (count / 100).ceil());
      expect(
        batches.every((List<String> batch) => batch.length <= 100),
        isTrue,
      );
      expect(batches.expand((batch) => batch), ids);
      expect(rows, <Map<String, Object>>[
        for (final String id in ids)
          for (final int position in <int>[2, 1])
            <String, Object>{'activity_id': id, 'position': position},
      ]);
    });
  }

  test('deduplicates IDs before batching', () async {
    final SupabaseClient client = _client((http.Request request) async {
      expect(jsonDecode(request.body)['activityIds'], <String>['a', 'b']);
      return http.Response(
        '{"history":[{"activity_id":"a"}]}',
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
    addTearDown(client.dispose);
    expect(
      await SupabaseClientPrivateDataGateway(
        client,
      ).loadActivityStatusHistory(<String>['a', 'a', 'b', 'a']),
      hasLength(1),
    );
  });

  test('a failed later batch rejects the entire load', () async {
    int calls = 0;
    final SupabaseClient client = _client((http.Request request) async {
      calls++;
      return http.Response(
        calls == 1
            ? '{"history":[{"activity_id":"a"}]}'
            : '{"error":"unavailable"}',
        calls == 1 ? 200 : 503,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
    addTearDown(client.dispose);
    await expectLater(
      SupabaseClientPrivateDataGateway(
        client,
      ).loadActivityStatusHistory(List<String>.generate(201, (int i) => '$i')),
      throwsA(isA<FunctionException>()),
    );
    expect(calls, 2);
  });
}

SupabaseClient _client(MockClientHandler handler) => SupabaseClient(
  'https://test.invalid',
  'test-publishable-key',
  httpClient: MockClient(handler),
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);
