import 'package:flutter_test/flutter_test.dart';
import 'package:nawly/data/job_map_region_repository.dart';
import 'package:nawly/data/jobs_find_repository.dart';
import 'package:nawly/models/job_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the official Berlin demo boundary from GeoJSON', () async {
    final JobMapRegion region = await const JobMapRegionDemoRepository()
        .loadRegion();

    expect(region.id, 'landesgrenze.11');
    expect(region.name, 'Berlin');
    expect(region.polygons, hasLength(4));
    expect(
      region.polygons
          .expand((JobMapRegionPolygon polygon) => polygon.outer)
          .length,
      greaterThan(1200),
    );

    final List<JobMapCoordinate> points = region.polygons
        .expand((JobMapRegionPolygon polygon) => polygon.outer)
        .toList(growable: false);
    expect(
      points.map((JobMapCoordinate point) => point.latitude).reduce(_min),
      closeTo(52.33824557, 0.00000001),
    );
    expect(
      points.map((JobMapCoordinate point) => point.latitude).reduce(_max),
      closeTo(52.6755077, 0.00000001),
    );
    expect(
      points.map((JobMapCoordinate point) => point.longitude).reduce(_min),
      closeTo(13.0883476, 0.00000001),
    );
    expect(
      points.map((JobMapCoordinate point) => point.longitude).reduce(_max),
      closeTo(13.76115913, 0.00000001),
    );
  });

  test('keeps every local demo marker inside the Berlin region', () async {
    final JobMapRegion region = await const JobMapRegionDemoRepository()
        .loadRegion();
    final List<JobFindData> jobs = await const JobsFindDemoRepository()
        .loadJobs();

    expect(jobs, hasLength(3));
    for (final JobFindData job in jobs) {
      final ApproximateJobLocation location = job.approximateLocation!;
      expect(
        _isInsideRegion(location, region),
        isTrue,
        reason: '${job.id} must stay inside the Berlin demo region',
      );
    }
  });
}

double _min(double left, double right) => left < right ? left : right;

double _max(double left, double right) => left > right ? left : right;

bool _isInsideRegion(ApproximateJobLocation location, JobMapRegion region) {
  return region.polygons.any((JobMapRegionPolygon polygon) {
    return _isInsideRing(location, polygon.outer) &&
        !polygon.holes.any(
          (List<JobMapCoordinate> hole) => _isInsideRing(location, hole),
        );
  });
}

bool _isInsideRing(
  ApproximateJobLocation location,
  List<JobMapCoordinate> ring,
) {
  var isInside = false;
  for (
    int current = 0, previous = ring.length - 1;
    current < ring.length;
    previous = current++
  ) {
    final JobMapCoordinate a = ring[current];
    final JobMapCoordinate b = ring[previous];
    final bool crossesLatitude =
        (a.latitude > location.latitude) != (b.latitude > location.latitude);
    final bool crossesRay =
        location.longitude <
        (b.longitude - a.longitude) *
                (location.latitude - a.latitude) /
                (b.latitude - a.latitude) +
            a.longitude;
    if (crossesLatitude && crossesRay) {
      isInside = !isInside;
    }
  }
  return isInside;
}
