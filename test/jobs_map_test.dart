import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nawly/data/job_map_region_repository.dart';
import 'package:nawly/data/jobs_find_repository.dart';
import 'package:nawly/models/job_models.dart';
import 'package:nawly/widgets/jobs_map.dart';

void main() {
  testWidgets('map fullscreen reaches bottom and preserves overlay lifecycle', (
    WidgetTester tester,
  ) async {
    const double bottomSafeInset = 34;
    final List<JobFindData> jobs = await const JobsFindDemoRepository()
        .loadJobs();
    final JobMapRegion region = await const JobMapRegionDemoRepository()
        .loadRegion();
    expect(jobs, hasLength(3));
    expect(
      jobs.map((JobFindData job) => job.approximateLocation),
      everyElement(isNotNull),
    );
    int beforeFullscreenCalls = 0;
    int fullscreenClosedCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(padding: const EdgeInsets.only(bottom: bottomSafeInset)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 402,
              child: JobsMap(
                jobs: jobs,
                region: region,
                borderColor: const Color(0x33FFFFFF),
                textColor: const Color(0xFFF2F2F2),
                secondaryTextColor: const Color(0xFFB3B3B3),
                cardColor: const Color(0xFF0D0D0D),
                buttonColor: const Color(0xFF1A1A1A),
                buttonTextColor: const Color(0xFFF2F2F2),
                isDark: true,
                tileProvider: _TestTileProvider(),
                onBeforeFullscreenPresented: () async {
                  beforeFullscreenCalls += 1;
                },
                onFullscreenClosed: () {
                  fullscreenClosedCalls += 1;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(FlutterMap), findsOneWidget);
    final FlutterMap map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    final FitBounds initialCameraFit =
        map.options.initialCameraFit! as FitBounds;
    final LatLng initialCenter = LatLng(
      jobs.fold<double>(
            0,
            (double sum, JobFindData job) =>
                sum + job.approximateLocation!.latitude,
          ) /
          jobs.length,
      jobs.fold<double>(
            0,
            (double sum, JobFindData job) =>
                sum + job.approximateLocation!.longitude,
          ) /
          jobs.length,
    );
    const Distance distance = Distance();
    expect(
      distance(
        initialCenter,
        LatLng(initialCameraFit.bounds.north, initialCenter.longitude),
      ),
      closeTo(5000, 2),
    );
    expect(
      distance(
        initialCenter,
        LatLng(initialCenter.latitude, initialCameraFit.bounds.east),
      ),
      closeTo(5000, 2),
    );
    expect(find.byType(ColorFiltered), findsOneWidget);
    expect(find.text('Berlin · Ungefähre Standorte'), findsOneWidget);
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    final PolygonLayer<String> regionLayer = tester
        .widget<PolygonLayer<String>>(
          find.byKey(const ValueKey<String>('job-region-landesgrenze.11')),
        );
    expect(regionLayer.polygons, hasLength(4));
    expect(regionLayer.polygonCulling, isFalse);
    expect(regionLayer.invertedFill, isNotNull);
    expect(
      regionLayer.polygons.every(
        (Polygon<String> polygon) =>
            polygon.borderColor == const Color(0xFFFF453A),
      ),
      isTrue,
    );
    expect(
      find.byKey(const ValueKey<String>('open-fullscreen-map')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('job-marker-find-dog-walking')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('job-marker-find-grocery-help')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('job-marker-find-package-pickup')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('open-fullscreen-map')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const ValueKey<String>('fullscreen-jobs-map')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('close-fullscreen-map')),
      findsOneWidget,
    );
    expect(beforeFullscreenCalls, 1);
    expect(fullscreenClosedCalls, 0);
    final Rect fullscreenMapRect = tester.getRect(
      find.byKey(const ValueKey<String>('fullscreen-jobs-map')),
    );
    final Rect fullscreenScaffoldRect = tester.getRect(find.byType(Scaffold));
    final Rect attributionRect = tester.getRect(
      find.text('© OpenStreetMap contributors'),
    );
    expect(fullscreenMapRect.bottom, fullscreenScaffoldRect.bottom);
    expect(
      attributionRect.bottom,
      lessThanOrEqualTo(fullscreenMapRect.bottom - bottomSafeInset),
    );
    expect(attributionRect.center.dx, lessThan(fullscreenMapRect.center.dx));

    await tester.tap(
      find.byKey(const ValueKey<String>('job-marker-find-package-pickup')),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Paket abholen'), findsOneWidget);
    expect(
      tester
          .getBottomRight(
            find.byKey(const ValueKey<String>('find-package-pickup')),
          )
          .dy,
      lessThanOrEqualTo(fullscreenMapRect.bottom - bottomSafeInset),
    );
    expect(
      find.textContaining(
        'Eine private Adresse wird hier nicht veröffentlicht',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('close-fullscreen-map')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const ValueKey<String>('fullscreen-jobs-map')),
      findsNothing,
    );
    expect(beforeFullscreenCalls, 1);
    expect(fullscreenClosedCalls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

class _TestTileProvider extends TileProvider {
  static final MemoryImage _tile = MemoryImage(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
      '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    ),
  );

  @override
  ImageProvider<Object> getImage(
    TileCoordinates coordinates,
    TileLayer options,
  ) => _tile;
}
