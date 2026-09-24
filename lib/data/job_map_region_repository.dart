import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/job_models.dart';

abstract class JobMapRegionRepository {
  const JobMapRegionRepository();

  Future<JobMapRegion> loadRegion();
}

/// Loads the bundled first-launch region. A future PostGIS adapter only needs
/// to return the same [JobMapRegion] model; the map UI remains unchanged.
class JobMapRegionDemoRepository extends JobMapRegionRepository {
  const JobMapRegionDemoRepository({
    this.assetPath = 'assets/data/berlin_demo_region.geojson',
  });

  final String assetPath;

  @override
  Future<JobMapRegion> loadRegion() async {
    final String payload = await rootBundle.loadString(assetPath);
    final Object? decoded = jsonDecode(payload);

    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Map region data must be a GeoJSON object');
    }

    return JobMapRegion.fromGeoJson(decoded);
  }
}
