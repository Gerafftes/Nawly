import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nawly/app_startup.dart';
import 'package:nawly/bootstrap.dart';
import 'package:nawly/config/app_environment.dart';
import 'package:nawly/data/app_repositories.dart';
import 'package:nawly/data/user_profile_repository.dart';
import 'package:nawly/models/user_profile_models.dart';

const ready = MaterialApp(home: Scaffold(body: Text('Bereit')));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late UserProfileData profile;
  setUpAll(() async {
    profile = await AppRepositories.demo().userProfile.loadProfile();
  });
  testWidgets('shows loading immediately and does not restart on rebuild', (
    tester,
  ) async {
    final pending = Completer<Widget>();
    var calls = 0;
    Future<Widget> load() {
      calls++;
      return pending.future;
    }

    await tester.pumpWidget(AppStartup(load: load));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(AppStartup(load: load));
    expect(calls, 1);
    pending.complete(ready);
    await tester.pumpAndSettle();
    expect(find.text('Bereit'), findsOneWidget);
  });

  for (final stage in ['initialization', 'profile']) {
    testWidgets('$stage failure is safe and retry can recover', (tester) async {
      final defaults = AppRepositories.demo();
      var fail = true;
      var calls = 0;
      final pendingRetry = Completer<void>();
      Future<Widget> load() async {
        calls++;
        if (calls > 1) await pendingRetry.future;
        final bootstrap = await loadAppBootstrap(
          environment: AppEnvironment.fromValues(
            dataSource: 'supabase',
            supabaseUrl: 'https://test.invalid',
            supabasePublishableKey: 'test-key',
          ),
          demoRepositories: () => throw StateError('No demo fallback allowed'),
          supabaseRepositories: (_) async {
            if (fail && stage == 'initialization') {
              throw StateError('sensitive-initialization-details');
            }
            return AppRepositories(
              userProfile: _Profile(() async {
                if (fail) throw StateError('sensitive-profile-details');
                return profile;
              }),
              activities: defaults.activities,
              jobs: defaults.jobs,
              mapRegion: defaults.mapRegion,
              accountDeletion: defaults.accountDeletion,
            );
          },
        );
        expectSync(bootstrap.userProfile, same(profile));
        return ready;
      }

      await tester.pumpWidget(AppStartup(load: load));
      await tester.pumpAndSettle();
      expect(find.text('Nawly konnte nicht gestartet werden.'), findsOneWidget);
      expect(find.textContaining('sensitive-'), findsNothing);
      final retry = tester.widget<FilledButton>(find.byType(FilledButton));
      fail = false;
      retry.onPressed!();
      retry.onPressed!();
      retry.onPressed!();
      await tester.pump();
      expect(calls, 2);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pendingRetry.complete();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Bereit'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('repeated failures allow later retries without parallel work', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      AppStartup(
        load: () async {
          if (++calls < 3) throw StateError('unavailable');
          return ready;
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Erneut versuchen'));
    await tester.pumpAndSettle();
    expect(find.text('Erneut versuchen'), findsOneWidget);
    await tester.tap(find.text('Erneut versuchen'));
    await tester.pumpAndSettle();
    expect(calls, 3);
    expect(find.text('Bereit'), findsOneWidget);
  });

  for (final fails in [false, true]) {
    testWidgets('unmounted attempt cannot replace a newer app ($fails)', (
      tester,
    ) async {
      final old = Completer<Widget>();
      await tester.pumpWidget(
        AppStartup(key: const ValueKey('old'), load: () => old.future),
      );
      await tester.pumpWidget(
        AppStartup(key: const ValueKey('new'), load: () async => ready),
      );
      await tester.pumpAndSettle();
      if (fails) {
        old.completeError(StateError('obsolete-sensitive-error'));
      } else {
        old.complete(const MaterialApp(home: Text('Veraltet')));
      }
      await tester.pumpAndSettle();
      expect(find.text('Bereit'), findsOneWidget);
      expect(find.text('Veraltet'), findsNothing);
      expect(find.text('Erneut versuchen'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('synchronous startup errors also show retry', (tester) async {
    await tester.pumpWidget(AppStartup(load: () => throw StateError('secret')));
    await tester.pumpAndSettle();
    expect(find.text('Erneut versuchen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _Profile extends UserProfileRepository {
  const _Profile(this.load);
  final Future<UserProfileData> Function() load;

  @override
  Future<UserProfileData> loadProfile() => load();
}
