import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nawly/pages/profile_details/profile_detail_gestures.dart';
import 'package:nawly/pages/profile_details/profile_detail_performance.dart';
import 'package:nawly/pages/profile_details/profile_detail_routes.dart';

void main() {
  for (final bool blocked in <bool>[false, true]) {
    testWidgets('back swipe respects blocker=$blocked and its disposal', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  buildProfileDetailSwipeRoute<void>(
                    onBackgroundProgressChanged: (_) {},
                    page: Scaffold(
                      appBar: AppBar(leading: const ProfileDetailBackButton()),
                      body: Stack(
                        children: <Widget>[
                          const Center(child: Text('Detail')),
                          if (blocked)
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: ProfileDetailSwipeBackGestureBlocker(
                                child: SizedBox(
                                  width: 60,
                                  height: double.infinity,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(const Offset(5, 250));
      await gesture.moveBy(const Offset(270, 0));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Detail'), blocked ? findsOneWidget : findsNothing);
      if (blocked) {
        await tester.tap(find.byType(ProfileDetailBackButton));
        await tester.pumpAndSettle();
        expect(find.text('Detail'), findsNothing);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'cold content waits 250 ms; warmed content is immediately ready',
    (tester) async {
      final registry = ProfileDetailWarmupRegistry();
      await tester.pumpWidget(_PerformanceHost(registry: registry));
      expect(find.text('waiting'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 249));
      expect(find.text('waiting'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('ready'), findsOneWidget);
      expect(registry.isWarmed('test'), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(_PerformanceHost(registry: registry));
      expect(find.text('ready'), findsOneWidget);
    },
  );

  testWidgets('disposing a cold page cancels its deferred frame', (
    tester,
  ) async {
    final registry = ProfileDetailWarmupRegistry();
    await tester.pumpWidget(_PerformanceHost(registry: registry));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(registry.isWarmed('test'), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a prewarm marks only its own registry and skips the delay', (
    tester,
  ) async {
    final registry = ProfileDetailWarmupRegistry();
    final unrelated = ProfileDetailWarmupRegistry();
    await tester.pumpWidget(
      _PerformanceHost(registry: registry, prewarm: true),
    );
    expect(find.text('ready'), findsOneWidget);
    expect(registry.isWarmed('test'), isTrue);
    expect(unrelated.isWarmed('test'), isFalse);
  });
}

class _PerformanceHost extends StatefulWidget {
  const _PerformanceHost({required this.registry, this.prewarm = false});
  final ProfileDetailWarmupRegistry registry;
  final bool prewarm;
  @override
  State<_PerformanceHost> createState() => _PerformanceHostState();
}

class _PerformanceHostState extends State<_PerformanceHost>
    with ProfileDetailPerformanceMixin<_PerformanceHost> {
  @override
  String get profileDetailPerformanceLabel => 'test';
  @override
  bool get deferHeavyContent => true;
  @override
  bool get isProfileDetailWarmup => widget.prewarm;
  @override
  ProfileDetailWarmupRegistry get warmupRegistry => widget.registry;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Text(isInitialContentReady ? 'ready' : 'waiting'),
  );
}
