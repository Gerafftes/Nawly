class JobFindData {
  const JobFindData({
    required this.id,
    required this.title,
    required this.time,
    required this.price,
    required this.distance,
    this.showVerified = false,
    this.approximateLocation,
  });

  factory JobFindData.fromJson(Map<String, Object?> json) {
    return JobFindData(
      id: json['id'] as String,
      title: json['title'] as String,
      time: json['time'] as String,
      price: json['price'] as String,
      distance: json['distance'] as String,
      showVerified: json['showVerified'] as bool? ?? false,
      approximateLocation: switch (json['approximateLocation']) {
        final Map<String, Object?> location => ApproximateJobLocation.fromJson(
          location,
        ),
        _ => null,
      },
    );
  }

  final String id;
  final String title;
  final String time;
  final String price;
  final String distance;
  final bool showVerified;
  final ApproximateJobLocation? approximateLocation;
}

/// Public map position for a job. This must never contain a private address or
/// an exact, non-obfuscated home coordinate.
class ApproximateJobLocation {
  const ApproximateJobLocation({
    required this.latitude,
    required this.longitude,
  }) : assert(latitude >= -90 && latitude <= 90),
       assert(longitude >= -180 && longitude <= 180);

  factory ApproximateJobLocation.fromJson(Map<String, Object?> json) {
    return ApproximateJobLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  final double latitude;
  final double longitude;
}

/// A public service region rendered on the jobs map.
///
/// The polygon structure mirrors GeoJSON/PostGIS polygons so the map widget is
/// independent from the repository that provides the region.
class JobMapRegion {
  const JobMapRegion({
    required this.id,
    required this.name,
    required this.polygons,
  });

  factory JobMapRegion.fromGeoJson(Map<String, Object?> json) {
    final List<Object?> features = switch (json['features']) {
      final List<Object?> value when value.isNotEmpty => value,
      _ => throw const FormatException(
        'Map region GeoJSON must contain at least one feature',
      ),
    };
    final Map<String, Object?> feature = switch (features.first) {
      final Map<String, Object?> value => value,
      _ => throw const FormatException('Map region feature must be an object'),
    };
    final Map<String, Object?> properties = switch (feature['properties']) {
      final Map<String, Object?> value => value,
      _ => const <String, Object?>{},
    };
    final Map<String, Object?> geometry = switch (feature['geometry']) {
      final Map<String, Object?> value => value,
      _ => throw const FormatException(
        'Map region feature must contain a geometry',
      ),
    };
    final Object? coordinates = geometry['coordinates'];
    final List<Object?> polygonCoordinates = switch (geometry['type']) {
      'Polygon' => <Object?>[coordinates],
      'MultiPolygon' when coordinates is List<Object?> => coordinates,
      _ => throw const FormatException(
        'Map region geometry must be a Polygon or MultiPolygon',
      ),
    };

    final List<JobMapRegionPolygon> polygons = polygonCoordinates
        .map(JobMapRegionPolygon.fromGeoJsonCoordinates)
        .toList(growable: false);

    return JobMapRegion(
      id: (feature['id'] ?? properties['id'] ?? properties['lan'] ?? 'region')
          .toString(),
      name: (properties['namlan'] ?? properties['name'] ?? 'Demo-Region')
          .toString(),
      polygons: polygons,
    );
  }

  final String id;
  final String name;
  final List<JobMapRegionPolygon> polygons;
}

class JobMapRegionPolygon {
  const JobMapRegionPolygon({required this.outer, this.holes = const []});

  factory JobMapRegionPolygon.fromGeoJsonCoordinates(Object? coordinates) {
    if (coordinates is! List<Object?> || coordinates.isEmpty) {
      throw const FormatException(
        'Map region polygon must contain an outer ring',
      );
    }

    return JobMapRegionPolygon(
      outer: _parseGeoJsonRing(coordinates.first),
      holes: coordinates.skip(1).map(_parseGeoJsonRing).toList(growable: false),
    );
  }

  final List<JobMapCoordinate> outer;
  final List<List<JobMapCoordinate>> holes;
}

class JobMapCoordinate {
  const JobMapCoordinate({required this.latitude, required this.longitude})
    : assert(latitude >= -90 && latitude <= 90),
      assert(longitude >= -180 && longitude <= 180);

  final double latitude;
  final double longitude;
}

List<JobMapCoordinate> _parseGeoJsonRing(Object? rawRing) {
  if (rawRing is! List<Object?> || rawRing.length < 4) {
    throw const FormatException(
      'Map region ring must contain at least four points',
    );
  }

  return rawRing
      .map((Object? rawPoint) {
        if (rawPoint is! List<Object?> || rawPoint.length < 2) {
          throw const FormatException(
            'Map region coordinate must contain longitude and latitude',
          );
        }
        final Object? longitude = rawPoint[0];
        final Object? latitude = rawPoint[1];
        if (longitude is! num || latitude is! num) {
          throw const FormatException('Map region coordinates must be numeric');
        }
        return JobMapCoordinate(
          latitude: latitude.toDouble(),
          longitude: longitude.toDouble(),
        );
      })
      .toList(growable: false);
}
